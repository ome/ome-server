# OME/Web/Validation.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


package OME::Web::Validation;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Dataset;
use OME::Project;
use OME::Image;

use base qw{ OME::Web };
__PACKAGE__->mk_classdata('ReloadHome');


sub getPageTitle {
	return "Open Microscopy Environment - Validation";
}

sub getPageBody {
	my $self = shift;
	my $body = "";

	$body .= $self->showMessage();

    return ('HTML',$body);
}

=pod

=head2 isRedirectNecessary

What it does: Determines if it is necessary to redirect. One example is if a project is not defined for the session.

Who calls it: OME::Web::Home

What it returns: 1 or undef 

=cut

# The ReloadHome class variable may need to be thought over some more.
# The only places it is accessed is isRedirectNecessary and ReloadHomeScript. 
# So modification should be simple.
sub isRedirectNecessary {
	my $self = shift;
	my $doNotSetFlag = shift;
	my $session = $self->Session()
		or die ref ($self) . " cannot find session via self->Session()";
	$self->ReloadHome( undef )
		unless $doNotSetFlag;

	# put all tests necessary for redirection here.
	if( (not defined $session->project()) || (not defined $session->dataset()) ) {
		$self->ReloadHome( 1 )
			unless $doNotSetFlag;
		return 1;
	}
	return undef;
}

=pod

=head2 ReloadHomeScript

What it does: Returns javascript to reload OME::Web::Home if it's necessary to do so

What it returns: 1 or undef 

=cut

sub ReloadHomeScript {
	my $self = shift;
	my $reloadHomeFlag = $self->ReloadHome();
	return "<script>top.location.href = top.location.href;</script>"
		if( defined $reloadHomeFlag || $self->isRedirectNecessary(1));
	return "";
}


=pod

=head2 showMessage

What it does: determines what is wrong, calls appropriate subroutine to display message of what is wrong and give the user options of dealing with it.

It is internally referenced. It returns html snippets.

=cut
sub showMessage {
	my $self = shift;
	my $session = $self->Session();
	
	return $self->projectNotDefined()
		if(not defined $session->project());
	return $self->datasetNotDefined()
		if(not defined $session->dataset());
	
}

=pod

=head2 projectNotDefined

What it does: returns a message explaining the project is not defined and gives the user options of how to deal with it.

=cut

sub projectNotDefined {
	my $self    = shift;
	my $session = $self->Session();
	my $user    = $session->User()
		or die ref ($self)."->projectNotDefined() say: There is no user defined for this session.";
	my $cgi     = $self->CGI();
	my $text    = '';
	
	# Has this function been called inappropriately?
	die ref ($self)."->projectNotDefined() has been called inappropriately. There is a project defined for this session."
		if( defined $session->project() );
	
	my @projects = OME::Project->search( group_id => $user->group()->group_id());
	
	# Is this a first time login? How do I check for that? For the time being, I'm going to say if neither a project nor dataset is defined, it is a first time login. Since this function won't be called if a project
	if( not defined $session->dataset() ) {
		$text .= "<p>You have started a new session. There are a few things you need to do to set up the session. This will lead you through all necessary steps.</p>";
	}
	
	$text .= "<p>There is not a project defined for your session. <li>Click ".$cgi->a({href=>'serve.pl?Page=OME::Web::MakeNewProject'},'here')." to create a new project. ";
	$text .= "<li>Click ".$cgi->a({href=>'serve.pl?Page=OME::Web::ProjectSwitch'},'here')." to choose an existing project."
		if( (scalar @projects) > 0 );
	$text .= "</p>";
	$text .= $self->printLogout();
	
	return $text;
}

=pod

=head2 datasetNotDefined

What it does: returns a message explaining the dataest is not defined and gives the user options of how to deal with it.

=cut

sub datasetNotDefined {
	my $self    = shift;
	my $session = $self->Session();
	my $cgi     = $self->CGI();
	my $text    = '';
	my $project = $self->Session()->project()
		or die "There is no project defined for this session.\n";
	my $user    = $session->User()
		or die "There is no user defined for this session.\n";
	
	# Has this function been called inappropriately?
	die "OME::Web::Validation->datasetNotDefined() has been called inappropriately. There is a dataset defined for this session."
		if( defined $session->dataset() );

	# if the project only has one dataset, we can fix the problem.
	my @datasets = $project->datasets();
	if( scalar @datasets == 1 ) {
		$text .= $self->ReloadHomeScript();
		$session->dataset( $datasets[0] );
		$session->writeObject();
		return $text;
	}
	
	@datasets    = OME::Dataset->search( group_id => $user->group()->group_id());
	my @images   = OME::Image->search( group_id => $user->group()->group_id());
	
	$text .= "<p>There is not a dataset defined for your session. <li>Click ".$cgi->a({href=>'/JavaScript/DirTree/index.htm'},'here')." to create a new dataset by importing images. ";
	$text .= "<li>Click ".$cgi->a({href=>qq{javascript: alert('This is not implemented yet.')}},'here')." to make a dataset from existing images. "
		if( (scalar @images) > 0 );
	$text .= "<li>Click ".$cgi->a({href=>"/perl2/serve.pl?Page=OME::Web::ProjectDataset"},'here')." to choose an existing dataset."
		if( (scalar @datasets) > 0 );
	$text .= "</p>";
	$text .= $self->printLogout();
	
	return $text;
}

=pod

=head2 printLogout

What it does: return a link to logout

=cut
sub printLogout {
	return qq{Click <a href="/perl2/serve.pl?Page=OME::Web::Logout">here</a> to logout.};
}

1;