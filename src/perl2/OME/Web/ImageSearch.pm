# OME/Web/ImageSearch.pm

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


package OME::Web::ImageSearch;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;

use OME::Research::SearchEngine;
use base qw(OME::Web);




sub getPageTitle {
	return "Open Microscopy Environment - Image Search" ;

}

sub getPageBody {
	my	$self = shift ;
	my 	$cgi = $self->CGI() ;
	my 	$body="" ;
	my 	$table="images";			#table name
      my 	$selectedcolumns="name,inserted,image_id";	#columns in table images
	my    $ref;
     
	if ($cgi->param('execute') ) {
	   my $tableRows="";
         my $string=cleaning($cgi->param('name'));
         return ('HTML',"<b>Please enter a data.</b>") unless length($string)>1;


         my $research=new OME::Research::SearchEngine($table,$string,$selectedcolumns);
         if (defined $research){
	    $ref=$research->searchEngine;
         }
         if (defined $ref){
		$body .=format_popup();
		$body .=format_output($ref,$cgi);
         }else{
		$body.="No Image found.";

         }

	}else{
       $body .=format_form($cgi);
      }
	return ('HTML',$body) ;
}


#---------------------
# PRIVATE METHODS
#---------------------


sub format_output{
 # format informations on images

   my ($ref,$cgi)=@_;
   my $text="";
   my $tableRows="";
   foreach (@$ref){
      my $button=create_button($_->{image_id});

	$tableRows .=$cgi->Tr( { -valign=>'MIDDLE' },
	   		   $cgi->td( { -align=>'LEFT' },$_->{name} ),
			   $cgi->td( { -align=>'LEFT' },$_->{inserted}),
			   $cgi->td( { -align=>'CENTER' },$button),
				  );

  }
  $text.=$cgi->h3("List of image(s) matching your data.");
  $text.="<form>";
  $text.=$cgi->table( { -border=>1 },
	   $cgi->Tr( { -valign=>'MIDDLE' },
	      $cgi->td( { -align=>'LEFT' },'<b>Name</b>' ),
	      $cgi->td( { -align=>'CENTER' },'<b>Inserted</b>' ),
	      $cgi->td( { -align=>'CENTER' },'<b>View Image</b>' ),	
			),
         $tableRows );
  $text.="</form>";
return $text;
}



sub format_form{
	my ($cgi) =@_ ;
	my $form="";
	$form .= $cgi->h3('Search For Images') ;
	$form .= $cgi->p('Please enter the data to match.') ;
	$form .=$cgi->startform;
	$form .= $cgi->start_table({-border=>0,-cellspacing=>4,-cellpadding=>0}) ;
	$form .= $cgi->Tr({-align=>'left',-valign=>'middle'},
				$cgi->td( $cgi->b('Name contains'),
						$cgi->textfield(-name=>'name',-size=>25) ) 
			) ;
	$form .= $cgi->Tr({-align=>'center',-valign=>'middle'},
   				$cgi->td( {-colspan => 2},
						$cgi->submit({-name=>'execute',-value=>'OK'}) )  
			) ;
	$form .= $cgi->end_table() ;
	$form .=$cgi->endform;
	return $form ;


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



sub cleaning{
 my ($string)=@_;
 chomp($string);
 $string=~ s/^\s*(.*\S)\s*/$1/;
 return $string;

}











1;



