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
		my @group=$cgi->param('List');
		$body.=remove_dataset($revArgs{Remove},\@group,$session);   
		$body .=$self->retrieve_result();
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";

	}elsif (exists $revArgs{Delete}){
	   my $deletedataset=$session->Factory()->loadObject("OME::Dataset",$revArgs{Delete})
         or die "Unable to load dataset ( ID = ".$revArgs{Delete}." ). Action cancelled<br>";
         
	   $body.=delete_process($deletedataset,$session);
	   $body .= $self->retrieve_result();
	   $body .= "<script>top.title.location.href = top.title.location.href;</script>";

	}elsif(exists $revArgs{Lock}){
		lock_unlock_dataset($revArgs{Lock},"t");
		$body.=$self->retrieve_result();

      }elsif(exists $revArgs{Unlock}){
		lock_unlock_dataset($revArgs{Unlock},"f");
		$body.=$self->retrieve_result();

	
	}else{
	  $body.=$self->retrieve_result();
      }
	return ('HTML',$body);
}


#------------------
#PRIVATE METHODS
#------------------

sub remove_dataset{
  my ($removedataset,$ref,$session)=@_;
  my $table="project_dataset_map";
  my $project=$session->project();
  my $dataset=$session->dataset();
  my $text="";
  return "<b>Please select at least one project</b>" if scalar(@$ref)==0;
		
  my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword())  
   or die "Unable to connect <br>";
		
  my @control=();
  foreach (@$ref){
     my ($condition,$result);
     $condition="dataset_id=".$removedataset." AND project_id=".$_;
     $result=do_request($table,$condition,$db);
     return "Cannot delete one entry in project_dataset_map." if (!defined $result);
     if ($project->project_id()==$_ and $dataset->dataset_id()==$removedataset){
	 # current project
	 my @datasetused=$project->datasets();
	 if (scalar(@datasetused)==0){
	   $session->dissociateObject('dataset');
	   $session->writeObject();
	   $text .="No dataset defined for your current project.Please define a dataset."; #if not refresh
	 }else{
	   $session->dataset($datasetused[0]);
	   $session->writeObject();
	 }
     }
   }
   $db->Off();
   return $text;

}




sub lock_unlock_dataset{
 my ($id,$bool)=@_;
 my ($table,$condition,$result);
 my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword())  
   or die "Unable to connect <br>";

 $table="datasets";
 $condition="dataset_id=".$id;
 my %h=(locked =>"'".$bool."'");
 $result=do_lock_unlock($table,\%h,$condition,$db);
 $db->Off();
 return $result;
}


sub delete_process{

 my ($dataset,$session)=@_;
 my $text="";
 
 my $currentdataset=$session->dataset();
 my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword())  
   or die "Unable to connect <br>";
# must find other solution!!
 my @tables=qw(project_dataset_map image_dataset_map);

 my $rep;
 $rep=delete_dataset_in_map(\@tables,$dataset,$db);
 return "Cannot delete entry in _dataset_map." if (!defined $rep);
 
 
 if ($dataset->dataset_id()==$currentdataset->dataset_id()){
   my $currentproject=$session->project();
   my @myDatasets=$currentproject->datasets();
   my @new=();
   foreach (@myDatasets){
     push (@new,$_) unless $_->dataset_id()==$currentdataset->dataset_id();
   }
   if (scalar(@new)==0){
	$session->dissociateObject('dataset');
   }else{
	$session->dataset($new[0]);
   }
   $session->writeObject(); 
 }
 $text.=delete_dataset($dataset,$db);
 
 return $text;

}

sub delete_dataset{
 my ($deletedataset,$db)=@_;
 my $text="";
 my $tableDataset="datasets";
 my ($condition,$result);
 $condition="dataset_id=".$deletedataset->dataset_id();
 $result=do_request($tableDataset,$condition,$db);
 if (defined $result){
     $text.="The dataset <b>".$deletedataset->name()."</b> has been successfully deleted.";
 }else{
     $text.="Cannot delete the dataset <b>".$deletedataset->name()."</b>";
 }
  return $text;
}


sub delete_dataset_in_map{
  my ($table,$dataset,$db)=@_;
  foreach (@$table){
     my ($condition,$result);
     $condition="dataset_id=".$dataset->dataset_id();
     $result=do_request($_,$condition,$db);
     return undef if (!defined $result);
  } 
  return 1;
}




sub retrieve_result{
  my $self=shift;
  my $text="";
  my $cgi=$self->CGI();
  my $session=$self->Session();
  my $ownerid=$session->User()->experimenter_id;
  my @userProjects = OME::Project->search( owner_id => $ownerid );
  return "You must define a project first." unless scalar(@userProjects)>0;
  my @groupProjects=OME::Project->search( group_id => $session->User()->group()->group_id());

  my $rep=not_owned_project(\@groupProjects,\@userProjects);
  my %gpDatasetList=();
  if (defined $rep){
   foreach (@$rep){
     my @datasets=$_->datasets();
     foreach my $obj (@datasets){
	 $gpDatasetList{$obj->dataset_id()}=$obj->name() unless (exists $gpDatasetList{$obj->dataset_id()});
     }
   }
 }

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
         my $bool=undef;
         if (exists ($gpDatasetList{$datasetid})){
		$bool=1;
	   }
	   my $summary=format_dataset($data,scalar(@Image),$ownerid,$cgi,$bool);
	   $DatasetList{$datasetid}->{text}=$summary;
	   $DatasetList{$datasetid}->{List}=\%ProjectInfo;
	   $DatasetList{$datasetid}->{bool}=$bool;

	}
    }
  }

 $text.=format_output(\%DatasetList,$cgi);
 return $text;



}

sub not_owned_project{
 # find others projects 
 my ($refa,$refb)=@_;
 my %in_b=();
 my @only_a=();
 foreach (@$refb){
   $in_b{$_->project_id()}=1;
 }
 foreach (@$refa){
   push(@only_a,$_) unless exists $in_b{$_->project_id()};

 }
 return scalar(@only_a)==0?undef:\@only_a;
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
  my ($dataset,$num,$userID,$cgi,$bool)=@_;
  my $summary="";
  my ($lock,$unlock)=undef;

  # change status iff own dataset
  if ($userID==$dataset->owner()->ID){
      $unlock.=$cgi->submit (-name=>$dataset->dataset_id(),-value=>'Unlock');
      $lock.=$cgi->submit (-name=>$dataset->dataset_id(),-value=>'Lock');
   
  }
  $summary .= "<NOBR><B>Name:</B> ".$dataset->name()."</NOBR><BR>" ;
  $summary .= "<NOBR><B>ID:</B> ".$dataset->dataset_id()."</NOBR><BR>" ;
  $summary .= "<B>Description:</B> ".$dataset->description()."<BR>" ;
  if (defined $lock){
    $summary .= "<NOBR><B>Locked:</B> ".($dataset->locked()?$lock:$unlock)."</NOBR><br>";
  }else{
    $summary .= "<NOBR><B>Locked:</B> ".($dataset->locked()?'YES':'NO')."</NOBR><br>";
  }

  $summary .= "<NOBR><B>Owner:</B> ".$dataset->owner()->firstname()." ".$dataset->owner()->lastname()."</NOBR><BR>";
  $summary .="<NOBR><B>E-mail:</B><a href='mailto:".$dataset->owner()->email()."'>".$dataset->owner()->email()."</a></NOBR><BR>";
  $summary .="<NOBR><B>Nb Images in dataset:</B> ".$num."</NOBR><BR>";
  $summary.="<br>";
  my $viewer=create_button($dataset->dataset_id());
  my ($removebutton,$deletebutton);
  $removebutton=$cgi->submit (-name=>$dataset->dataset_id(),-value=>'Remove');
  $deletebutton=$cgi->submit (-name=>$dataset->dataset_id(),-value=>'Delete')
    if ($userID==$dataset->owner()->ID and !defined $bool);
 
  $summary.=$cgi->table( { -border=>1 },
			  $cgi->Tr( { -valign=>'middle' },
				$cgi->td({ -align=>'left' },$cgi->submit (-name=>$dataset->dataset_id(),-value=>'Select')),
				$cgi->td({ -align=>'left' },$removebutton),
				$cgi->td({ -align=>'left' },$deletebutton),
				$cgi->td({ -align=>'left' },$viewer),
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
  $text.=format_popup();
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
  %h=%$ref;
  my @list=();
 # Cannot Use cgi->checkbox
  foreach (keys %h){
	my $val;
        $val="<input type=\"checkbox\" name=\"List\" value=\"$_\"/>".$h{$_};
      
	push(@list,$val);
  }
   $text.=join("<br>",@list);
  return $text;
}

sub format_popup{
  my ($text)=@_;
 $text.=<<ENDJS;
<script language="JavaScript">
<!--
var ID;
function OpenPopUp(id) {
      ID=id;
	var OMEfile;
	var DatasetViewer;
	OMEfile='/perl2/serve.pl?Page=OME::Web::GetGraphics&DatasetID='+ID;
	DatasetViewer=window.open(
		OMEfile,
		"ImageViewer",
		"toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500");
	DatasetViewer.focus();
      return false;
}
-->
</script>
ENDJS

return $text;
}


sub create_button{
 my ($id)=@_;
 my $text="";
 $text.=<<END;
	<input type=button
	onclick="return OpenPopUp($id)"
	value="View"
	name="submit">
END
 return $text;
}




sub do_request{
 my ($table,$condition,$db)=@_;
 my $result;
 if (defined $db){
       $result=$db->DeleteRecord($table,$condition);
 
 }
 return $result;

}

sub do_lock_unlock{
  my ($table,$ref,$condition,$db)=@_;
  my $result=undef;
 if (defined $db){
       $result=$db->UpdateRecord($table,$ref,$condition);
 
 }
 return $result;


}


1;
