# OME/Web/ImageManager.pm

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



package OME::Web::ImageManager;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::SetDB;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Image Manager";
}

# project owner
# datasets used
# images in datasets.

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;

	if (exists $revArgs{Remove}){
	   my @groupdatasets=$cgi->param('List');
	   $body.=remove_image(\@groupdatasets);
	}elsif(exists $revArgs{Delete}){
         $body.=delete_image_process($revArgs{Delete});
		  
	}      
	$body.=$self->print_list();  
      return ('HTML',$body);
}






#---------------------------
# PRIVATE METHODS
#---------------------------

sub delete_image_process{
 my ($image)=@_;
 my $text="";
 my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword())  
		 or die "Unable to connect <br>";

  # process MUST FIND BETTER SOLUTION
  my @tables=qw(image_dataset_map image_dimensions image_files_xyzwt image_screen_info image_stage_info image_wavelengths xy_image_info xy_softworx_info xyz_image_info features ome_sessions_images);
  my $answer=delete_image_in_all(\@tables,$image,$db);
  return "cannot delete in table_image_map" if (!defined $answer); 
  $text.=delete_image($image,$db);
  $db->Off(); 
  return $text;
}


sub delete_image_in_all{
 my ($table,$image,$db)=@_;
 foreach (@$table){
     my ($condition,$result);
     $condition="image_id=".$image;
     $result=do_request($_,$condition,$db); 
     return undef if (!defined $result);

 }
 return 1;

}
sub delete_image{
 my ($image,$db)=@_;
 my $text="";
 my $table="images";
 my ($condition,$result);
 $condition="image_id=".$image;
 $result=do_request($table,$condition,$db);
 return "cannot delete image" if (!defined $result);
 $text.="Image deleted";
 return $text;
}



sub remove_image{
  my ($refarray)=@_;
  my $table="image_dataset_map";
  my $text="";
  return "Please select at least one dataset" if scalar(@$refarray)==0;
  my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword())  
		 or die "Unable to connect <br>";

  foreach (@$refarray){
     my ($condition,$result);
     my ($imageID,$datasetID)=split("-",$_);
     $condition="image_id=".$imageID." AND dataset_id=".$datasetID;
     $result=do_request($table,$condition,$db); 
     return ('HTML',"Cannot delete one entry in image_dataset_map.") if (!defined $result);
     
  }
   $db->Off(); 
  $text.="<b>image removed<b>";
  return $text;

}


sub print_list{

  my $self = shift;
  my $cgi = $self->CGI();
  my $session = $self->Session();
  my $user=$session->User();
  my $ownerid=$user->id();
 # my @userProjects = OME::Project->search( owner_id => $ownerid );
  #my @groupProjects=OME::Project->search( group_id => $user->Group()->id());

  my @groupProjects=$session->Factory()->findObjects("OME::Project",'group_id'=> $user->Group()->id());
  my @userProjects=$session->Factory()->findObjects("OME::Project",'owner_id'=> $ownerid);
 

  my $text="";

  my $rep=not_owned_project(\@groupProjects,\@userProjects); 
  my %gpDatasetList=();
  my %gpImageList=();
   
  if (defined $rep){
    foreach (@$rep){
	my @datasets=$_->datasets();		
	foreach my $d (@datasets){
	   $gpDatasetList{$d->dataset_id()}=$d->name() unless (exists $gpDatasetList{$d->dataset_id()});
	   my @images=$d->images();
	   foreach my $i (@images){
		$gpImageList{$i->image_id()}=$i->name() unless (exists $gpImageList{$i->image_id()});
		
	   }
      }
    }
  }
  
  my %userImageList=();
  
  if (scalar(@userProjects)==0){
	return "You must define a project first.";
  }
  foreach (@userProjects){
    my @datasets=$_->datasets();
    foreach my $dataset (@datasets){
       my @images=$dataset->images();
	 my %datasetInfo=();
       my %Remove=();
       $datasetInfo{$dataset->dataset_id()}=$dataset;
	 if (exists $gpDatasetList{$dataset->dataset_id()} || $dataset->locked()){
         $Remove{$dataset->dataset_id()}=undef ;
	 }else{
	   $Remove{$dataset->dataset_id()}=1 ;
       }

	 foreach my $i (@images){
	    
         if (exists($userImageList{$i->image_id()})){
	  	my $list=$userImageList{$i->image_id()}->{list};
            my %fusion=();
		%fusion=(%$list,%datasetInfo);
		$userImageList{$i->image_id()}->{list}=\%fusion; 
		my $remove=$userImageList{$i->image_id()}->{remove};
            my %mix=();
		%mix=(%$remove,%Remove);
		$userImageList{$i->image_id()}->{remove}=\%mix; 

            
	   }else{
		my $formatimage="";
		my ($booldel)=1;
		if (exists $gpImageList{$i->image_id()}){
    		 $booldel=undef;
            }
		$userImageList{$i->image_id()}->{list}=\%datasetInfo;
		$userImageList{$i->image_id()}->{image}=$formatimage;
 		$userImageList{$i->image_id()}->{remove}=\%Remove;
		$userImageList{$i->image_id()}->{name}=$i->name();
		$userImageList{$i->image_id()}->{owner}=$i->experimenter_id();

		$userImageList{$i->image_id()}->{booldel}=$booldel;

	   }
	 }
    }
  }
  # format here:
  my $count=0;
  foreach (keys %userImageList){
	$count++;
	my $a=$userImageList{$_}->{remove};
	my $boolremove=undef;
      foreach my $r (keys %$a){
	 if (defined ${$a}{$r}){
	   $boolremove=1;
	 }
      }
      my $b=$userImageList{$_}->{list};
	#my $formatimage=format_image($_,$userImageList{$_}->{name},$userImageList{$_}->{owner},$ownerid,$cgi,$userImageList{$_}->{booldel},$boolremove);
	my $formatimage=format_image($_,$userImageList{$_}->{name},$userImageList{$_}->{owner},$ownerid,$cgi,$userImageList{$_}->{booldel});
   $userImageList{$_}->{image}=$formatimage;

  }
  if ($count==0){
   $text.="<br><b>no images to display.</b>";
  }else{
   $text.=format_output(\%userImageList,$cgi);
  }

}

sub format_output{
   my ($userImage,$cgi)=@_;
   my %userImageList=();
   %userImageList=%$userImage;
   
   my $summary="";
   my $rows="";
   my $bool=undef;
   foreach (keys %userImageList){
	my $checkbox="";
      
	my ($a,$b)=format_checkbox($_,$userImageList{$_}->{list},$userImageList{$_}->{remove},$cgi);
	$checkbox.=$a;
	if (defined $b){
	 $bool=1;
	}
	$rows.=$cgi->Tr( { -valign=>'middle' },
		 $cgi->td({ -align=>'left' },$userImageList{$_}->{image}),
		 $cgi->td({ -align=>'left' },$checkbox)
			   );


   }
   $summary.=$cgi->h3("List of image(s) used:");
   $summary.=$cgi->startform;
   $summary.=$cgi->table( { -border=>1 },
		 $cgi->Tr( { -valign=>'middle' },
		 $cgi->td({ -align=>'left' },'<B>Images</B>'), 
		 $cgi->td({ -align=>'left' },'<B>Datasets related</B>'),

			),
			 $rows) ;
   if (defined $bool){
   $summary.="<br><br><center>".$cgi->submit (-name=>'Remove',-value=>'Remove')."</center>";
   }
   $summary.=$cgi->endform;
   return $summary;
}


sub format_image{
  my ($id,$name,$ownImage,$ownerid,$cgi,$booldel)=@_;
  my $summary="";
  my ($buttonView,$buttonDelete);
  $buttonView=create_button($id);
  $buttonDelete=$cgi->submit (-name=>$id,-value=>'Delete')
    if ($ownerid==$ownImage and defined $booldel);
 
  $summary .= "<NOBR><B>Name:</B> ".$name."</NOBR><BR>" ;
  $summary .= "<B>Image ID:</B> ".$id."<BR>" ;
  $summary.="<br>";
  $summary.=$cgi->table( { -border=>1 },
			  $cgi->Tr( { -valign=>'middle' },
				$cgi->td({ -align=>'left' },$buttonView),
				$cgi->td({ -align=>'left' },$buttonDelete),

			  )
			     );

  return $summary;
}

sub format_checkbox{
  my ($datasetID,$ref,$refrem,$cgi)=@_;
  my $text="";
  my @list=();
  # Cannot Use cgi->checkbox
  my $bool=undef;
  foreach (keys %$ref){
	my $val;
	my $pair=$datasetID."-".$_;
      if (defined ${$refrem}{$_}){
	   $bool=1;
	   $val="<input type=\"checkbox\" name=\"List\" value=\"$pair\"/>".${$ref}{$_}->name();
      }else{
        $val=${$ref}{$_}->name();
      }
	push(@list,$val);
  }
   $text.=join("<br>",@list);


 return ($text,$bool);
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


1;

