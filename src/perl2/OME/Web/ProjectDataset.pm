# OME/Web/ProjectDataset.pm

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


=pod

=head1 Package OME::Web::ProjectDataset

Description: Generate HTML to describe & control datasets belonging to
the project specified in session.

=cut

package OME::Web::ProjectDataset;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Web::Validation;
use OME::Dataset;
use OME::SetDB;
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
	# This is not meant to take the place of OME::Web::Validation->isRedirectNecessary
	# It is explicit variable validity verification. Validation may eventually have other checks as well. This only needs these checks.
	if( not defined $project ) {
		$body .= OME::Web::Validation->ReloadHomeScript();
		return ("HTML",$body);
	}

	# cgi parameters to remove & switch datasets show up as ID=Remove and ID=Select
	# I need to reverse name, value pairs in the cgi hash to see if Remove or Select is in there
	my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;

	# FIXME: Some validation is needed for these.
	# Àdo we need to remove a dataset?
	if( exists $revArgs{Remove} ) {
		my $dataset = $session->Factory()->loadObject("OME::Dataset",$revArgs{Remove});
		if( not defined $dataset ) {
			die "Could not load dataset ( ID = '".$revArgs{Remove}."' ). It has not been removed.<br>";
		}else {
			my $result=remove_dataset($revArgs{Remove},$project->project_id());
			return ('HTML',"Cannot remove dataset.") if (!defined $result);
			my @datasets=$project->datasets();	
			if ($dataset->dataset_id()==$currentdataset->dataset_id()){
			   if (scalar(@datasets)==0){
				 $session->dissociateObject('dataset');
		 	  	 $session->writeObject();
			  	 $body .="No dataset defined for your current project.Please define a dataset."; #if not refresh
			 	 $body .= "<script>top.location.href = top.location.href;</script>";
				 $body .= "<script>top.title.location.href = top.title.location.href;</script>";

				#$body .= OME::Web::Validation->ReloadHomeScript();
			   }else{
				$session->dataset($datasets[0]);
			      $session->writeObject();
		         }
			    $body .= "<script>top.title.location.href = top.title.location.href;</script>";
			}
			$body.=$self->print_form();
		
		}
		
	}
	# Àdo we need to switch to another dataset?
	elsif ( exists $revArgs{Select} ) {
	#if( exists $revArgs{Select} ) {
		my $dataset = $session->Factory()->loadObject("OME::Dataset",$revArgs{Select})
			or die "Unable to load dataset ( ID = ".$revArgs{Select}." ). Action cancelled<br>";
		if( $project->doesDatasetBelong( $dataset ) ) {
			if ($dataset->dataset_id()==$currentdataset->dataset_id()){
			   $body.="Your current dataset is already: <b>".$currentdataset->name()."</b><br>";
			   $body.=$self->print_form();
			}else{
			  $session->dataset($dataset);
			  $session->writeObject();
	
			  # this will add a script to reload OME::Home if it's necessary
			  $body .= OME::Web::Validation->ReloadHomeScript();
			  $body .= "Operation successful. Current dataset is: <b>".$session->dataset()->name()."</b><br>";
			  # update titlebar
			  $body .= "<script>top.title.location.href = top.title.location.href;</script>";
			}

		} else {
			die "Dataset '".$dataset->name."' does not belong to the current project.<br>";
		}
	}
	# Àdo we need to add a dataset to the project?
      elsif( defined $cgi->param('addDataset') ) {

	#if( defined $cgi->param('addDataset') ) {
		my $currentdataset=$session->dataset();
		my $reload=undef;
		$reload=1 if (defined $currentdataset);
		my $dataset = $project->addDatasetID( $cgi->param('addDatasetID') )
			or die ref $self." died when trying to add dataset (".$cgi->param('addDatasetID');
		$session->dataset($dataset);
		$session->writeObject();
		$project->writeObject();
		
		$body .= "Dataset '".$dataset->name()."' successfully added to this project and set to current dataset.<br>";
		
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
            if (defined $reload){
	         $body .= OME::Web::Validation->ReloadHomeScript();
	      }else{
		  $body .= "<script>top.location.href = top.location.href;</script>";
		}
		$body .= $self->print_form();

		# update titlebar
		

	}else{

	# display datasets that user owns 
	$body .= $self->print_form();
	}
    return ('HTML',$body);
}


#---------------
# PRIVATE METHODS
#---------------

sub print_form {
	my $self = shift;
	my $session = $self->Session();
	my $project = $session->project();
	my @projectDatasets = $project->datasets();
	my $user    = $session->User()
		or die ref ($self)."->print_form() say: There is no user defined for this session.";
	my @groupDatasets = $session->Factory()->findObjects("OME::Dataset", 'group_id' =>  $user->Group()->id() ) ; #OME::Dataset->search( group_id => $user->group()->id() );
	my %datasetList;
	my %Listgeneral=();
	# remove empty datasets 
	my @notEmptyDatasets=();
  	foreach (@groupDatasets){
		my @images=$_->images();
     		 if (scalar(@images)>0){
		  push(@notEmptyDatasets,$_);
		}
  	}


	
	foreach (@notEmptyDatasets) {
	print STDERR "\n".$project->doesDatasetBelong($_)." ".$_->ID();
		$Listgeneral{$_->ID()}=$_->name();
		if (not $project->doesDatasetBelong($_)) {
			$datasetList{$_->ID()} = $_->name();
		}
	}

	my $cgi = $self->CGI();
	my $text = '';
	my ($tableRows);
	if (scalar @projectDatasets >0){
		$text .=format_own_Dataset($cgi,$project->name(),\@projectDatasets,\%datasetList);
     }else{
		$text .=format_Datasets($cgi,$project->name(),\%Listgeneral);

     }
		
	

}

#----------

sub remove_dataset{
  my ($datasetID,$projectID)=@_;
  my ($condition,$result,$table);
  $table="project_dataset_map";
  $condition="dataset_id=".$datasetID." AND project_id=".$projectID;
  $result=do_request($table,$condition);
  return $result;


}




#---------

sub format_own_Dataset{
	my ($cgi,$name,$refarray,$refhash)=@_;
	my $text="";
	my $tableRows="";
	my @control=();
	foreach (keys %$refhash){
	  push(@control,$_);
	}
	$text .= "The current Project <b>".$name."</b> contains these datasets.<br><br>";
	foreach (@$refarray) {
		  $tableRows .= 
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					$_->name() ),
				$cgi->td( { -align=>'LEFT' },
					( $_->locked() == 0 ? 'Unlocked' : 'Locked' ) ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->submit( { -name  => $_->dataset_id() ,
					                -value => 'Remove' } ) ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->submit( { -name  => $_->dataset_id() ,
					                -value => 'Select' } ) ) );
		}
	$text .= $cgi->startform;
	$text .= $cgi->table( { -border=>1 },
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'CENTER' },
					'<b>Name</b>' ),
				$cgi->td( { -align=>'CENTER' },
					'<b>Locked/Unlocked</b>' ),
				$cgi->td( { -align=>'CENTER' },
					'<b>Remove from current project</b>' ),
				$cgi->td( { -align=>'CENTER' },
					'<b>Make this the current dataset</b>' ) ),
			$tableRows );
	if (scalar(@control)>0){
	 $text.=$cgi->h3("If you want to add an existing dataset to the current project,
			Please choose one in the list below.");
	 $text .= $cgi->table(
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					$cgi->popup_menu (
						-name => 'addDatasetID',
						-values => [keys %$refhash],
						-labels => $refhash)
					  ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->submit (-name=>'addDataset',-value=>'add Dataset to this project') ) ),
		);


      }
	$text .= $cgi->endform;
	$text .= '<br>What else would you like to do with these? Think about it. <a href="mailto:igg@nih.gov,bshughes@mit.edu,dcreager@mit.edu,siah@nih.gov,a_falconi_jobs@hotmail.com">email</a> the developers.';
	
	return $text;

}
#-------


sub format_Datasets{
  my ($cgi,$name,$ref)=@_;
  my $text="";
  $text.="The current project <b>".$name."</b> doesn't contain a dataset. <br><br>";
  $text.="Please choose an existing dataset in the list below.";
  $text .= $cgi->startform;
  $text .= $cgi->table(
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					$cgi->popup_menu (
						-name => 'addDatasetID',
						-values => [keys %$ref],
						-labels => $ref)
					  ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->submit (-name=>'addDataset',-value=>'add Dataset to this project') ) ),
		);
			
	$text .= $cgi->endform;
 	return $text;


}

#----------------
sub do_request{
 my ($table,$condition)=@_;
 my $result;
 my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword());  
 if (defined $db){
       $result=$db->DeleteRecord($table,$condition);
 
 }
 return $result;

}



1;
