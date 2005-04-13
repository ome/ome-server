# OME/Remote/Facades/ModuleRetrievalFacade.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:    Harry Hochheiser <hsh@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Remote::Facades::ModuleRetrievalFacade;
use OME;
use strict;
our $VERSION = $OME::VERSION;

use OME::Session;


=head1 NAME

OME::Remote::Facades::ModuleRetrievalFacade: a facade for 
    special-purpose retrieval of modules.

=head1 DESCRIPTION

Generalized retrieval of DTOs from the OME database via DBObject and
 Factory can be inefficient. For cases where known queries will be
 commonly repeated, construction and managemetn of custom queries
 that will be hand-converted into appropriate DTOs can provide
 significant performance improvements.

 This manager provides just such a custom implementation for
 retrieving all of the modules in an OME database.

=cut

# several queries that are needed to assemble the module data.
# the general approach here is to build several indviduanl queries,
# each of which involves either one chain or multiple chains  
# that are joined via one-one relationships. Any joins involving
# has-many or many-many relationships should be handled by multiple
# queries, as seen below.

# Desired fields for a module,
use constant MODULE_QUERY => <<MODULE_SQL;
Select m.module_id, m.name, m.description,m.category from modules m;
MODULE_SQL

# formal inputs get the associated semantic type as well
use constant FINS_QUERY => <<FINS_SQL;
select fi.formal_input_id,fi.name, fi.module_id, stin.semantic_type_id, 
stin.name from formal_inputs fi, semantic_types stin
where fi.semantic_type_id=stin.semantic_type_id;
FINS_SQL

# as do formal outputs get the associated semantic type as well
use constant FOUTS_QUERY => <<FOUTS_SQL;
select fo.formal_output_id,fo.name, fo.module_id, stout.semantic_type_id, 
stout.name from formal_outputs fo, semantic_types stout
where fo.semantic_type_id=stout.semantic_type_id;
FOUTS_SQL

# fields for the various objects and sub-objects. Each of these lists specifies
# exactly those columns, in order, that will be present in the above queries. 
# These arrays will be used to provide hash keys for these fields in the
# resulting hash of hashes (which will eventually be encoded as XMLRPC and
# returned to the caller. Note that regardless of their names in the database,
#id fields are simply named "id". Note also that nodes and links have
# analysis_chain_ids, which will be cleared once those objects are placed in the # appropriate chain.
my @module_fields = qw[id name description category];
my @input_fields = qw[id name module_id];
my @output_fields = qw[id name module_id];
my @st_fields = qw[id name];


sub retrieveModules {

	# start by grabbing the appropriate entry points to the OME Database
	my $session = OME::Session->instance();
	my $factory = $session->Factory();

	my $dbh = $factory->obtainDBH();

	# do modules with hash by Id. Although we want a list, we hash by id to 
	# provide easy access to chains by id. Eventually, we'll return the values
	# of this hash.
	my $modules= {};
	
	#the current chain and owner
	my $module;
	my $SQL=MODULE_QUERY;

	# execute module query.
	my $sth = $dbh->prepare($SQL);
	$sth->execute();

	# run across the rows.
	while (my @row = $sth->fetchrow_array) {
		my $i=0;
		# look at columns that hold the chain and populate them
		$module = fill_fields(\$i,\@row,\@module_fields);
		# reformat last pieces to be category
		if (exists $module->{'category'} &&
		    defined $module->{'category'}) {
		    $module->{'category'} = 
			getCategoryXML($module->{'category'});
		}
		$modules->{$module->{'id'}} = $module;
	}

	# do formal inputs
	my $fin;
	my $st;
	my $modid;
	$SQL = FINS_QUERY;
	$sth = $dbh->prepare($SQL);
	$sth->execute();

	while (my @row = $sth->fetchrow_array) {
		my $i=0;
		# get formal input and st
		$fin= fill_fields(\$i,\@row,\@input_fields);
		$st = fill_fields(\$i,\@row,\@st_fields);
		my $stxml = getSTXml($st);
		my $finxml = getParameterXml($fin,$stxml);
		# find module 
		$modid = $fin->{'module_id'};
		$module = $modules->{$modid};
		# undef module id
		delete $fin->{'module_id'};
		# add fin to module
		push @{$module->{'inputs'}},$finxml;
	}

	# do formal outputs
	my $fout;
	my $fouts;
	$SQL = FOUTS_QUERY;
	$sth = $dbh->prepare($SQL);
	$sth->execute();

	while (my @row = $sth->fetchrow_array) {
		my $i=0;
		$fout= fill_fields(\$i,\@row,\@output_fields);
		$st = fill_fields(\$i,\@row,\@st_fields);
		my $stxml = getSTXml($st);
		my $foutxml = getParameterXml($fout,$stxml);
		$modid = $fout->{'module_id'};
		$module = $modules->{$modid};
		# undef module id
		delete $fout->{'module_id'};
		# add fin to module
		push @{$module->{'outputs'}},$foutxml;
	}

	my $res = getModulesXML(values %$modules);
	return (bless (\$res,'OME::Remote::Response::XMLRPC'));
}

# to fill the fields of a given object from a row,
# take the row, along with a starting point in the row,
# and the list of fields to fill. March down the fieldlist and the
# row, using entries from the fieldlist as keys and the row as
# values. Advance the index pointer to point to the next available
# column in the table. 

sub fill_fields {

    my ($startindex,$row,$fieldlist)=@_;

    my $i = $$startindex;
    my @fields = @$fieldlist;
    my $res;
    for (my $j=0; $j <=$#fields; $j++) {
    	my $val = $row->[$i++];
    	if (defined $val) {
			$res->{$fields[$j]} = $val;
		}
   	}
    $$startindex= $i;
    return $res;
}


# build xml for an st
	# st xml is 
	#	<struct>
	#  <member>
	#    <name>id</name>
	#	<value>
	#    <int>46</int>
	# 	</value>
	# </member>
	# <member>
	#<name>name</name>
	#<value>
	#<string>StackSigma</string>
	#</value>
	# </member>
	# </struct>

sub getSTXml {
 my $st = shift;
 
 my $xml = "<struct><member><name>id</name><value><int>" . $st->{'id'}. 	     
 		"</int></value></member>";
 $xml = $xml . "<member><name>name</name><value>" . $st->{'name'}. 
 		"</value></member></struct>";
 return $xml;
}


# formal output/formal input structure
#     <struct>
#         <member>
#           <name>id</name>
#           <value><int>26</int></value>
#         </member>
#          <member>
#          <name>semantic_type</name>
#         <value>
#			... st structure
#		   </value>
#         </member>
#        <member>
#         <name>name</name>
#         <value><string>Sigma</string></value>
#        </member>
#      </struct>

sub getParameterXml {
	my ($param,$stxml) = @_;
 	
    my $xml = "<struct><member><name>id</name><value><int> " . $param->{'id'} .
    	 "</int></value></member>";
    $xml = $xml . "<member><name>semantic_type</name>";
    $xml = $xml . "<value>$stxml</value></member>";
    $xml = $xml . "<member><name>name</name><value><string>" . 
    		$param->{'name'} . "</string></value></member></struct>";
    return $xml;
}   

sub getCategoryXML {
    my ($category_id) = shift;

    my $xml ="<struct><member><name>id</name><value><int>";
    $xml = $xml .  $category_id .
	"</int></value></member></struct>";
    return $xml;
}


# module
#id 
#name 
#description
#category 
#inputs 
#outputs.

sub getModulesXML{

        my(@modules) = @_;

	# sort them by name
        @modules = sort { lc($a->{'name'}) cmp lc($b->{'name'})} @modules;


	my $res; 
	$res = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
	$res = $res. "<methodResponse><params><param><value><array><data>";
	#print header 
	
	
	#iterate
	foreach my $module (@modules) {
		$ res = $res . "<value>" . getModuleXML($module) . "</value>";
	}
	
	#close up
	$res  = $ res ."</data></array></value></param></params></methodResponse>";
	
	return $res;
} 

# a module

sub getModuleXML { 
	my $module = shift;
	
	#preamble
	my $xml = "<struct>";
	
	# id
	$ xml = $xml . "<member><name>id</name><value><int> " . 
	    $module->{'id'} . "</int></value></member>";
	
	# name
	$ xml = $xml . "<member><name>name</name><value><string> " 
		. $module->{'name'} . "</string></value></member>";
	
	#description
	if (defined $module->{'description'}) {
		$ xml = $xml .
		    "<member><name>description</name><value><string> " . 
	   	    $module->{'description'} . "</string></value></member>";
	}
	# category
	if (defined $module->{'category'}) {
	    $xml = $xml .
		"<member><name>category</name><value>";
	    $xml = $xml . $ module->{'category'} .
		"</value></member>";
	}

	#inputs
	my $inputCount = $#{$module->{'inputs'}} +1;
	if ($inputCount > 0) {
		 $xml = $xml .
		     "<member><name>inputs</name><value><array><data>"; 
		 foreach my $input ( @{$module->{'inputs'}}) {
	 		$xml = $xml . "<value>$input</value>";
		 }
  		 $xml = $xml . "</data></array></value></member>";
	}


	#outputs
	my $outputCount = $#{$module->{'outputs'}} +1;
	if ($outputCount > 0) {
		 $xml = $xml .
		     "<member><name>outputs</name><value><array><data>"; 
		 foreach my $output ( @{$module->{'outputs'}}) {
	 		$xml = $xml . "<value>$output</value>";
		 }
  		 $xml = $xml . "</data></array></value></member>";
	}
	
	# end 
	$xml = $xml . "</struct>";
	return $xml;
}	
1;

__END__
=head1 AUTHOR

Harry Hochheiser (hsh@nih.gov)

=cut
