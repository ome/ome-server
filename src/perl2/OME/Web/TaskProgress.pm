# OME/Web/TaskProgress.pm

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
#  Author:  Ilya G. Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::TaskProgress;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use base qw{ OME::Web::Authenticated };

use OME::Tasks::NotificationManager;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	
	$self->{ _default_Length } = 35;
	
	return $self;
}

sub getPageTitle {
	return "Tasks in the current user session" ;
}

{
	my $menu_text = "Tasks";

	sub getMenuText { return $menu_text }
}


=head2 getLocation
=cut

sub getLocation {
	my $self = shift;
	my $template = OME::Web::TemplateManager->getLocationTemplate('TaskProgress.tmpl');
	return $template->output();
}

# Override's OME::Web

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my @tasks;
	

	# The action that was "clicked"
	my $action = $cgi->param('action') || '';
	my @selected;
	if ($action eq 'Clear Selected') {
		OME::Tasks::NotificationManager->clear (id => ['in',[$cgi->param('selected')]])
			if( $cgi->param('selected') );
	} elsif ($action eq 'Clear All') {
		OME::Tasks::NotificationManager->clear ();
	} elsif ($action eq 'Clear Finished') {
		OME::Tasks::NotificationManager->clear (state => 'FINISHED');
	}

	@tasks = OME::Tasks::NotificationManager->list();

	my @active_tasks;
	my @other_tasks;
	foreach (@tasks) {
		if ($_->state() eq 'IN PROGRESS') {
			push (@active_tasks,$_);
		} else {
			push (@other_tasks,$_);
		}
	}
	@tasks = (@active_tasks,@other_tasks);
	
	my $body;
	if (scalar @tasks) {
		$body = 
			$cgi->startform( { -name => 'primary' } ).
			$self->Renderer()->renderArray( \@tasks, 'table', { type => 'OME::Task' } ).
			$cgi->hidden(-name=>'action').
			$cgi->endform();
	} else {
		$body = '<h3>No active tasks for this session.</h3>';
	}


	return ('HTML',$body);
}

1;
