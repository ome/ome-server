# OME/Tasks/AttributeManager.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Tasks::AttributeManager;


=head1 NAME

OME::Tasks::AttributeManager - Common tasks for attributes

=head1 SYNOPSIS

	use OME::Tasks::AttributeManager;
	my $attrManager=new OME::Tasks::AttributeManager($session);
	
	# merge attributes that have been sorted by module execution
	my @table_set_list = $attrManager->mergeMEXAttrs( [ 
		{ attrs => /@attrs1,
		  mex   => $module_execution1,
		  fo    => $formal_output1 },
		{ attrs => /@attrs2,
		  mex   => $module_execution2,
		  fo    => $formal_output2 },
		...]);
	foreach my $table_set( @table_set_list ) {
		my $table = $tbl_set->{ table };
		# data sources for that table
		my $srcs = $tbl_set->{ srcs };

		foreach my $src ( @$srcs ) {
			my $module_execution = $src->{mex};
			my $formal_output    = $src->{fo};
			# ...do something
		}

		# ...do something
	}
	

=head1 DESCRIPTION

The OME::Tasks::DatasetManager provides a list of methods to manage attributes

=head1 METHODS


=cut

use strict;
use OME::SetDB;
use OME::DBObject;
OME::DBObject->Caching(0);

use OME;
our $VERSION = $OME::VERSION;

sub new{
	my $proto = shift;
	my $class = ref($proto) || $proto;
print STDERR "1\n";
	my $self={};
print STDERR "1\n";
	$self->{session}=shift;
print STDERR "1\n";
	bless($self,$class);
print STDERR "1\n";
   	return $self;


}


=pod

=head2 mergeMEXAttrs

=cut

#################
# Parameters:
#	attr_set_hash

sub mergeMEXAttrs {
	my $self = shift;
	my $attr_set_list = shift;
	
	my @attrTables;
	foreach my $attr_set (@$attr_set_list) {
		my $attr_list = $attr_set->{attrs};
		my $mex = $attr_set->{mex};
		my $fo = $attr_set->{fo};
		my @tbl;
		my $i = 0;
		foreach my $attr (@$attr_list) {
			my $dat = $attr->getDataHash()
				or die "Could not load attribute data hash\n";
			$tbl[$i]->{$_} = $dat->{$_} 
				foreach keys %$dat;
			$i++;
		}
		push( @attrTables, { table => \@tbl, srcs => [{ mex => $mex, fo => $fo }] } );
	} 


	return \@attrTables;
}

=head1 AUTHOR

Josiah Johnston

=head1 SEE ALSO

L<OME::DBObject|OME::DBObject>,
L<OME::Factory|OME::Factory>,
L<OME::SetDB|OME::SetDB>,

=cut

1;
