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
use base qw{ OME::Web };

use CGI;
use OME::Tasks::NotificationManager;
use OME::Web::DBObjTable;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	
	$self->{ _default_Length } = 25;
	
	return $self;
}

sub getPageTitle {
	return "Tasks in the current user session" ;
}

{
	my $menu_text = "Tasks";

	sub getMenuText { return $menu_text }
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $user = $self->Session()->User();
	my @tasks = OME::Tasks::NotificationManager->list();
	my $tableMaker = OME::Web::DBObjTable->new( CGI => $cgi );
	

	# The action that was "clicked"
	my $action = $cgi->param('action') || '';
	my @selected;
	if ($action eq 'Clear Selected') {
		@selected = $cgi->param('selected');
	} elsif ($action eq 'Clear All') {
		push (@selected,$_->id()) foreach @tasks;
	}
	
	foreach (@selected) {
		OME::Tasks::NotificationManager->clear (id => $_);
	}
	
	# reload the tasks after 'action' if any.
	@tasks = OME::Tasks::NotificationManager->list() if scalar (@selected);

	my $body;
	if (scalar @tasks) {
		$body = $tableMaker->getTable( {
			title            => 'Tasks',
			noSearch         => 1,
			select_column    => 1,
			actions          => ['Update','Clear Selected','Clear All'],
			select_column    => 1,
			select_name      => 'selected',
			noTxtDownload    => 1,
			},
			'OME::Task', \@tasks );
	} else {
		$body = '<h3>No active tasks for this session.</h3>';
	}


	return ('HTML',$body);
}

######################

sub __printForm {
	my $self = shift;
	my $q = $self->CGI();
	my $group_id = $self->User()->Group()->id();
	
	my @tasks = OME::Tasks::NotificationManager->list();
	my @rows;

	foreach (@tasks) {
		$q->td
	}

	my $metadata = $q->Tr({-bgcolor => '#FFFFFF'}, [
		$q->td( [
			$q->span("Name *"),
			$q->textfield( {
					-name => 'name',
					-size => 40
				}
			)
			]
		),
		$q->td( [
			$q->span("Description"),
			$q->textarea( {
					-name => 'description',
					-rows => 3,
					-columns => 50,
				}
			)
			]
		),
		]
	);

	my $footer_table = $q->table( {
			-width => '100%',
			-cellspacing => 0,
			-cellpadding => 3,
		},
		$q->Tr( {-bgcolor => '#E0E0E0'},
			$q->td({-align => 'left'},
				$q->span( {
						-class => 'ome_info',
						-style => 'font-size: 10px;',
					}, "Items marked with a * are required unless otherwise specified"
				),
			),
			$q->td({-align => 'right'},
				$q->a( {
						-href => "#",
						-onClick => "openExistingProject($group_id); return false",
						-class => 'ome_widget'
					}, "Existing Projects"
				),
				"|",
				$q->a( {
						-href => "#",
						-onClick => "document.forms['metadata'].action.value='create'; document.forms['metadata'].submit(); return false",
						-class => 'ome_widget'
					}, "Create Project"
				),
			),
		),
	);


	my $border_table = $q->table( {
			-class => 'ome_table',
			-width => '100%',
			-cellspacing => 1,
			-cellpadding => 3,
		},
		$q->startform({-name => 'metadata'}),
		$q->hidden(-name => 'action', -default => ''),
		$metadata,
	);	

	return $border_table .
	       $footer_table .
		   $q->endform();
}

# Clean superfluous spaces
sub cleaning {
	my ($string)=@_;

	chomp($string);
	$string=~ s/^\s*(.*\S)\s*/$1/;

	return $string;
}


1;
