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

package OME::Web::DirTreeSelect;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::Web;
use OME::DBObject;
@ISA = ("OME::Web");

use OME::Tasks::ImageTasks;

sub getPageTitle {
	return "Select Images (created by OME::Web::DirTreeSelect)";
}

sub getPageBody {
	my $self = shift;
	my $rootName = "Home";
	my $cgi = $self->CGI();
	my $rootDir = $self->User()->data_dir();

	my @selections = ();
	my $selection;
	my @paths;
	my $body = '';

	foreach $selection ($cgi->url_param()) {
		$selection = $cgi->unescape($selection);
		if ( not ($selection eq 'action' or $selection eq 'keywords' or $selection eq 'Page' or not $selection)) {
			push (@selections,$selection);
			push (@paths,$rootDir.$selection);
		}
	}
	
	@selections = sort {uc($a) cmp uc($b)} @selections;

	if (scalar (@selections) > 0) {
		if ($cgi->param('Import')) {
			my ($datasetID,$dataset);
			my $session = $self->Session();
			my $project = $session->project();
			my $radioSelect = $cgi->param('DoDatasetType');
			if ($radioSelect eq 'addNewDataset') {
				$dataset = $project->newDataset($cgi->param('newDataset'));
				die ref($self)."->import:  Could not create dataset '".$cgi->param('newDataset')."'\n" unless defined $dataset;
			} elsif ($radioSelect eq 'addExistDataset') {
				$dataset = $project->addDatasetID ($cgi->param('addDataset'));
				die ref($self)."->import:  Could not load dataset '".$cgi->param('addDataset')."'\n" unless defined $dataset;
			}

			my $errorMessage = '';
			if ($dataset) {
				$dataset->writeObject();
			    $errorMessage = OME::Tasks::ImageTasks::importFiles($self->Session(), $dataset, \@paths);
				die $status if $status;
				$dataset->writeObject();
				$project->writeObject();
				$session->dataset($dataset);
				$session->writeObject();
			} else {
				$errorMessage = "No Dataset to import into.\n";
			}
			if ($errorMessage) {
				$body .= $cgi->h3($errorMessage);
				$body .= $self->print_form($selections[0]);
				$body .= $cgi->h4 ('Selected Files and Folders:');
				$body .= join ("<BR>",@selections);
			}
		}
		# If we have a selection, but import button wasn't clicked, print the form:
		else {
			$body .= $self->print_form($selections[0]);
			$body .= $cgi->h4 ('Selected Files and Folders:');
			$body .= join ("<BR>",@selections);
		}
	
	# If we gots no selection, just print a handy hint.
	} else {
		$body .=  $cgi->h4 ('Select Files and Folders in the menu tree on the left.');
	}

	return ('HTML', $body);

}



sub print_form {
my $self = shift;
my $recentSelection = shift;
my $cgi = $self->CGI();

# Stub: this needs to be an array of dataset names for the user to
#       "Add imported images to existing dataset"
my $project = $self->Session()->project();
my @datasets = $project->unlockedDatasets() if defined $project;
my %datasetHash  = map { $_->ID() => $_->name()} @datasets if @datasets > 0;;
my $text = '';

	$text .= "\n".$cgi->startform;
	$text .= "<CENTER>\n	".$cgi->submit (-name=>'Import',-value=>'Import Selected Files/Folders')."\n</CENTER>\n";

	# this sets default datasetName to the last directory path
	my @pathElements = split ('/',$recentSelection);
	my $datasetName = $pathElements[$#pathElements-1];
	my ($key, $value,$defaultDatasetID);
	while (($key, $value) = each %datasetHash) {
		$defaultDatasetID = $key if $value eq $datasetName;
	}
	
	my $defaultRadio = 'addNewDataset';
	$defaultRadio = 'addExistDataset' if $defaultDatasetID;
	my $newDatasetName = '';
	$newDatasetName = $datasetName unless $defaultDatasetID;
	$defaultDatasetID = $self->Session()->dataset()->ID() unless $defaultDatasetID;
	
	$text .= "<BLOCKQUOTE>\n";
	my @datasetRadios = $cgi->radio_group(-name=>'DoDatasetType',
				-values => ['addNewDataset','addExistDataset'],
				-default=>$defaultRadio,
				-labels => {
					'addNewDataset'   => 'New dataset named: ',
					'addExistDataset' => 'Add imported images to existing dataset ',
				}
			);

	$text .= '	'.$datasetRadios[0]."\n	".$cgi->textfield(-name=>'newDataset', -size=>32,-default=>$newDatasetName)."<BR>\n";
	$text .= '	'.$datasetRadios[1]."\n	".$cgi->popup_menu(-name=>'addDataset',-values=>\%datasetHash,-default=>$defaultDatasetID)."<BR>\n";

	$text .= "</BLOCKQUOTE>\n";

	$text .= $cgi->endform."\n";
	return $text;
}




sub process_form {
my $self = shift;
my $datasetIDs = shift;
my $cgi = $self->CGI();
my $message;
#remove OME when fixing this function
my $OME;


	print STDERR "DirTreeSelect:  process_form\n";
	if ($cgi->param('DoProject') eq 'on') {
		print STDERR "DirTreeSelect:  process_form: DoProject\n";
		my $radioSelect = $cgi->param('DoProjectType');
		if ($radioSelect eq 'addExistProj') {
			print STDERR "DirTreeSelect:  process_form: addExistProj\n";
			if ($OME->AddProjectDatasets ($OME->GetProjectID(ProjectName=>$cgi->param('addProject')), DatasetIDs=>$datasetIDs)) {
				$message = "Selected datasets added to project '".$cgi->param('addProject')."'.";
			} else {
				$message = $OME->errorMessage;
			}
				
		} elsif ($radioSelect eq 'addNewProj') {
			print STDERR "DirTreeSelect:  process_form: addNewProj\n";
			my $projectID = $OME->NewProject ($cgi->param('newProject'));
			if (defined $projectID and $projectID) {
				if ($OME->AddProjectDatasets ($projectID, DatasetIDs=>$datasetIDs) ) {
					$message = "Selected datasets added to new project '".$cgi->param('newProject')."'.";
				} else {
					$OME->Rollback(); # Don't want to add the new project if an error occured while adding datasets to it.
					$message = $OME->errorMessage;
				}
			} else {
				$message = $OME->errorMessage;
			}
		} elsif ($radioSelect eq 'replaceProj') {
			print STDERR "DirTreeSelect:  process_form: replaceProj\n";
			my $projectID = $OME->GetProjectID(ProjectName=>$cgi->param('replaceProject'));
			if (defined $projectID and $projectID) {
				$OME->ClearProjectDatasets ($projectID);
				if ($OME->AddProjectDatasets ($projectID, DatasetIDs=>$datasetIDs) ) {
					$message = "Datasets in project '".$cgi->param('replaceProject')."' replaced with selected datasets."
				} else {
					$message = $OME->errorMessage;
				}
			} else {
				$message = $OME->errorMessage;
			}
		}
		
	} # If doing stuff with projects.


	if ($cgi->param('DoSelection') eq 'on') {
		print STDERR "DirTreeSelect:  process_form: DoSelection\n";
		my $radioSelect = $cgi->param('DoSelectionType');
		if ($radioSelect eq 'ReplaceSelection') {
			print STDERR "DirTreeSelect:  process_form: DoSelection:  ReplaceSelection\n";
			$OME->SetSelectedDatasets ($datasetIDs);
		} elsif ($radioSelect eq 'AddToSelection') {
			print STDERR "DirTreeSelect:  process_form: DoSelection:  AddToSelection\n";
			push (@$datasetIDs,@{$OME->GetSelectedDatasetIDs()});
			$OME->SetSelectedDatasets ($datasetIDs);
		}
	}

	return $message;
}







sub ImportSelections {
my $selections = shift;
my %selectedFiles;
my @datasetIDs;
my $maxReport=50;
my $reportEvery;
my $reportNum;
my $numSelections;
#remove OME when fixing this function
my $OME;

# We're going to use the UNIX system's find instead of Perl's File::Find
# I didn't like the consistency of how it reported paths.  Sometimes there were multiple
# path separators, and I didn't feel like parsing the paths before comparing them.
# The point here is that we want to recursively proceess all  selected directories, and any selected files.
# After doing that, we don't want any duplicates because sub-directories (or files) were selected within selected
# parent directories.
#	print STDERR "DirTreeSelect:  Opening pipe: find -X @$selections -type f 2>/dev/null | \n";
	open (FIND_PIPE,"find @$selections -type f 2>/dev/null |");	
	while (<FIND_PIPE>) {
		chomp;
		$selectedFiles{$_} = undef;
	}
	close FIND_PIPE;

# Don't really need to resort the list, but we'll spend some CPU cycles doing it anyway.
	@$selections = sort {uc($a) cmp uc($b)} keys %selectedFiles;

	if ($selections->[0]) {
		print qq {
			<script language="JavaScript">
				<!--
					importStatWin = window.open("","ImportStatus","scrollbars=1,height=100,width=500");
					importStatWin.document.URL = "";
				//-->
			</script>
			};

		$reportEvery = 1;
		$reportNum = 0;
		$numSelections = scalar (@$selections);
		$reportEvery = $numSelections / $maxReport;
		$reportEvery = 1 unless $reportEvery > 1;
	}
	$OME->TrackProgress (scalar @$selections);
	$OME->UpdateProgress (ProgramName => 'Dataset Import');
	my $datasetName;
	foreach (@$selections) {
		$datasetName = $_;
#		print STDERR "DirTreeSelect:  Importing $datasetName\n";
		my $dataset = eval {$OME->ImportDataset (Name => $datasetName);};
		if (defined $dataset) {
			push (@datasetIDs,$dataset->{ID});
			$OME->IncrementProgress();
#			if ($reportEvery eq 1) {
#				ReportDocStatus ($dataset->{Path}.$dataset->{Name}.":  Imported as type:  <B>".$dataset->{Type}."</B><BR>");
#			} elsif (scalar (@datasetIDs) % $reportEvery eq 0) {
#				ReportDocStatus ("<B>".scalar @datasetIDs."</B> of <B>".$numSelections."</B> Datasets imported.<BR>");
#				$OME->Commit();			
#			}
		} elsif ($@) {
			$OME->UpdateProgress (Error => $@);
			ReportDocStatus ('<B><font color=\"#FF0000\">Error!</font></B>'."  '$datasetName' is corrupt!<BR>");
		} else {
			ReportDocStatus ("'$datasetName':  <B>Ignored</B> - file type not supprted.<BR>");
		}
	}
	ReportDocStatus ("Total: <B>".scalar @datasetIDs."</B> Datasets imported.<BR>");
	$OME->StopProgress();
	return \@datasetIDs;
}

1;
