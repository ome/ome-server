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
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();
      my $dataset =$session->dataset();
      # MUST BE CHANGED
      my @list=$session->project()->datasets();
      if (scalar(@list)==0){
		$body.=$cgi->h3("No current dataset. Please define a dataset");
		 return ('HTML',$body);


	}
	#
	my @listimages=();
	if (defined $dataset){
	    @listimages=$dataset->images();
          $body.=format_currentdataset($dataset,$cgi);
	    if (scalar(@listimages)>0){
		$body.=format_popup();
		$body.=format_images(\@listimages,$cgi);
         }else{
	     $body.=$cgi->h3('The current dataset contains no image.') ;
         }

     }else{
	  $body .= $cgi->h3('You have no dataset currently selected. Please select one.') ;
     }
      return ('HTML',$body);
}





#---------------------
#PRIVATE METHODS
#---------------------

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

