# OME/Web/TitleBar.pm

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

# JM 07-03-03 remove viewer in TitleBar

package OME::Web::TitleBar;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::DBObject;
use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Title Bar";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();
	my $experimenter = $self->User()
		or die "User not defined for this session";
	my $firstName   = $experimenter->firstname();
	my $lastName    = $experimenter->lastname();
	
	my $project   = $session->project();
	my $dataset;
	#my ($projectName,$datasetName) = ('*** UNDEFINED ***','*** UNDEFINED ***');
      $dataset   = $session->dataset();
	my $datasetID;
	$datasetID = $dataset->ID() if defined $dataset;
	
	my ($sentencedataset,$sentenceproject)=undef;
	if (defined $project){
 	  $sentenceproject="You are working on project:".$project->name()."<br>",
	}else{
	  $sentenceproject=" no project defined <br>";
	}
	if (defined $dataset){
 	  $sentencedataset="You are working on dataset:".$dataset->name()."<br>",
	}else{
	  $sentencedataset.="no dataset defined <br>";
	}
	# maybe add smart sizing of viewer Popupwindow by looking up dimensions of image?

	my ($left, $right);
	$left = $cgi->td(
		{ width=>"105" },
		$cgi->img( { src   => "/images/AnimalCell.aa.jpg.png",
		               width => "105",
		               height => "77",				
		               border => "0",
		               alt    => "Cell in mitosis" }));
			$right = $cgi->td(
		"Welcome $firstName $lastName<br>",
		$sentenceproject,
		$sentencedataset);
	
	$body = $cgi->table(
		{ cellspacing => 0, cellpadding => 2, border => 0, width=> '100%' },
		$cgi->Tr( 
			{ valign => 'MIDDLE', align => 'CENTER' },
			$left,
			$right ));
		
return ('HTML',$body);
}



1;
