# OME/Web/ViewMEXresults.pm

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


package OME::Web::ViewMEXresults;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - MEX results";
}

{
	my $menu_text = "View MEX Results";

	sub getMenuText { return $menu_text }
}

sub getPageBody {
	my $self = shift;
	my $session = $self->Session();
	my $cgi     = $self->CGI();

	my $body;
	
	if( $cgi->param('MEX_ID') ) {
		$body .= $self->display_MEX();
	} else {
		$body .= $self->print_form();
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

# expand to allow MEX retrieval by more methods (e.g. browse by module name, etc) ?
	my $html;
	$html .= "<h3>Type the Module Execution ID you wish to see results for.</h3>";

	$html .= $cgi->startform();
	$html .= $cgi->start_table({-border => 0, -cellspacing => 4, -cellpadding => 0});
	$html .= $cgi->Tr({-align => 'left', -valign => 'middle'},
		  $cgi->td($cgi->b("MEX_ID"),
			   $cgi->textfield(-name => 'MEX_ID',
					   -size => 10)), 
		  $cgi->td({-colspan => 2},
			   $cgi->submit({-name  => 'display_results',
					 -value => 'Display Results'})));
	$html .= $cgi->end_table;

	$html .= $cgi->endform();

  	return $html;
}


sub display_MEX{
	my $self = shift;
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $cgi     = $self->CGI();

	my $MEX_ID = $cgi->param('MEX_ID')
		or die "MEX_ID not specified as URL param";
	my $MEX = $factory->loadObject( "OME::ModuleExecution", $MEX_ID ) 
		or die "MEX_ID ($MEX_ID) does not exist in database";
	
	my $module;
	$module = $MEX->module()
		or die "This is a NULL module MEX. This implementation only supports display of not NULL module MEX.";
	
	my @Input_list = $MEX->inputs();
	my @FI_list = $module->inputs();
	my @FO_list = $module->outputs();

	my $html;
	$html .= "<a name='top'><center><h2>Displaying Module EXecution (MEX) results.</h2>";
	# module info block
	$html .= "<b>MEX ID: </b> ".$MEX_ID."<br>";
	$html .= $cgi->start_table({-border => 1, -cellspacing => 4, -cellpadding => 5});
	$html .= $cgi->Tr({-align => 'center', -valign => 'middle'},
		$cgi->td( { -colspan => 2 },
			$cgi->b( $module->name() ) ));
	$html .= $cgi->Tr({ -valign => 'middle' },
		$cgi->td( $cgi->b( 'Formal Inputs' ) ),
		$cgi->td( $cgi->b( 'Formal Outputs' ) ),
			);
	$html .= $cgi->TR(  
		$cgi->td( {-align => 'left'},
			join( '<br>', map( '<a href="#Input_'.$_->name().'">'.$_->name().'</a>',@FI_list))
		 ),
		$cgi->td( {-align => 'right'},
			join( '<br>', map( '<a href="#Output_'.$_->name().'">'.$_->name().'</a>',@FO_list))
		),
	);			
	$html .= $cgi->end_table;
	$html .= '</center>';
# add link to as yet unwritten ViewModule page

	################################
	# FI tables
	$html .= "<h3>Actual Inputs:</h3>" .
		$cgi->start_table({-border => 0, -cellspacing => 4, -cellpadding => 0}) .
		"<tr><td width='100'></td><td>"
		if( scalar( @Input_list ) > 0 );
	foreach my $input( @Input_list ) {
		my $FI = $input->formal_input();
		my $ST = $FI->semantic_type()
			or die "Formal Input ".$FI->name()." does not have a ST.";
		my @SE_list = $ST->semantic_elements();
		my @attr_list = $factory->findAttributes( $ST, module_execution => $input->input_module_execution() );

	 	$html .= "<a name='Input_".$FI->name()."'>"; 
	 	$html .= "<a href='top'>Top</a><br>"; 
		$html .= "Formal Input: <b>".$FI->name()."</b><br>";
		$html .= "Semantic Type: <b>".$ST->name()."</b><br>";
		$html .= "Source Module Name (MEX_ID): <b>";
		$html .= "<a href='/perl2/serve.pl?Page=".ref($self)."&MEX_ID=".$input->input_module_execution()->id()."'>";
		$html .= $input->input_module_execution()->module()->name()
			if $input->input_module_execution()->module();
		$html .= " (".$input->input_module_execution()->id().")</a></b>";
# add link to as yet unwritten ViewST page
# add link 'click to download as tab delimited table'
		
		$html .= $cgi->start_table({-border => 1, -cellspacing => 4, -cellpadding => 5});
		$html .= $cgi->Tr({-align => 'left', -valign => 'middle'},
			map( $cgi->td( $cgi->b( $_->name() ) ), @SE_list ),
				);
		foreach my $attr ( @attr_list ) {
			my $data_hash = $attr->getDataHash();
			$html .= $cgi->TR( 
				map( $cgi->td( $data_hash->{$_->name()} ), @SE_list )
			);			
		}
		$html .= $cgi->end_table;
		$html .= "<br><br>";
	}
	$html .= "</td></tr></table>";


	################################
	# FO tables
	$html .= "<h3>Outputs:</h3>" .
		$cgi->start_table({-border => 0, -cellspacing => 4, -cellpadding => 0}) .
		"<tr><td width='100'></td><td>"
		if( scalar( @FO_list ) > 0 );
	foreach my $FO( @FO_list ) {
		my $ST = $FO->semantic_type()
			or die "Formal Output ".$FO->name()." does not have a ST.";
		my @SE_list = $ST->semantic_elements();
		my @attr_list = $factory->findAttributes( $ST, module_execution => $MEX );

	 	$html .= "<a name='Output_".$FO->name()."'>"; 
	 	$html .= "<a href='top'>Top</a><br>"; 
		$html .= "Formal Output: <b>".$FO->name()."</b><br>";
		$html .= "Semantic Type: <b>".$ST->name()."</b><br>";
# add link to as yet unwritten ViewST page
# add link 'click to download as tab delimited table'

		$html .= $cgi->start_table({-border => 1, -cellspacing => 4, -cellpadding => 5});
		$html .= $cgi->Tr({-align => 'left', -valign => 'middle'},
			map( $cgi->td( $cgi->b( $_->name() ) ), @SE_list )
				);
		foreach my $attr ( @attr_list ) {
			my $data_hash = $attr->getDataHash();
			$html .= $cgi->TR( 
				map( $cgi->td( $data_hash->{$_->name()} ), @SE_list )
			);			
		}
		$html .= $cgi->end_table;
		$html .= "<br><br>";
	}
	$html .= "</td></tr></table>";



  	return $html;
}
