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
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::DBObject;
use OME::Dataset;		
use OME::Tasks::ImageTasks;
use OME::Tasks::DatasetManager;
use OME::Tasks::ProjectManager;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Helper::JScriptFormat;
use base qw{ OME::Web };


sub getPageTitle {
	return "Open Microscopy Environment - Select Images";
}

sub getPageBody {
	my $self = shift;
	my $rootName = "Home";
	my $cgi = $self->CGI();
	my $session=$self->Session();
	my $rootDir=$self->User()->DataDirectory();

	my $datasetManager=new OME::Tasks::DatasetManager($session);
	my $projectManager=new OME::Tasks::ProjectManager($session);
	my $htmlFormat=new OME::Web::Helper::HTMLFormat;
	my $jscriptFormat=new OME::Web::Helper::JScriptFormat;

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
			my $project = $session->project();
			my $radioSelect = $cgi->param('DoDatasetType');
			my ($reloadTitleBar, $reloadPage);
			
			# If there is no dataset defined, then whole page will need 
			# to be reloaded so Web::Home will display menubar
			$reloadPage = 1	if( not defined $session->dataset);
			# radios are not drawn on the form if there are no datasets
			# in the project. In this case, 'addNewDataset' is implicitly chosen
			if (not defined $radioSelect or $radioSelect eq 'addNewDataset') {
				$reloadTitleBar = 1;
				# No name
				my $datasetname=$cgi->param('newDataset');
				my $text="";
				$text=$htmlFormat->noNameMessage("dataset");
				$text.=print_form($session,$cgi,$htmlFormat,\@selections);
				return ('HTML',$text) unless $datasetname;
         			
        			#name already exists
				my $rep=$datasetManager->exist($datasetname);

				my $txt="";
				$txt=$htmlFormat->existMessage("dataset");
				$txt.=print_form($session,$cgi,$htmlFormat,\@selections);
	   			return ('HTML',$txt) unless (defined $rep);
				# must find better solution
				$datasetManager->create($cgi->param('newDataset'),$cgi->param('description'));

			} elsif ($radioSelect eq 'addExistDataset') {
				# is this the Right Way to do this operation?
				$projectManager->add($cgi->param('addDataset'));
								
			}

			my $errorMessage = '';
			if ($session->dataset()) {
			    $errorMessage = OME::Tasks::ImageTasks::importFiles($self->Session(), $session->dataset(), \@paths);
				
			} else {
				$errorMessage = "No Dataset to import into.\n";
			}
			# Import messed up. Display error message & let them try again.
			if ($errorMessage) { 
				#Delete $dataset 
				# +link. MUST BE DONE BEFORE (New class) domain logic 
				$datasetManager->delete($session->dataset()->dataset_id());
				$body .= "<b>".$errorMessage."</b><br>";
				$body .= print_form($session,$cgi,$htmlFormat,\@selections);
			} else {
				# import successful. Reload titlebar & display success message.
				# javascript to reload titlebar
				#$dataset->writeObject();
				#$project->writeObject();
				#$session->dataset($dataset);
				#$session->writeObject();
				$body=$jscriptFormat->openInfoDatasetImport($session->dataset()->dataset_id());
				$body .= "<script>top.location.href = top.location.href;</script>";
				$body .= "<script>top.title.location.href = top.title.location.href;</script>"
					if defined $reloadTitleBar;	
			}
		}
		# If we have a selection, but import button wasn't clicked, print the form:
		else {
			$body .= print_form($session,$cgi,$htmlFormat,\@selections);
		}
	
	# If we got no selection, just print a handy hint.
	} else {
		$body .=  "<h4>Select Files and Folders in the menu tree on the left.</h4>";
	}

	return ('HTML', $body);

}


sub print_form {
	my ($session,$cgi,$htmlFormat,$refSelection) = @_;

	my $recentSelection=@$refSelection[0];
	my $project = $session->project();
	my @datasets = $project->unlockedDatasets() if defined $project;
	my %datasetHash  = map { $_->ID() => $_->name()} @datasets if @datasets > 0;;
	my $text = '';
	
	# this sets default datasetName to the last directory path
	my @pathElements = split ('/',$recentSelection);
	my $datasetName = $pathElements[$#pathElements-1];
	my ($key, $value,$defaultDatasetID);
	while (($key, $value) = each %datasetHash) {
		$defaultDatasetID = $key if $value eq $datasetName;
	}
	
	my $defaultRadio =1;
	$defaultRadio = 2 if $defaultDatasetID;
	my $newDatasetName = '';
	$newDatasetName = $datasetName unless $defaultDatasetID;
	$defaultDatasetID = $session->dataset()->ID() unless not defined $session->dataset() or $defaultDatasetID;
	
	my %h=(
	1 =>{name =>'addNewDataset', text=> 'New dataset named: '},
	2 =>{name => 'addExistDataset', text => 'Add imported images to existing dataset '},
	);
	my $dropDowntable= $htmlFormat->dropDownTable("addDataset",\%datasetHash);
	my $radioButton= $htmlFormat->radioButton(\%h,$defaultRadio,"DoDatasetType");

	$text .= $cgi->startform;
	$text.=$htmlFormat->formImport($newDatasetName,$dropDowntable,$radioButton,"Import","Import Selected Files/Folders");
	$text .= $cgi->endform;

	$text .= "<h4>Selected Files and Folders:</h4>";
	$text .= join ("<BR>",@$refSelection);
	return $text;
}



1;
