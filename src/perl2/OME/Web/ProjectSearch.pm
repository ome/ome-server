# OME/Web/ProjectSearch.pm

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


package OME::Web::ProjectSearch;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;

use OME::Research::SearchEngine;
use base qw(OME::Web);




sub getPageTitle {
	return "Open Microscopy Environment - Project Search" ;

}

sub getPageBody {
	my	$self = shift ;
	my 	$cgi = $self->CGI() ;
	my 	$body="" ;
	my 	$session=$self->Session();
	my	$userID=$session->User()->id();
	my 	$table="projects";			#table name
      my 	$selectedcolumns="name,description,project_id,owner_id";	#columns in table projects
	my    $ref;
      my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;

	if ($cgi->param('execute') ) {
         my $tableRows="";
         my $string=cleaning($cgi->param('string'));
	   return ('HTML',"<b>Please enter a data.</b>") unless length($string)>1;
        
         my $research=new OME::Research::SearchEngine($table,$string,$selectedcolumns);
         if (defined $research){
	    $ref=$research->searchEngine;
         }
          if (defined $ref){
		$body.=format_popup();
            $body .=format_output($ref,$userID,$cgi);
          }else{
		$body.="No Project found.";

          }
	}elsif ($cgi->param('switch') ) {
		my $newdataset= $session->Factory()->loadObject("OME::Dataset", $cgi->param('newdataset'))
			or die "Unable to load dataset (id: ".$cgi->param('newdataset').")\n";

		$session->dataset($newdataset);
		$session->writeObject();
		my $name=$session->dataset()->name();
		my @datasets=$session->project()->datasets();
		$body.=format_currentproject($session->project(),$cgi);
		$body.=format_dataset($name,\@datasets,$cgi);
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		
	}elsif (exists $revArgs{Select}){
        my $project = $session->Factory()->loadObject("OME::Project",$revArgs{Select})
         or die "Unable to load project ( ID = ".$revArgs{Select}." ). Action cancelled<br>";	
		
        $session->project($project);
	  $session->writeObject();
        my $projectnew=$session->project();
	  my @datasets=$projectnew->datasets();
        if (scalar(@datasets)>0){
          $session->dataset($datasets[0]);
	    $session->writeObject();
	    $body.=format_currentproject($projectnew,$cgi);
	    $body.=format_dataset($datasets[0]->name(),\@datasets,$cgi);
	    $body .= "<script>top.title.location.href = top.title.location.href;</script>";
	  }else{
	     $session->dissociateObject('dataset');
	     $session->writeObject();

	     $body.="No Dataset associated to this project. Please define a dataset.";
	     $body .= OME::Web::Validation->ReloadHomeScript();
	     $body .= "<script>top.title.location.href = top.title.location.href;</script>";

        }

	}else{
       $body .=format_form($cgi);
      }
	return ('HTML',$body) ;
}


#-----------------
# PRIVATE METHODS
#-----------------

sub format_form{
      my ($cgi) = @_ ;
	my $form="";
	$form .= $cgi->h3('Search For Projects') ;
	$form .= $cgi->p('Please enter the data to match.') ;
	$form .= $cgi->startform;
	$form .= $cgi->start_table({-border=>0,-cellspacing=>4,-cellpadding=>0}) ;
	$form .= $cgi->Tr({-align=>'left',-valign=>'middle'},
				$cgi->td( $cgi->b('Name contains'),
						$cgi->textfield(-name=>'string',-size=>25) ) 
			) ;
	$form .= $cgi->Tr({-align=>'center',-valign=>'middle'},
   				$cgi->td( {-colspan => 2},
						$cgi->submit({-name=>'execute',-value=>'OK'}) )  
			) ;
	$form .= $cgi->end_table() ;
	$form .=$cgi->endform;
	return $form ;

}



sub format_output{
  my ($ref,$userID,$cgi)=@_;
  my $tableRows="";
  my $text="";
  foreach (@$ref){
    my ($buttonSelect,$buttonInfo);
    $buttonInfo=create_button($_->{project_id});
    if ($userID==$_->{owner_id}){
	$buttonSelect=$cgi->submit (-name=>$_->{project_id},-value=>'Select');
    }
    $tableRows .= $cgi->Tr( { -valign=>'MIDDLE' },
	   		$cgi->td( { -align=>'LEFT' },$_->{name} ),
	   		#$cgi->td( { -align=>'LEFT' },$_->{description}),
			$cgi->td( { -align=>'CENTER' },$buttonSelect),
 			$cgi->td( { -align=>'CENTER' },$buttonInfo),

			);
  }
  
  $text.=$cgi->h3("List of projects matching your data");
  $text.= $cgi->startform;
  $text.=$cgi->table( { -border=>1 },
	   $cgi->Tr( { -valign=>'MIDDLE' },
	   $cgi->td( { -align=>'LEFT' },'<b>Name</b>' ),
	  # $cgi->td( { -align=>'CENTER' },'<b>Description</b>' ),
	   $cgi->td( { -align=>'CENTER' },'<b>Select as current projet</b>' ),
	   $cgi->td( { -align=>'CENTER' },'<b>Project Info</b>' ),

	    ),
	   $tableRows );
 $text .= $cgi->endform;

 return $text;
}

sub format_currentproject{
 my ($project,$cgi)=@_;
 my $summary="";
 $summary .= $cgi->h3('Your current project is:') ;
 $summary .= "<P><NOBR><B>Name:</B> ".$project->name()."</NOBR><BR>" ;
 $summary .= "<NOBR><B>ID:</B> ".$project->project_id()."</NOBR><BR>" ;
 $summary .= "<B>Description:</B> ".$project->description()."<BR></P>" ;
 return $summary ;

}

sub format_dataset{
 my ($dataname,$ref,$cgi)=@_;
 my @datasets=();
 my $summary="";
 @datasets=@$ref;
 if (scalar(@datasets)>1){
	# display a list

	my %datasetList= map {$_->dataset_id() => $_->name()} @datasets;
	$summary.="<P>Your current dataset is: <B>".$dataname."</B></P>";
	$summary.="<p> If you want to switch, please choose a dataset in the list below.</p>";
	$summary.=$cgi->startform;
	$summary.=$cgi->table(
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					$cgi->popup_menu (
						-name => 'newdataset',
						-values => [keys %datasetList],
						-labels => \%datasetList)
					 ),
			$cgi->td( { -align=>'LEFT' },
					$cgi->submit (-name=>'switch',-value=>'Switch') ) ),
		);
	$summary .= $cgi->endform;
		
 }else{
 	$summary.="<P>Your current dataset is: <B>".$dataname."</B></P>";
 }
 return $summary;
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
	OMEfile='/perl2/serve.pl?Page=OME::Web::GetInfo&ProjectID='+ID;
	projectInfo=window.open(
		OMEfile,
		"ProjectInfo",
		"toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500");
	projectInfo.focus();
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
