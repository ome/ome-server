# OME/Web/ProjectDataset.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  J-M Burel <j.burel@dundee.ac.uk>
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


=pod

=head1 Package OME::Web::ProjectDataset

Description:
Generate HTML to describe & control datasets belonging to
the project specified in session.

=cut

package OME::Web::ProjectDataset;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Web::Validation;
use OME::Tasks::DatasetManager;
use OME::Tasks::ProjectManager;
use OME::Web::Helper::HTMLFormat;



use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Datasets in this project";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();
	my $project = $session->project();
	my $currentdataset=$session->dataset();
	my $datasetManager=new OME::Tasks::DatasetManager($session);
	my $projectManager=new OME::Tasks::ProjectManager($session);
	my $htmlFormat=new OME::Web::Helper::HTMLFormat;
	
 	

	if( not defined $project ) {
		$body .= "<script>top.location.href = top.location.href;</script>";
		return ("HTML",$body);
	}

	my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;

	
	if( exists $revArgs{Remove} ) {
		my %h=();
		my @a=($session->project()->project_id());

		$h{$revArgs{Remove}}=\@a;
		$datasetManager->remove(\%h);		 
		my @datasets=$session->project()->datasets();
		if (scalar(@datasets)==0){	  	 
  		  $body .= "<script>top.location.href = top.location.href;</script>";
		}else{
		  $body.=print_form($session,$datasetManager,$htmlFormat,$cgi);
	      }
		  $body .= "<script>top.title.location.href = top.title.location.href;</script>";		
	}
	elsif ( exists $revArgs{Select} ) {
		$datasetManager->switch($revArgs{Select});
		$body.= "Operation successful. Current dataset is: <b>".$session->dataset()->name()."</b><br>";
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		$body.=print_form($session,$datasetManager,$htmlFormat,$cgi);
	}
	# Àdo we need to add a dataset to the project?
      elsif( defined $cgi->param('addDataset') ) {

		$projectManager->add($cgi->param('addDatasetID'));
		$body .= "Dataset <b>".$session->dataset()->name()."</b> successfully added to this project and set to current dataset.<br>";
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		$body .= "<script>top.location.href = top.location.href;</script>";

          	$body .= print_form($session,$datasetManager,$htmlFormat,$cgi);

				

	}else{
	
		$body .= print_form($session,$datasetManager,$htmlFormat,$cgi);
	}
    return ('HTML',$body);
}


#---------------
# PRIVATE METHODS
#---------------

sub print_form {
	
	my ($session,$datasetManager,$htmlFormat,$cgi) = @_;
	my $ref=$datasetManager->notBelongToProject();
	my $text=formatList($cgi,$htmlFormat,$session,$ref);	
	return $text;


}



#---------

sub formatList{
	my ($cgi,$htmlFormat,$session,$refhash)=@_;
	my $text="";
	my $tableRows="";
	my @control=();
      my @datasets=$session->project()->datasets();
	my $name=$session->project()->name();

	foreach (keys %$refhash){
	  push(@control,$_);
	}
	$text .= $cgi->startform;
	if (scalar(@datasets)>0){
		$text .= "The current Project <b>".$name."</b> contains these datasets.<br><br>";
		$text.=$htmlFormat->datasetListInProject(\@datasets);
	}else{
		$text.="The current project <b>".$name."</b> doesn't contain a dataset. <br><br>";

	}
	if (scalar(@control)>0){
	
	 $text.="<h3>If you want to add an existing dataset to the current project,
			Please choose one in the list below.</h3>";
	 $text.=$htmlFormat->dropDownTable("addDatasetID",$refhash,"addDataset","add a Dataset");
	}
	$text .= $cgi->endform;
	return $text;

}

1;