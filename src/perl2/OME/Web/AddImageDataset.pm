# OME/Web/AddImageDataset.pm

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


package OME::Web::AddImageDataset;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;


use base qw(OME::Web);




sub getPageTitle {
	return "Open Microscopy Environment - Add Image/Existing Dataset" ;

}

sub getPageBody {
	my	$self = shift ;
	my 	$cgi = $self->CGI() ;
	my	$session=$self->Session();
	my 	$body="" ;
	my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;

	if ($cgi->param('Add')){

  	   my $dataset=$session->Factory()->loadObject("OME::Dataset", $cgi->param('AddDataset') )
		or die "Unable to load dataset (id: ".$cgi->param('AddDataset').")";
	   # dataset =>current dataset
         if (defined $dataset){
           $session->dataset($dataset);
           $session->writeObject();
	     my ($a,$b)=format_selected_dataset($dataset,$cgi);
	     $body.=$a;
	     if (defined $b){
		$body.=$self->format_list_images($dataset);

	     }
 	     $body .= "<script>top.title.location.href = top.title.location.href;</script>";
	   }			
	
	}elsif(exists $revArgs{Unlock}){

		lock_unlock_dataset($revArgs{Unlock},"f");
		my $dataset=$session->Factory()->loadObject("OME::Dataset",$revArgs{Unlock})
		or die "Unable to load dataset (id: ".$cgi->param('AddDataset').")";
		if (defined $dataset){
 	         $session->dataset($dataset);
               $session->writeObject();
               my ($a,$b)=format_selected_dataset($dataset,$cgi);
	   	   $body.=$a;
		   if (defined $b){
		    $body.=$self->format_list_images($dataset);
	         }
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
	   }			


	}elsif ($cgi->param('AddImage')){
		my $dataset=$session->dataset();
		my @addImages=$cgi->param('ListImage');
		return ('HTML',"<b>No image selected. Please try again </b>") unless scalar(@addImages)>0;
		foreach (@addImages){
              my $image=$dataset->addImageID($_);
		}
		$session->dataset($dataset);
		$session->writeObject();
		my $newdataset=$session->dataset();
		my ($a,$b)=format_selected_dataset($newdataset,$cgi);
	   	$body.=$a;
		if (defined $b){
		   $body.=$self->format_list_images($newdataset);
	      }
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";



      }else{
	 $body.=$self->print_status;
      }
	return ('HTML',$body);

		
}


#---------------------
# PRIVATE METHODS
#---------------------

sub print_status{
 my $self=shift;
 my $cgi=$self->CGI();
 my $text="";
 my $session=$self->Session();
 my $user=$session->User();

 #User's datasets
 my @ownDatasets=$session->Factory()->findObjects("OME::Dataset",'owner_id' => $user->id());

 #my @ownDatasets=OME::Dataset->search( owner_id => $user->id() );
 my %UserDataset=();
 my %Share=();
 my %CanAdd=();

 %UserDataset= map {$_->dataset_id() =>$_->name()} @ownDatasets;
 %CanAdd=%UserDataset;

 #Check if used by others members.
 my @groupProjects=$session->Factory()->findObjects("OME::Project",'group_id'=> $user->Group()->id());
 my @ownprojects=$session->Factory()->findObjects("OME::Project",'owner_id'=> $user->id());
 
 #my @groupProjects=OME::Project->search( group_id => $user->group()->group_id());
 #my @ownprojects=OME::Project->search(owner_id =>$user->id());
 
 my $rep=not_owned_project(\@groupProjects,\@ownprojects); 
 if (defined $rep){
   foreach (@$rep){
     my @datasets=$_->datasets();
	foreach my $d (@datasets){
        if (exists $UserDataset{$d->dataset_id()}){
		$Share{$d->dataset_id()}=$d->name();
		delete($CanAdd{$d->dataset_id()});
        }
      }
   }
 }
 # Solution for the time being!!!
 foreach (keys %CanAdd){
  if ($CanAdd{$_} eq "Dummy import dataset"){
	delete($CanAdd{$_});

  }
 }
 if (%Share){
   $text.=$cgi->h3("Datasets you own but used by others");
   $text.=format_dataset(\%Share);
 }
 if (%CanAdd){
   $text.=format_form(\%CanAdd,$cgi);
 }else{
   $text.=$cgi->h3("All your datasets are used. Cannot add new images");
 }
 return $text;
}


sub format_form{
 my ($ref,$cgi)=@_;
 my $text="";
 $text.=$cgi->h3("If you want to add images, please choose a dataset in list below");
 $text .= $cgi->startform;
 $text .= $cgi->table(
		$cgi->Tr( { -valign=>'MIDDLE' },
		$cgi->td( { -align=>'LEFT' },
			   $cgi->popup_menu (
				 -name => 'AddDataset',
				 -values => [keys %$ref],
				 -labels => $ref
				 ) ),
		 $cgi->td( { -align=>'LEFT' },
					$cgi->submit (-name=>'Add',-value=>'Dataset') ) ),
		);		
   $text .= $cgi->endform;
  return $text;
}




sub format_dataset{
 my ($ref)=@_;
 my $text="";
 $text.="<p>";
 foreach (keys %$ref){
   $text.="<NOBR><B>Name:</B> ".${$ref}{$_}."</NOBR>&nbsp;&nbsp;<b>ID:</b> ".$_."<BR>";
   
 }
 $text.="</p>";
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

#------------
#"Add" stuff

sub format_selected_dataset{
 my ($data,$cgi)=@_;
 my $summary="";
 my $button="";
 my $word;
 my $bool=undef;
 my @images=$data->images();
 $summary .= $cgi->h3('The selected dataset is:') ;
 $summary .= "<p><NOBR><B>Name:</B> ".$data->name()."</NOBR><BR>" ;
 $summary .= "<NOBR><B>ID:</B> ".$data->dataset_id()."</NOBR><BR>" ;
 $summary .= "<B>Description:</B> ".$data->description()."<BR>" ;
 $summary .= "<NOBR><B>Locked:</B> ".($data->locked()?'YES':'NO')."</NOBR><br>";                  
 $summary .= "<NOBR><B>Owner:</B> ".$data->owner()->firstname()." ".$data->owner()->lastname()."</NOBR><BR>";
 $summary.="<NOBR><B>E-mail:</B><a href='mailto:".$data->owner()->email()."'>".$data->owner()->email()."</a></NOBR><BR>";
 $summary .="<NOBR><B>Nb Images in dataset:</B> ".scalar(@images)."</NOBR><br>" ;
 if (scalar(@images)>0){
  my @list=();
  foreach (@images){
    my ($val,$button);
    $button=create_button($_->image_id());
    $val=$button."&nbsp;&nbsp;".$_->name();
    push(@list,$val);
  }
  $summary.=format_popup();
  $summary.="<b>Images' name:</b><br> ".join("<br>",@list);
 }
 if ($data->locked()){
  $summary.="</p><b>The selected dataset is locked. You cannot add images.</b>";
  #$summary.=$cgi->endform;

 }else{
   $bool=1;
 }
 return ($summary,$bool) ;


}


sub format_list_images{
 my $self=shift;
 my $cgi=$self->CGI();
 my ($dataset)=@_;
 my $text="";
 my $checkbox="";
 my $session=$self->Session();
 my $user=$self->Session()->User() 
	or die ref ($self)."->print_form() say: There is no user defined for this session.";
 my @groupImages = $session->Factory()->findObjects("OME::Image", 'group_id' =>  $user->Group()->id() ) ; #OME::Dataset->search( group_id => $user->group()->id() );
 my @datasetsImages=$dataset->images();
 my $rep=not_used_images(\@groupImages,\@datasetsImages);	
 if (scalar(@$rep)>0){
   
   $checkbox.=print_checkbox($cgi,$rep);
   #format output
   $text.=$cgi->h3("Select images in the list below");
   $text.=$cgi->startform;
   $text.=$checkbox;
   $text .= "<br><br><CENTER>".$cgi->submit (-name=>'AddImage',-value=>'Add Images')."</CENTER>";
   $text.$cgi->endform;
   
 }
 return $text;
}

sub not_used_images{
 # find others projects 
 my ($refa,$refb)=@_;
 my %in_b=();
 my @only_a=();
 foreach (@$refb){
   $in_b{$_->image_id()}=1;
 }
 foreach (@$refa){
   push(@only_a,$_) unless exists $in_b{$_->image_id()};

 }
 return scalar(@only_a)==0?undef:\@only_a;
}









sub print_checkbox{
 my ($cgi,$ref)=@_;
 my %List=();
 my %ReverseList=();
 my $text="";
 my @names=();
 # necessary because not control before import process!
 foreach (@$ref){
   $ReverseList{$_->name()}=$_->image_id();
   # push(@names,$_->name());
   
 }
 %List= reverse %ReverseList;
  
 
 my @list=();
 foreach (keys %List){
  my ($val,$button);
  $button=create_button($_);
  $val=$button."&nbsp;&nbsp;<input type=\"checkbox\" name=\"ListImage\" value=\"$_\"/>".$List{$_};
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
	var ImageViewer;
	OMEfile='/perl2/serve.pl?Page=OME::Web::GetGraphics&ImageID='+ID;
	ImageViewer=window.open(
		OMEfile,
		"ImageViewer",
		"toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500");
	ImageViewer.focus();
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

sub do_lock_unlock{
  my ($table,$ref,$condition,$db)=@_;
  my $result=undef;
 if (defined $db){
       $result=$db->UpdateRecord($table,$ref,$condition);
 
 }
 return $result;


}


1;




