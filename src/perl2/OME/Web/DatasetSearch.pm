# OME/Web/DatasetSearch.pm

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


package OME::Web::DatasetSearch;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;

use OME::Research::SearchEngine;
use base qw(OME::Web);




sub getPageTitle {
	return "Open Microscopy Environment - Dataset Search" ;

}

sub getPageBody {
	my	$self = shift ;
	my 	$cgi = $self->CGI() ;
	my 	$session=$self->Session();
	my	$ownerID=$session->User()->experimenter_id;
	my 	$body="" ;
	my 	$table="datasets";		#table name
      my 	$selectedcolumns="name,description,locked,dataset_id";	#columns in table projects
	my    $ref;
      my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;
      if (exists $revArgs{Select}){
	  my $newdataset= $self->Session->Factory()->loadObject("OME::Dataset", $revArgs{Select})
		or die "Unable to load dataset (id: ".$revArgs{Select}.")\n";
        
	   $session->dataset($newdataset);
	   $session->writeObject();
	   $body.=format_currentdataset($session->dataset(),$cgi);
	   $body .= "<script>top.title.location.href = top.title.location.href;</script>";

	}elsif ($cgi->param('execute') ) {
	   my $tableRows="";
         my $string=cleaning($cgi->param('name'));
         return ('HTML',"<b>Please enter a data.</b>") unless length($string)>1;

         my $research=new OME::Research::SearchEngine($table,$string,$selectedcolumns);
         if (defined $research){
	    $ref=$research->searchEngine;
         }
          if (defined $ref){
		$body.=format_popup();
            $body.=format_output($session,$ref,$ownerID,$cgi);
          }else{
		$body.="No Dataset found.";
          }

	}else{
          $body .=format_form($cgi);
      }
	return ('HTML',$body) ;
}


#------------------
# PRIVATE METHODS
#------------------


sub format_form{
	my ($cgi) =@_;
	my $form="";
	$form .= $cgi->h3('Search For Datasets') ;
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
	$form.=$cgi->endform;
	return $form ;

}

sub format_output{
   my ($session,$ref,$ownerID,$cgi)=@_;
   my $tableRows="";
   my $text="";
   # select button only for the dataset used
   my @userProjects=$session->Factory()->findObjects("OME::Project",'owner_id'=>$ownerID);

  # my @userProjects = OME::Project->search( owner_id => $ownerID );
   my %datasetList=();
   foreach (@userProjects){
     my @datasets=$_->datasets();
     foreach my $data (@datasets){
	   $datasetList{$data->dataset_id()}=$data->name() unless $datasetList{$data->dataset_id()};
     }
  }

  



   foreach (@$ref){
	my ($buttonSelect,$buttonInfo);
	#Control for the time being. due to import process
	if ($_->{name} eq "Dummy import dataset"){
	  next;
      }
	$buttonInfo=create_button($_->{dataset_id});
      if (exists $datasetList{$_->{dataset_id}}){
         $buttonSelect=$cgi->submit (-name=>$_->{dataset_id},-value=>'Select');
      }

      $tableRows .= $cgi->Tr( { -valign=>'MIDDLE' },
	   		    $cgi->td( { -align=>'LEFT' },$_->{name} ),
	   		    # $cgi->td( { -align=>'LEFT' },$_->{description}),
			    #$cgi->td( { -align=>'LEFT' },($_->{locked})?"YES":"NO"),
      		    $cgi->td( { -align=>'CENTER' },$buttonSelect),
			    $cgi->td( { -align=>'CENTER' },$buttonInfo),

			   );

   }
   $text.=$cgi->h3("List of dataset(s) matching your data");
   $text.=$cgi->startform;
   $text.=$cgi->table( { -border=>1 },
	      $cgi->Tr( { -valign=>'MIDDLE' },
	       $cgi->td( { -align=>'LEFT' },'<b>Name</b>' ),
	       #$cgi->td( { -align=>'CENTER' },'<b>Description</b>' ),
	       #$cgi->td( { -align=>'CENTER' },'<b>Locked</b>' ),
	       $cgi->td( { -align=>'CENTER' },'<b>Select as current dataset</b>' ),
  		 $cgi->td( { -align=>'CENTER' },'<b>Dataset Info</b>' ),

		),
           $tableRows );
   $text.=$cgi->endform;

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


sub format_popup{
  my ($text)=@_;
 $text.=<<ENDJS;
<script language="JavaScript">
<!--
var ID;
function OpenPopUp(id) {
      ID=id;
	var OMEfile;
	OMEfile='/perl2/serve.pl?Page=OME::Web::GetInfo&DatasetID='+ID;
	Info=window.open(
		OMEfile,
		"DatasetInfo",
		"toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500");
	Info.focus();
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
	value="Info"
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

