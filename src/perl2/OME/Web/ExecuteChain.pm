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


# Override's OME::Web
sub getPageBody {
	my $self = shift;
	my $body = "";
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $cgi = $self->CGI();
	
	if( $cgi->param( 'executeChain' ) ) {
		my $chain = $factory->loadObject( "OME::AnalysisChain", $cgi->param( 'chain_id' ) );
	
		# prompt for user inputs
		my $cmanager = OME::Tasks::ChainManager->new($session);
		my $user_input_list = $cmanager->getUserInputs($chain);		
#		return ('HTML', $self->collect_user_inputs( $chain ) ) if ( scalar @$user_input_list );
		
		return ('HTML', "Cannot execute without a dataset selected" )
			unless $session->dataset();
		
		# execute chain
		my $doNotReuseResults = $cgi->param( 'ReExecuteChain' );
		my $reuseResults = ($doNotReuseResults ? 0 : 1 );
		OME::Fork->doLater ( sub {
			OME::Analysis::Engine->executeChain(
				$chain,$session->dataset,{ }, undef, 
				ReuseResults => $reuseResults
			) or die "Could not execute analysis chain";
		} );
		
		# If we've made it this far, then there should be a task
		# for the user to view. Forward them to the task page.
		return( 'REDIRECT', $self->pageURL('OME::Web::TaskProgress') );

	} else {
		$body .= $self->printForm();
	}

	return ('HTML',$body);
}

sub printForm {
	my $self = shift;
	my $text = "";
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $cgi = $self->CGI();

	my @chains = $factory->findObjects( "OME::AnalysisChain" );
	
	# filter out all chains with free inputs for now
	my $cmanager = OME::Tasks::ChainManager->new($session);
	my @chains_without_free_inputs;
	foreach my $chain ( @chains ) {
		my $user_input_list = $cmanager->getUserInputs($chain);
		push( @chains_without_free_inputs, $chain )
#			if scalar(@$user_input_list) eq 0;
if( ( scalar(@$user_input_list) eq 0 ) ||
    ( grep( (not $_->[2]->optional), @$user_input_list ) eq 0 ) );
	}
	@chains = @chains_without_free_inputs;
	
	my $labels;
	%$labels = map{ $_->id() => $_->name() } @chains;
	$text .= "<h2>Execute Analysis Chain</h2>";
	$text .= $cgi->startform( { -name => 'primary' } );
	$text .= $cgi->popup_menu( 
		-name   => 'chain_id',
		-labels => $labels,
		-values => [keys %$labels],
	);
	$text .= '<br>'.$cgi->checkbox( -name => 'ReExecuteChain', -value => 1, -label => 'Re-Execute Chain' );
	$text .= '<br>'.$cgi->submit(
		-name  => 'executeChain',
		-value => 'Execute Chain'
	);
	$text .= $cgi->endform;

	return $text;
}

sub collect_user_inputs {
	return "This chain requires User inputs. User input collection is not yet supported."
}

1;
