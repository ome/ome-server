# OME/Util/Top.pm

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
# Written by: Tom Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------

package OME::Util::Top;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Carp;
use Getopt::Long;
use OME;
use OME::Session;
use OME::SessionManager;
use OME::AnalysisChain;
use OME::Tasks::NotificationManager;
use OME::Analysis::Engine::Worker;
use Term::Cap;
use Term::ANSIColor qw(:constants);
use File::stat;
use Time::Local;

use Getopt::Long;
Getopt::Long::Configure("bundling");


sub getCommands {
    return
      {
       'top'     => 'top',
      };
}

sub top_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    
    print <<"USAGE";
Usage:
    $script $command_name 
    
This utility prints out detailed information about OME Tasks that are executing 
or finished execution.

Options:

  -w , --wait optional flag specifying how many seconds to wait before updating
USAGE
    CORE::exit(1);
}

sub top {
	my $self = shift;
    my $session = $self->getSession();
    my $factory = $session->instance()->Factory();
	my $install_date = "UNKNOWN";
	
	my $update_delay = 10;
	
	GetOptions('wait|w' => \$update_delay);

	# figure out the day ome was installed based on when the environment file was modified
	if (-e "/etc/ome-install.store") {
		my $file_stat = stat("/etc/ome-install.store");
		$install_date = localtime($file_stat->atime);
	}
	
	# figure out about the terminal
	my $terminal = Term::Cap->Tgetent({OSPEED=>9600});
	my $clr_cmd = $terminal->Tputs('cl');
	
	while (1) {
		print $clr_cmd;
		
		my @tasks = OME::Tasks::NotificationManager->list;
		my @tasks_IP = OME::Tasks::NotificationManager->list(state=>'IN PROGRESS');
		my @tasks_F  = OME::Tasks::NotificationManager->list(state=>'FINISHED');
		my @tasks_A  = OME::Tasks::NotificationManager->list(state=>'ABORTED');
	
		
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		my $timestamp = time;
		my $timestr = localtime $timestamp;
		
		my @workers = $factory->findObjects('OME::Analysis::Engine::Worker', {__order=>['id']});
		my @workers_b = $factory->findObjects('OME::Analysis::Engine::Worker',{status => 'BUSY'});
		my @workers_i = $factory->findObjects('OME::Analysis::Engine::Worker',{status => 'IDLE'});
		my @workers_o = $factory->findObjects('OME::Analysis::Engine::Worker',{status => 'OFF-LINE'});
		printf "  _______          Workers: %d Total, %d busy, %d idle, %d off-line \n", 
			   scalar @workers, scalar @workers_b, scalar @workers_i, scalar @workers_o;
		printf " /=======\\     Tasks: %d Total, %d in progress, %d finished, %d aborted \n", 
		       scalar @tasks, scalar @tasks_IP, scalar @tasks_F, scalar @tasks_A; 
		printf "|===OME===|    OME %s was installed on %s\n", $OME::VERSION_STRING, $install_date;
		printf " \\=======/                 %s\n", $timestr;
		printf "\n";
		
		print "      TASK           STATUS                MESSAGE              ER  STEP#   PID\n";
		
		# print out the tasks
		foreach (@tasks) {				
			my ($task_str, $status_str, $message_str, $error_str, $step_str, $pid_str) 
				= ($_->name(), $_->state(), $_->message(), $_->error(), $_->last_step()."/".$_->n_steps(),
				   $_->process_id());
				   
			# truncate  the error msg to whether an error occured or not.
			if (defined $error_str) {
				$error_str = "Y";
			} else {
				$error_str = "N";
			}
			
			my @str = ($task_str, $status_str, $message_str, $error_str, $step_str, $pid_str) ;
			my ($task_len, $status_len, $message_len, $error_len, $step_len, $pid_len) = (19, 11, 30,1,5,5);
			my @str_len = ($task_len, $status_len, $message_len, $error_len, $step_len, $pid_len);
			
			# put all the strings on Procrustes' bed
			for (my $i=0; $i<scalar @str; $i++) {
				$str[$i] = ' ' unless defined $str[$i];
				$str[$i] = substr($str[$i], 0, $str_len[$i]);
				my $tmp_str = $str[$i]." "x($str_len[$i] - length($str[$i])); # same thing
				$str[$i] = $tmp_str;
			}
			print $str[0]." ".$str[1]."  ".$str[2]."  ".$str[3]."  ".$str[4]."  ".$str[5]."\n";
		}
		
		for (my $i = 0; $i < 15-(scalar @tasks)-(scalar @workers); $i++){
			print "\n";
		}
		
		print "WID  STATUS        PID                               URL\n";
		foreach (@workers) {
			my ($wid_str, $status_str, $pid_str, $url_str)
				= ($_->worker_id(), $_->status(), $_->PID(), $_->URL());

			my @str = ($wid_str, $status_str, $pid_str, $url_str);
			my ($wid_length, $status_len, $pid_len, $url_len) = (5,10,10,45);
			my @str_len = ($wid_length, $status_len, $pid_len, $url_len);
			
			# put all the strings on Procrustes' bed
			for (my $i=0; $i<scalar @str; $i++) {
				$str[$i] = ' ' unless defined $str[$i];
				$str[$i] = substr($str[$i], 0, $str_len[$i]);
				my $tmp_str = $str[$i]." "x($str_len[$i] - length($str[$i])); # same thing
				$str[$i] = $tmp_str;
			}
			print $str[0]." ".$str[1]."  ".$str[2]."  ".$str[3]."\n";
		}
		sleep($update_delay);
	}
}