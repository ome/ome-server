# OME/Web/AttributeTabularView.pm

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


package OME::Web::AttributeTabularView;

use strict;
use vars qw($VERSION);
use OME;
use OME::Tasks::AttributeManager;
$VERSION = $OME::VERSION;
use CGI;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - MEX results";
}

sub getPageBody {
	my $self = shift;
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $cgi     = $self->CGI();

	my $body = '';
	
	##############################
	# Parse parameters and load attributes.
	die "MEX_OUT param is missing."
		unless $cgi->param('MEX_OUT');
	my $mex_out = $cgi->param('MEX_OUT');
	my @attr_set_list;
	foreach my $loc( split( /:/, $mex_out ) ) {
		my ($mex_id, $fo_id) = split( /\./, $loc )
			or die "Could not parse location $loc.\n"; 
		my $mex = $factory->loadObject( "OME::ModuleExecution", $mex_id )
			or die "Could not load a Module Execution with id $mex_id";
		my $fo = $factory->loadObject( "OME::Module::FormalOutput", $fo_id )
			or die "Could not load a Formal Output with id $fo_id";
		my $st = $fo->semantic_type()
			or die "Could not load a Semantic Type for Formal output (".$fo->id().").\n";
		my @attrs = $factory->findAttributes( $st->name(), { 
			module_execution => $mex } )
			or die "Could not load attributes for loc $loc.\n"; 
		push( @attr_set_list, { attrs => \@attrs, mex => $mex, fo => $fo});
	}
	
	##############################
	# Merge attrs
	my $attrManager = OME::Tasks::AttributeManager->new( $session );
	my $attrTables = $attrManager->mergeMEXAttrs( \@attr_set_list );


	##############################
	# Print tables
	foreach my $tbl_set(@$attrTables) {
		my $tbl = $tbl_set->{ table };
		my $srcs = $tbl_set->{ srcs };
		# FIXME
		# table header
		# add link 'click to download as tab delimited table'
		$body .= "Data sources:<br><ul>";
		$body .= "<li><b>".$_->{mex}->module()->name()." (".$_->{mex}->id().") - ".$_->{fo}->name()."</li>"
			foreach( @$srcs );
		$body .= "</ul>";


 		my @columns = keys %{$tbl->[0]};
		$body .= $cgi->start_table({-border => 1, -cellspacing => 4, -cellpadding => 5});

		# column headers
		$body .= $cgi->Tr({-align => 'left', -valign => 'middle'},
			map( $cgi->td( $cgi->b( $_ ) ), @columns ),
		);
		
		# row data
		foreach my $row (@$tbl) {
			$body .= $cgi->TR( 
				map( $cgi->td( $row->{$_} ), @columns )
			) ;
		}
		$body .= $cgi->end_table();
		$body .= "<br><br>";
	}
	
	return ('HTML',$body);
}





#---------------------
#PRIVATE METHODS
#---------------------
sub print_form{
	my $self = shift;
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $cgi     = $self->CGI();

	my $html = '';

  	return $html;
}


