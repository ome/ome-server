# OME/Web/DirTreeSelect.pm

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
# Written by:    Ilya G. Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DirTreeSelect;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::DBObject;
use OME::Dataset;		
use OME::Tasks::ImageTasks;
use OME::Tasks::DatasetManager;
use OME::Tasks::ProjectManager;
use OME::Web::Helper::HTMLFormat;
use base qw{ OME::Web };


sub getPageTitle {
	return "Open Microscopy Environment - Select Images";
}

sub getPageBody {
	my $self = shift;
	my $rootName = "Home";
	my $cgi = $self->CGI();
	my $session=$self->Session();
	my $userID=$session->User()->id();
	my $usergpID=$session->User()->Group()->id();

	my $rootDir=$self->User()->DataDirectory();

	my $datasetManager=new OME::Tasks::DatasetManager($session);
	my $projectManager=new OME::Tasks::ProjectManager($session);
	my $htmlFormat=new OME::Web::Helper::HTMLFormat;

	my @selections = ();
	my $selection;
	my @paths;
	my $body = '';
	my $existFlag=undef;
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
				my $rep=$datasetManager->nameExists($datasetname);

				my $txt="";
				$txt=$htmlFormat->existMessage("dataset");
				$txt.=print_form($session,$cgi,$htmlFormat,\@selections);


	   			return ('HTML',$txt) unless (defined $rep);
				# must find better solution
				$dataset=$datasetManager->create($cgi->param('newDataset'),$cgi->param('description'),$userID,$usergpID,$project->project_id());

			} elsif ($radioSelect eq 'addExistDataset') {
				# is this the Right Way to do this operation?
				$dataset=$datasetManager->load($cgi->param('addDataset'));
				$existFlag=1;
								
			}

			my $errorMessage = '';
			if ($dataset) {
				my $datasetManager = new OME::Tasks::DatasetManager;
			    my $images = OME::Tasks::ImageTasks::importFiles(@paths);
				my @image_ids = map($_->id(), @$images);
			   	$datasetManager->addImages( \@image_ids, $dataset->id());

				
			} else {
				$errorMessage = "No Dataset to import into.\n";
			}
			# Import messed up. Display error message & let them try again.
			if ($errorMessage) { 
				#Delete $dataset 
				# +link. MUST BE DONE BEFORE (New class) domain logic
				# must find solution next version

				$datasetManager->delete($session->dataset()->dataset_id()) unless (defined $existFlag);
				########
				$body .= "<b>".$errorMessage."</b><br>";
				$body .= print_form($session,$cgi,$htmlFormat,\@selections);

			} else {
				# import successful. Reload titlebar & display success message.
				# javascript to reload titlebar
				#$dataset->writeObject();
				#$project->writeObject();
				#$session->dataset($dataset);
				#$session->writeObject();
				
				$body .= '<script>openInfoDatasetImport(' . $session->dataset()->id() . ');</script>';
				$body .= '<script>top.location.href = top.location.href;</script>';
				$body .= '<script>top.title.location.href = top.title.location.href;</script>'
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
	# only dataset related to current project
	# maybe display list of datasets by a given user 
	# security control i.e. if dataset used by others.

	my @datasets = $project->unlockedDatasets() if defined $project;
	
	my %datasetHash  = map { $_->ID() => $_->name()} @datasets if @datasets > 0;;
	my $text = '';
	
	# this sets default datasetName to the last directory path
	my @pathElements = split ('/',$recentSelection);
	my $n=scalar(@pathElements);
	my $datasetName = $pathElements[$n-1];


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
	#2 =>{name => 'addExistDataset', text => 'Add imported images to an unlock existing dataset '},
	);
  my $dropDowntable;
  if  (@datasets >0){
   $h{2}={name => 'addExistDataset', text => 'Add imported images to an unlock existing dataset '};
	 $dropDowntable= $htmlFormat->dropDownTable("addDataset",\%datasetHash);
  }
	my $radioButton= $htmlFormat->radioButton(\%h,$defaultRadio,"DoDatasetType");

	$text .= $cgi->startform;
	$text.=$htmlFormat->formImport($newDatasetName,$dropDowntable,$radioButton,"Import","Import Selected Files/Folders");
	$text .= $cgi->endform;

	$text .= "<h4>Selected Files and Folders:</h4>";
	$text .= join ("<BR>",@$refSelection);
	return $text;
}



1;
