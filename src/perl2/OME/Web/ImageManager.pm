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
	   my $image=$revArgs{Remove};
	   my @groupdatasets=$cgi->param('List');
    	   my $table="image_dataset_map";
	   if (scalar(@groupdatasets)>0){
		   my @control=();
		   foreach (@groupdatasets){
			my $cd;
			my ($condition,$result);
			my %h=();
    		      $condition="image_id=".$image." AND dataset_id=".$_;
			$result=do_request($table,$condition);
			if (defined $result){
			  push(@control,$_);
			}
		   }  
		   if (scalar(@control)==scalar(@groupdatasets)){
			$body.=$cgi->h3("The image has been successfully removed from selected datasets");
		   }else{
			$body.=$cgi->h3("Cannot remove image in at least one dataset.");
		   }
		}else{
		   $body.=$cgi->h3("Please select at least one dataset");
		}



	}else{
       $body.=$self->print_list(); 
      }
     return ('HTML',$body);
}






#----------------------------
# PRIVATE METHODS
#---------------------------

sub print_list{

  my $self = shift;
  my $cgi = $self->CGI();
  my $session = $self->Session();
  my $ownerid=$session->User()->experimenter_id;
  my @userProjects = OME::Project->search( owner_id => $ownerid );
  my %ImageList=();
  my $text="";
  if (scalar(@userProjects)==0){
	return "You must define a project first.";
  }
 foreach (@userProjects){
    my @datasets=$_->datasets();
  
    foreach my $dataset (@datasets){
	 my $datasetid=$dataset->dataset_id();
       my  @listimages=();
	 @listimages=$dataset->images();
	 my %datasetInfo=();
       $datasetInfo{$datasetid}=$dataset->name();
       if (scalar(@listimages)>0){
		 foreach my $image (@listimages){
		    my $imageID=$image->image_id();
		    if (exists($ImageList{$imageID})){
			 my $list=$ImageList{$imageID}->{list};
                   my %fusion=();
			 %fusion=(%$list,%datasetInfo);
			 $ImageList{$imageID}->{list}=\%fusion; 
		    }else{
			my $formatimage="";
			$formatimage.=format_image($image,$cgi);
			$ImageList{$imageID}->{list}=\%datasetInfo;
			$ImageList{$imageID}->{image}=$formatimage;

		    }
		 }
	    }#fin scalar	
	  }#end dataset
 }
 $text.=format_popup("");
  $text.=format_output(\%ImageList,$cgi);

}


sub format_image{
  my ($image,$cgi)=@_;
  my $summary="";
  my ($id,$button);
  $id=$image->image_id();
  $button=create_button($id);
  $summary .= "<NOBR><B>Name:</B> ".$image->name()."</NOBR><BR>" ;
  $summary .= "<B>Image ID:</B> ".$id."<BR>" ;
  $summary .=$button;
  
  return $summary;
}

sub format_output{
   my ($ref,$cgi)=@_;
   my %List=();
   %List=%$ref;
   my $summary="";
   my $rows="";
   foreach (keys %List){
	my $formatdataset="";
	$formatdataset.=format_dataset($List{$_}->{list},$cgi);

	$rows.=$cgi->Tr( { -valign=>'middle' },
		 $cgi->td({ -align=>'left' },$List{$_}->{image}),
		 $cgi->td({ -align=>'left' },$formatdataset)
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
   $summary.=$cgi->endform;



  return $summary;
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



sub format_dataset{
  my ($ref,$cgi)=@_;
  my $text="";
  my @end=();
  foreach (keys %$ref){
    my $data="";
    $data.="<b>Name:</b> ".${$ref}{$_}."<br>";
    $data.="<b>Id:</b> ".$_;
    push(@end,$data);

  }
 $text.="<P>";
 $text.=join("<br>",@end);
 $text.="</P>";

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

