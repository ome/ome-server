#!/usr/bin/perl -w
# Author:  Ilya G. Goldberg (igg@mit.edu)
# Copyright 1999-2001 Ilya G. Goldberg
# This file is part of OME.
# 
#     OME is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     OME is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with OME; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# 
#

use OMEpl;

use strict;
use vars qw ($OME $cgi);
$OME = new OMEpl;
$cgi = $OME->cgi();

KillSession($cgi->param()) if $cgi->param();
DisplaySession ();
$OME->Finish();
undef $cgi;
undef $OME;



sub DisplaySession {
my (@tableRows,@tableColumns);
my ($key,$value);
my $PID;
my $i=0;
my $session;
my $analysis;
my $time;
my $userSessions = $OME->GetUserSessions();
	push (@tableRows,$cgi->th([
		'Status','PID','Time running','Datasets Completed','Last DatasetID','Time since last completed','Avg. time / dataset','Message']));
	foreach (@$userSessions) {
		$session = $OME->Session ({_session_id => $_});

		while ( ($PID,$analysis) = each %{$session->{Analyses}} ) {
			$analysis->{Status} = 'DIED' unless kill (0,$analysis->{ProgramPID}) or $analysis->{Status} eq 'Finished';
			
			if (defined $analysis->{TimeFinished} and $analysis->{TimeFinished}) {
				$time = $analysis->{TimeFinished};
			} else {
				$time = time;
			}
			$analysis->{Status} = 'Idle' unless defined $analysis->{Status} and $analysis->{Status};
			push (@tableRows,$cgi->td ([
				$analysis->{Status},
				$PID,
				$analysis->{ProgramStarted} ? $time - $analysis->{ProgramStarted} : '',
				(defined $analysis->{NumDatasetsCompleted} and defined $analysis->{NumSelectedDatasets}) ? 
					$analysis->{NumDatasetsCompleted}.' / '.$analysis->{NumSelectedDatasets} : '',
				$analysis->{LastCompletedDatasetID} ? $analysis->{LastCompletedDatasetID} : '',
				$analysis->{LastCompletedDatasetTime} ? $time - $analysis->{LastCompletedDatasetTime}: '',
				$analysis->{AverageTimePerDataset} ? $analysis->{AverageTimePerDataset} : '',
				$analysis->{Error} ? "<font size=-1>$analysis->{Error}</font>" : '',
				$analysis->{Status} eq 'Executing' ? $cgi->submit (-name=>'Abort-'.$PID,-value=>'Abort') : 
						$cgi->submit (-name=>'Clear-'.$PID,-value=>'Clear')
			]));
		}
		$OME->Session ($session);
	}
	
	print $cgi->header;
	print $cgi->start_html(-title=>'OME Status');
	print $cgi->start_form();
	print $cgi->submit (-name=>'Refresh',-value=>'Refresh');
	print $cgi->table({-border=>1,-cellspacing=>1,-cellpadding=>1},
			$cgi->Tr(\@tableRows));
	print $cgi->end_form;
	print $cgi->end_html;
	


}

sub KillSession {
my ($button) = @_;
my ($action,$PID) = split (/-/,$button);
my %signal;
use Config;
my $i=0;
my $value;

	defined $Config{sig_name} || die "No sigs?";
	foreach $value (split(' ', $Config{sig_name})) {
		$signal{$value} = $i;
		$i++;
	}
	if ($action eq 'Abort') {
		kill ($signal{'USR2'},$PID);
	} elsif (defined $action and $action and defined $PID and $PID) {
		my $session = $OME->Session;
		delete $session->{Analyses}->{$PID};
		$OME->Session ($session);
	}

}
