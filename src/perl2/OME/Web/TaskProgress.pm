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
	
	# create a virtual column "t_elapsed" in the table
	my ($t6, $t5, $t4, $t3, $t2, $year, $wday, $yday, $isdst) = localtime(time);
	$t2 += 1; # month range is from 0 to 11 not 1 to 12

	foreach (@tasks) {
		my $t_start = $_->{"__fields"}->{tasks}->{"t_start"};
		my $t_stop  = $_->{"__fields"}->{tasks}->{"t_stop"};
		
		use integer;
		$t_start =~ m/^(\d*)-(\d*)-(\d*) (\d*):(\d*):(\d*)/;
		my $sec_start = ((($2 * 30 + $3) * 24 + $4) * 60 + $5) * 60 + $6;

		my $sec_stop;
		if (defined($t_stop) and $t_stop ne 'now') {
			$t_stop =~ m/^(\d*)-(\d*)-(\d*) (\d*):(\d*):(\d*)/;
			$sec_stop  = ((($2 * 30 + $3) * 24 + $4) * 60 + $5) * 60 + $6;
		} else {
			$sec_stop  = ((($t2 * 30 + $t3) * 24 + $t4) * 60 + $t5) * 60 + $t6;
		}
		
		my $remain_sec = $sec_stop - $sec_start;
		my $hrs  = $remain_sec / (60*60);
		$remain_sec -= $hrs * (60*60);
		my $mins = $remain_sec / 60;
		$remain_sec -= $mins * 60;
		
		$_->{"__fields"}->{tasks}->{"t_elapsed"} 
			= sprintf("%02d:%02d:%02d", $hrs, $mins, $remain_sec);		
    }

	my $body;
	if (scalar @tasks) {
		$body = 
			$cgi->startform().
			$self->Renderer()->renderArray( \@tasks, 'table', { type => 'OME::Task' } ).
			$cgi->hidden(-name=>'action').
			$cgi->endform();
	} else {
		$body = '<h3>No active tasks for this session.</h3>';
	}


	return ('HTML',$body);
}

1;
