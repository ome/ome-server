# OME/Web/ExecuteChain.pm

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


package OME::Web::ExecuteChain;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

use OME::DBObject;
use OME::Analysis::Engine;
use OME::Tasks::ChainManager;
use OME::Fork;

use base qw{ OME::Web::Authenticated };

sub getPageTitle {
	return "Open Microscopy Environment - Execute Analysis Chain";
}

{
	my $menu_text = "Execute Chain";

	sub getMenuText { return $menu_text }
}

=head2 getLocation

=cut

sub getLocation {
	my $self = shift;
	my $template = OME::Web::TemplateManager->getLocationTemplate('ExecuteChain.tmpl');
	return $template->output();
}

sub getAuthenticatedTemplate {
    return OME::Web::TemplateManager->getActionTemplate('ExecuteChain.tmpl');
}


# Override's OME::Web
sub getPageBody {
	my ($self, $tmpl) = @_;
	my $body = "";
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $q = $self->CGI();
	
	if( $q->param( 'action' )  && ( $q->param( 'action' ) eq 'executeChain' ) ) {
		my $chain = $factory->loadObject( "OME::AnalysisChain", $q->param( 'chain_id' ) )
			or die "Could not load dataset ".$q->param( 'Dataset' );
	
		# gather user inputs
		my $cmanager = OME::Tasks::ChainManager->new($session);
		my $user_inputs = $self->collect_user_inputs( $chain );
				
		if( $q->param( 'Dataset' ) && defined $user_inputs ) {
			my $dataset = $factory->loadObject( 'OME::Dataset', $q->param( 'Dataset' ) )
				or die "Could not load dataset ".$q->param( 'Dataset' );
			
			# execute chain
			my $doNotReuseResults = $q->param( 'ReExecuteChain' );
			my $reuseResults = ($doNotReuseResults ? 0 : 1 );
			OME::Fork->doLater ( sub {
				OME::Analysis::Engine->executeChain(
					$chain, $dataset, $user_inputs, undef, 
					ReuseResults => $reuseResults
				) or die "Could not execute analysis chain";
			} );
			
			# If we've made it this far, then there should be a task
			# for the user to view. Forward them to the task page.
			return( 'REDIRECT', $self->pageURL('OME::Web::TaskProgress') );
		}
	} 
	
	$body .= $self->printForm($tmpl);

	return ('HTML',$body);
}

sub printForm {
	my ($self, $tmpl) = @_;
	my $session  = $self->Session();
	my $factory  = $session->Factory();
	my $q        = $self->CGI();
	my $errorMsg = '';
	my $cmanager = OME::Tasks::ChainManager->new($session);

	my $chain_id =  $q->param( 'chain_id' );
	my ($submit, $user_inputs_mandatory, $user_inputs_optional);
	if( $chain_id ) {
		my $chain            = $factory->loadObject( 'OME::AnalysisChain', $chain_id );
		my $user_input_list  = $cmanager->getUserInputs($chain);
		foreach my $input ( @$user_input_list ) {
			my ( $node, $module, $formal_input, $semantic_type ) = @$input;
			my $fieldName = 'userInput'.$formal_input->id;
			my ($package_name, $common_name, $formal_name, $ST) = 
					$self->_loadTypeAndGetInfo( '@'.$semantic_type->name );
			# Select
			my $field = "<li>".
				$self->Renderer()->render( $module, 'ref' ) . "." .
				$self->Renderer()->render( $formal_input, 'ref' ) . 
				( $formal_input->optional ? " (optional): " : " (required): " ) . 
				$self->SearchUtil()->getObjectSelectionField( $formal_name, $fieldName, {
					select_one  => !$formal_input->list,
					list_length => 1,
					max_elements_in_list => -1, 
				} );
			# or Create
			my $create_link = $q->a( { 
				-href => "javascript: creationPopup( '$formal_name','$fieldName' );"}, 
						 "Create a new $common_name" );
			$field .= " or " . $create_link . "</li>";

			if( $formal_input->optional ) {
				$user_inputs_optional .= $field;
			} else {
				$user_inputs_mandatory .= $field;
			}
		}
		
		# Gather user inputs, see if all mandatory ones are populated. 
		my $user_inputs = $self->collect_user_inputs( $chain ) || {};
		my @mandatory_inputs = grep( (not $_->[2]->optional), @$user_input_list );
		foreach my $input ( @mandatory_inputs ) {
			my ( $node, $module, $formal_input, $semantic_type ) = @$input;
			if( !exists( $user_inputs->{ $formal_input->id } ) && $q->param( 'action' ) eq 'executeChain' ) {
				$errorMsg .= "Input ".
					$self->Renderer()->render( $module, 'ref' ) . "." .
					$self->Renderer()->render( $formal_input, 'ref' ) . 
					" must be filled out.<br/>\n";
			}
		}
		
		$submit = $q->button(
			-value   => 'Execute Chain',
			-onClick => "javascript: document.forms['primary'].elements['action'].value='executeChain'; document.forms['primary'].submit();"
		);
	} else {
		$submit = $q->button(
			-value   => 'Examine chain inputs',
			-onClick => "javascript: document.forms['primary'].elements['action'].value='refresh'; document.forms['primary'].submit();"
		);
	}

	$tmpl->param( {
		error_msg     => $errorMsg, 
		chooseChain   => $self->SearchUtil()->getObjectSelectionField( 'OME::AnalysisChain', 'chain_id', {
			select_one  => 1,
			list_length => 1,
		} ). $q->checkbox( -name => 'ReExecuteChain', -value => 1, -label => 'Re-Execute Chain' ),
		chooseDataset => $self->SearchUtil()->getObjectSelectionField( 'OME::Dataset', 'Dataset', {
			default_obj => $session->dataset,
			select_one  => 1,
			list_length => 1,
		} ),
		mandatoryInputs => "<ul>".$user_inputs_mandatory."</ul>",
		optionalInputs  => "<ul>".$user_inputs_optional."</ul>",
		submit          => $submit
	} );
	my $html =
		$q->startform( { -name => 'primary', 
				 -enctype => 'multipart/form-data' } ).
		$tmpl->output().
		$q->hidden( -name => 'action' ).
		$q->endform();

	return $html;
}

sub collect_user_inputs {
	my ($self, $chain) = @_;
	my $session  = $self->Session();
	my $factory  = $session->Factory();
	my $q        = $self->CGI();
	my $cmanager = OME::Tasks::ChainManager->new($session);
	
	my $user_inputs = {};
	my $user_input_list  = $cmanager->getUserInputs($chain);
	foreach my $input ( @$user_input_list ) {
		my ( $node, $module, $formal_input, $semantic_type ) = @$input;
		my $fieldName = 'userInput'.$formal_input->id;
		if( $q->param( $fieldName ) ) {
			my @object_ids = $q->param( $fieldName );
			my %mexes = ();
			foreach my $id ( @object_ids ) {
				my $obj = $factory->loadObject( $semantic_type, $q->param( $fieldName ) )
					or die "Could not loadObject( $semantic_type, \$q->param( $fieldName ) )";
				$mexes{ $obj->module_execution_id } = $obj->module_execution;
			}
			$user_inputs->{ $formal_input->id } = [values %mexes]
				if( scalar( keys %mexes ) > 0 );
		}
		if( ( not exists $user_inputs->{ $formal_input->id } ) && (not $formal_input->optional )) {
			return undef;
		}
	}

	return $user_inputs;
}

1;
