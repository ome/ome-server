# OME/Web/DatasetComponents.pm

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



package OME::Web::DatasetComponents;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use base qw{ OME::Web };
sub getPageTitle {
	return "Open Microscopy Environment - Images in current Dataset";
}

sub getPageBody {
	my $self = shift;
	my $session=$self->Session();
	my $body = "";
	my $cgi=$self->CGI();

	if ($cgi->param('AddImage')){
		my $dataset=$session->dataset();
		my @addImages=$cgi->param('ListImage');
		return ('HTML',"<b>No image selected. Please try again </b>") unless scalar(@addImages)>0;
		foreach (@addImages){
              my $image=$dataset->addImageID($_);
		}
		$session->dataset($dataset);
		$session->writeObject();
		my $newdataset=$session->dataset();
		$body.=format_selected_dataset($newdataset,$cgi);
		$body.=$self->format_list_images($newdataset);
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";

      }else{	     
	$body.=$self->print_status();
	}
	return ('HTML',$body);
}





#---------------------
#PRIVATE METHODS
#---------------------
sub print_status{
 my $self=shift;
 my $cgi=$self->CGI();
 my $session = $self->Session();
 my $dataset =$session->dataset();
 my @list=$session->project()->datasets();
 my $text="";
 if (scalar(@list)==0){
  $text.="<b>No current dataset. Please define a dataset</b>";
  return $text;
 }

 my @listimages=();
 @listimages=$dataset->images();
 $text.=format_currentdataset($dataset,$cgi);
 if (scalar(@listimages)>0){
  $text.=format_popup();
  $text.=format_images(\@listimages,$cgi);
 }else{
  $text.=$cgi->h3('The current dataset contains no image.') ;
  $text.=$self->format_list_images($dataset)
	unless ($dataset->locked());
 }
 return $text;
   

}
sub format_currentdataset{
 my ($dset,$cgi)=@_;
 my $summary="";
 $summary .= $cgi->h3('Your current dataset is:') ;
 $summary .= "<P><NOBR><B>Name:</B> ".$dset->name()."</NOBR><BR>" ;
 $summary .= "<NOBR><B>ID:</B> ".$dset->dataset_id()."</NOBR><BR>" ;
 $summary .= "<B>Description:</B> ".$dset->description()."<BR>" ;
 $summary .= "<NOBR><B>Locked:</B> ".($dset->locked()?'YES':'NO')."</NOBR></P>" ;
 return $summary ;

}

sub format_images{

  my ($ref,$cgi)=@_;
  my $summary="";
  if (scalar(@$ref)==1){
     $summary .= $cgi->h3('The current dataset contains the image listed below.') ;
  }else{
    $summary .= $cgi->h3('The current dataset contains the images listed below.') ;
  }
  my $tableRows="";
  foreach (@$ref){
     my $button=create_button($_->image_id());

     $tableRows .= $cgi->Tr( {-valign=>'middle'},
					$cgi->td({-align=>'left'},$_->name()),
					$cgi->td({-align=>'left'},$_->image_id()),
					$cgi->td({-align=>'left'},$_->inserted()),
					$cgi->td( { -align=>'CENTER' },$button),

					);
  }
  $summary .="<form>";
  $summary .= $cgi->table( {-border=>1},
		  $cgi->Tr( {-valign=>'middle'},
		  	$cgi->td({-align=>'left'},'<B>Name</B>'),
		 	$cgi->td({-align=>'left'},'<B>ID</B>'),  
		 	$cgi->td({-align=>'left'},'<B>Inserted</B>'),
			$cgi->td({-align=>'left'},'<B>View</B>'),

                  ),
			$tableRows ) ;
 $summary .="</form>";

 return $summary;
}

sub format_selected_dataset{
 my ($data,$cgi)=@_;
 my $summary="";
 my $button="";
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
  return $summary ;


}





sub format_list_images{
 my $self=shift;
 my $cgi=$self->CGI();
 my ($dataset)=@_;
 my $text="";
 my $checkbox="";
 my $session=$self->Session();
 my $user=$session->User() 
	or die ref ($self)."->format_list_images() say: There is no user defined for this session.";
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
var imageid;
function OpenPopUp(id) {
      imageid=id;
	var OMEfile;
	OMEfile='/perl2/serve.pl?Page=OME::Web::GetGraphics&ImageID='+imageid;
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
	<input type="button"
	onclick="OpenPopUp($id)"
	value="View"
	name="submit">
END
 return $text;
}


1;

