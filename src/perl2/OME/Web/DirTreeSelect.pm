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
use base qw{ OME::Web };

use OME::Tasks::ImageTasks;

sub getPageTitle {
	return "Open Microscopy Environment - Select Images";
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
			my ($reloadTitleBar, $reloadPage);
			
			# If there is no dataset defined, then whole page will need 
			# to be reloaded so Web::Home will display menubar
			$reloadPage = 1
				if( not defined $session->dataset);
			# radios are not drawn on the form if there are no datasets
			# in the project. In this case, 'addNewDataset' is implicitly chosen
			if (not defined $radioSelect or $radioSelect eq 'addNewDataset') {
				$reloadTitleBar = 1;
				$dataset = $project->newDataset($cgi->param('newDataset'), $cgi->param('description') );
				die ref($self)."->import:  Could not create dataset '".$cgi->param('newDataset')."'\n" unless defined $dataset;
				$session->dataset($dataset);
			} elsif ($radioSelect eq 'addExistDataset') {
				$dataset = $project->addDatasetID ($cgi->param('addDataset'));
				die ref($self)."->import:  Could not load dataset '".$cgi->param('addDataset')."'\n" unless defined $dataset;
			}

			my $errorMessage = '';
			if ($dataset) {
				$dataset->writeObject();
			    $errorMessage = OME::Tasks::ImageTasks::importFiles($self->Session(), $dataset, \@paths);
				die $errorMessage if $errorMessage;
				$dataset->writeObject();
				$project->writeObject();
				$session->dataset($dataset);
				$session->writeObject();
			} else {
				$errorMessage = "No Dataset to import into.\n";
			}
			# Import messed up. Display error message & let them try again.
			if ($errorMessage) {
				$body .= $cgi->h3($errorMessage);
				$body .= $self->print_form($selections[0]);
				$body .= $cgi->h4 ('Selected Files and Folders:');
				$body .= join ("<BR>",@selections);
			} else {
			# import successful. Reload titlebar & display success message.
				# javascript to reload titlebar
				$body .= "<script>top.title.location.href = top.title.location.href;</script>"
					if defined $reloadTitleBar;
				# javascript to reload titlebar
				$body .= "<script>top.location.href = top.location.href;</script>"
					if defined $reloadPage;
				$body .= q`Import successful. This should display more info. But that's not implemented. What would you like to see? <a href="mailto:igg@nih.gov,bshughes@mit.edu,dcreager@mit.edu,siah@nih.gov,a_falconi_jobs@hotmail.com">email</a> the developers w/ your comments.`;
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
	$defaultDatasetID = $self->Session()->dataset()->ID() unless not defined $self->Session()->dataset() or $defaultDatasetID;
	
	$text .= "<BLOCKQUOTE>\n";
	my @datasetRadios = $cgi->radio_group(-name=>'DoDatasetType',
				-values => ['addNewDataset','addExistDataset'],
				-default=>$defaultRadio,
				-labels => {
					'addNewDataset'   => 'New dataset named: ',
					'addExistDataset' => 'Add imported images to existing dataset ',
				}
			);

	$text .= 
		$cgi->table(
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'RIGHT' },
					'<NOBR>'.(@datasets > 0 ? $datasetRadios[0] : 'New dataset named: ').'</NOBR>' ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->textfield(-name=>'newDataset', -size=>32,-default=>$newDatasetName)) ),
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'RIGHT' },
					'Description:' ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->textarea(-name=>'description', -columns=>32, -rows=>3) ) ) );
	
	$text .= '	'.$datasetRadios[1]."\n	".$cgi->popup_menu(-name=>'addDataset',-values=>\%datasetHash,-default=>$defaultDatasetID)."<BR>\n"
		if @datasets > 0;

	$text .= "</BLOCKQUOTE>\n";

	$text .= $cgi->endform."\n";
	return $text;
}

1;
