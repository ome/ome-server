# OME/Web/DatasetManager.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Jean-Marie Burel <j.burel@dundee.ac.uk>
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



package OME::Web::DatasetManager;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::SetDB;
use base qw{ OME::Web };
sub getPageTitle {
	return "Open Microscopy Environment - Dataset Manager";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();
      my $dataset=$session->dataset();
	my $project=$session->project();
	my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;

	if (exists $revArgs{Select}){
	    my $newdataset= $session->Factory()->loadObject("OME::Dataset", $revArgs{Select})
		or die "Unable to load dataset (id: ".$revArgs{Select}.")\n";

	   $session->dataset($newdataset);
	   $session->writeObject();
	   $body.=format_currentdataset($session->dataset(),$cgi);
	   $body .= "<script>top.title.location.href = top.title.location.href;</script>";

	}elsif (exists $revArgs{Remove}){
		my $deletedataset=$revArgs{Remove};
            my @groupProjects=$cgi->param('List');
		my $table="project_dataset_map";
            return ('HTML',"<b>Please select at least one project</b>") if scalar(@groupProjects)==0;
		
		my @control=();
		foreach (@groupProjects){
		   my ($condition,$result);
    		   $condition="dataset_id=".$deletedataset." AND project_id=".$_;
               $result=do_request($table,$condition);
               
		   return ('HTML',"Cannot at least delete one entry.") if (!defined $result);

               if ($project->project_id()==$_ and $dataset->dataset_id()==$deletedataset){

			my @datasetused=$project->datasets();
			if (scalar(@datasetused)==0){
			  $session->dissociateObject('dataset');
		 	  $session->writeObject();
			  $body .="No dataset defined for your current project.Please define a dataset."; #if not refresh
			  $body .= OME::Web::Validation->ReloadHomeScript();

	            }else{
			  $session->dataset($datasetused[0]);
			  $session->writeObject();
		        $body .=$self->retrieve_result();

			}
			  #$body .= OME::Web::Validation->ReloadHomeScript();
		        # javascript to reload titlebar
		        $body .= "<script>top.title.location.href = top.title.location.href;</script>";


		   }
		}#
		  
				
	}else{
	  $body.=$self->retrieve_result();
      }
	return ('HTML',$body);
}


#------------------
#PRIVATE METHODS
#------------------

sub retrieve_result{
  my $self=shift;
  my $cgi=$self->CGI();
  my $session=$self->Session();
  my $ownerid=$session->User()->experimenter_id;
  my @userProjects = OME::Project->search( owner_id => $ownerid );
  return "You must define a project first." unless scalar(@userProjects)>0;
  
  my $text="";
  my %DatasetList=();
  foreach my $project (@userProjects){
    my %ProjectInfo=();
    $ProjectInfo{$project->project_id()}=$project->name();
    my @datasetsused=$project->datasets();
    foreach my $data (@datasetsused){
	my $datasetid=$data->dataset_id();
	# num images in datasets
	my @Image=$data->images();
	if (exists($DatasetList{$datasetid})){
	  my $href= $DatasetList{$datasetid}->{List};
        my %fusion=();
	  %fusion=(%$href,%ProjectInfo);
	  $DatasetList{$datasetid}->{List}=\%fusion;
	}else{
	   my $summary=format_dataset($data,scalar(@Image),$cgi);
	   $DatasetList{$datasetid}->{text}=$summary;
	   $DatasetList{$datasetid}->{List}=\%ProjectInfo;

	}
    }
  }

 $text.=format_output(\%DatasetList,$cgi);
 return $text;



}









sub format_currentdataset{
 my ($dset,$cgi)=@_;
 my $summary="";
 $summary .= $cgi->h3('Your current dataset is:') ;
 $summary .= "<P><NOBR><B>Name:</B> ".$dset->name()."</NOBR><BR>" ;
 $summary .= "<NOBR><B>ID:</B> ".$dset->dataset_id()."</NOBR><BR>" ;
 $summary .= "<B>Description:</B> ".$dset->description()."<BR>" ;
 $summary .= "<NOBR><B>Locked:</B> ".($dset->locked()?'YES':'NO')."</NOBR><BR>";
 $summary .="<NOBR><B>Nb Images in dataset:</B> ".scalar($dset->images())."</NOBR></P>" ;

 return $summary ;

}



sub format_dataset {
  my ($dataset,$num,$cgi)=@_;
  my $summary="";
  $summary .= "<NOBR><B>Name:</B> ".$dataset->name()."</NOBR><BR>" ;
  $summary .= "<NOBR><B>ID:</B> ".$dataset->dataset_id()."</NOBR><BR>" ;
  $summary .= "<B>Description:</B> ".$dataset->description()."<BR>" ;
  $summary .= "<NOBR><B>Locked:</B> ".($dataset->locked()?'YES':'NO')."</NOBR><br>";
  $summary .= "<NOBR><B>Owner:</B> ".$dataset->owner()->firstname()." ".$dataset->owner()->lastname()."</NOBR><BR>";
  $summary .="<NOBR><B>E-mail:</B><a href='mailto:".$dataset->owner()->email()."'>".$dataset->owner()->email()."</a></NOBR><BR>";
  $summary .="<NOBR><B>Nb Images in dataset:</B> ".$num."</NOBR><BR>";
  $summary.="<br>";
  $summary.=$cgi->table( { -border=>1 },
			  $cgi->Tr( { -valign=>'middle' },
				$cgi->td({ -align=>'left' },$cgi->submit (-name=>$dataset->dataset_id(),-value=>'Select')),
				$cgi->td({ -align=>'left' },$cgi->submit (-name=>$dataset->dataset_id(),-value=>'Remove')),
			  )
			     );
  return $summary;

}


sub format_output {
  my ($ref,$cgi)=@_;
  my %h=();
  %h=%$ref;
  my $rows="";
  my $text="";
  #creation de la check_box
  foreach (keys %h){
	my $checkbox="";
	$checkbox.=format_checkbox($h{$_}->{List},$cgi);
   	$rows.=$cgi->Tr( { -valign=>'middle' },
			$cgi->td({ -align=>'left' },$h{$_}->{text}),
			$cgi->td({ -align=>'left' },$checkbox),
	);


  }
  #$text.="<b>Delete button not activated</b><br>";
  $text.=$cgi->h3("List of dataset(s) used:");
  $text.=$cgi->startform;
  $text.=$cgi->table( { -border=>1 },
				$cgi->Tr( { -valign=>'middle' },
				$cgi->td({ -align=>'left' },'<B>Datasets</B>'), 
				$cgi->td({ -align=>'left' },'<B>Projects related</B>'),
			  ),
			 $rows) ;

  $text.=$cgi->endform;
  
  return $text;
}



sub format_checkbox{
  my ($ref,$cgi)=@_;
  my $text="";
  my %h=();
  my @names=();
  %h=%$ref;
  foreach (keys %h){
   	push(@names,$_);
  }
  $text.=$cgi->checkbox_group(-name=>'List',
				     -values=>\@names,
				     -linebreak=>'true',
				     -labels=>\%h);
 return $text;
}



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
