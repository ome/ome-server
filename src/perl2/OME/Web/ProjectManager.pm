# OME/Web/ProjectManager.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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

#JM 11-03
package OME::Web::ProjectManager;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::SetDB;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Project Manager";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();
	my $currentproject=$session->project();
	# do we need to save?
	# ... check for save in cgi params, save, display message
	#don't forget to include these lines after saving
	# this will add a script to reload OME::Home if it's necessary
	#	require OME::Web::Validation;
	#	$body .= OME::Web::Validation->ReloadHomeScript();
	
	my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;

	if (exists	$revArgs{Select}){
	   my $newproject=$session->Factory()->loadObject("OME::Project",$revArgs{Select})
         or die "Unable to load project ( ID = ".$revArgs{Select}." ). Action cancelled<br>";
         $session->project($newproject);
	   $session->writeObject();
         my $projectnew=$session->project();

		
	   my @datasets=$projectnew->datasets();
         if (scalar(@datasets)>0){
        	 $session->dataset($datasets[0]);		#switch dataset ??
	   	 $session->writeObject();
	       $body.=format_project($projectnew,$cgi);
	       $body.=format_dataset($datasets[0]->name(),\@datasets,$cgi);
	       $body .= "<script>top.title.location.href = top.title.location.href;</script>";
	   }else{
		 $session->dissociateObject('dataset');
		 $session->writeObject();

		 $body.="No Dataset associated to this project. Please define a dataset.";
		 $body .= OME::Web::Validation->ReloadHomeScript();
		 $body .= "<script>top.title.location.href = top.title.location.href;</script>";

	   }
	}elsif (exists $revArgs{Delete}){		
		 my $deleteproject=$session->Factory()->loadObject("OME::Project",$revArgs{Delete})
        	 or die "Unable to load project ( ID = ".$revArgs{Delete}." ). Action cancelled<br>";
           
		if ($deleteproject->project_id()==$currentproject->project_id()){
		  $body.=delete_process($deleteproject,$session);
		  $body .= OME::Web::Validation->ReloadHomeScript();
		  $body .= "<script>top.title.location.href = top.title.location.href;</script>";
		 
		}else{
		   $body.=delete_process($deleteproject);
		   $body.=$self->print_form();
		}
	     
	##
	}elsif ($cgi->param('execute')){
	   my $newdataset= $session->Factory()->loadObject("OME::Dataset", $cgi->param('newdataset'))
			or die "Unable to load dataset (id: ".$cgi->param('newdataset').")\n";

	   $session->dataset($newdataset);
	   $session->writeObject();
	   my $name=$session->dataset()->name();
	   my $formatproject=format_project($session->project(),$cgi);
	   my @datasets=$session->project()->datasets();
	   my $formatdata=format_dataset($name,\@datasets,$cgi);
	   $body.=$formatproject;
	   $body.=$formatdata;
	   $body .= "<script>top.title.location.href = top.title.location.href;</script>";
		


	}else{
	   $body .= $self->print_form();
	}
    return ('HTML',$body);
}


#-------------------------------
# PRIVATE METHODS
#------------------------------
sub delete_process{
   my ($deleteproject,$session)=@_;
   my $text="";
   my @datasetused=$deleteproject->datasets();
   my @myProjects=OME::Project->search( owner_id => $session->User()->experimenter_id ) if (defined $session);
   
   my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword())  
   or die "Unable to connect <br>";


   if (scalar(@datasetused)==0){
	# delete only entry in table:projects
	# cannot happen !
      if (defined $session){
	   if (scalar(@myProjects)==1){
	     $session->dissociateObject('project');
	     $session->writeObject();
	   }else{
		my @new=();
		foreach (@myProjects){
              push(@new,$_) unless $_->project_id()==$deleteproject->project_id();

		}
		my $newproject=$new[0];
		my @newdataset=$newproject->datasets();
		$session->project($newproject);
		#$session->writeObject(); 
		if (scalar(@newdataset)==0){
		  $session->dissociateObject('dataset');
            }else{
		   $session->dataset($newdataset[0]);
		}
		$session->writeObject(); 

         }
	}
	$text.=delete_project($deleteproject,$db);
   }else{
	# delete in project_dataset_map
	my $rep;
	$rep=delete_datasets($deleteproject,\@datasetused,$db);
      return "Cannot delete dataset." if (!defined $rep);
	#$text.=$rep."<br>";
	if (defined $session){
	    if (scalar(@myProjects)==1){
	      $session->dissociateObject('dataset');
	      $session->writeObject();
	      $session->dissociateObject('project');
	      $session->writeObject();
	    }else{
		my @new=();
		foreach (@myProjects){
              push(@new,$_) unless $_->project_id()==$deleteproject->project_id();

		}
		my $newproject=$new[0];
		my @newdataset=$newproject->datasets();
		$session->project($newproject);
		#$session->writeObject(); 
		if (scalar(@newdataset)==0){
		   $session->dissociateObject('dataset');  
            }else{
		  $session->dataset($newdataset[0]);
		}
		$session->writeObject(); 


	    }
	}

      $text.=delete_project($deleteproject,$db);   		  						
   }
  $db->Off();
   return $text;
}


sub delete_project{
 my ($deleteproject,$db)=@_;
 my $text="";
 my $tableProject="projects";
 my ($condition,$result);
 $condition="project_id=".$deleteproject->project_id();
 $result=do_request($tableProject,$condition,$db);
 if (defined $result){
     $text.="The project <b>".$deleteproject->name()."</b> has been successfully deleted.";
 }else{
     $text.="Cannot delete the project.<b>".$deleteproject->name()."</b>";
 }
  return $text;

}

sub delete_datasets{
  my ($deleteproject,$ref,$db)=@_;
  my $tableProjectMap="project_dataset_map";
  foreach (@$ref){
    my ($condition,$result);
    $condition="project_id=".$deleteproject->project_id()." AND dataset_id=".$_->dataset_id();
    $result=do_request($tableProjectMap,$condition,$db);
    return undef if (!defined $result);
	
  }
  return 1;
}






sub print_form {

	my $self=shift;
	my $cgi=$self->CGI();
	my $session=$self->Session();
	my $text ="";
	my $tableRows="";
	my @projects=OME::Project->search( owner_id => $session->User()->experimenter_id );
	
	return ('HTML',"Please define a project firt.<br>") if scalar(@projects)==0;
	$text .=format_popup();
	$text .=$cgi->h3("You own these projects:");	
	foreach (@projects) {
		my $buttonInfo=create_button($_->{project_id});
		$tableRows .= 
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					$_->name() ),
				$cgi->td( { -align=>'LEFT' },
					$_->project_id() ),
				$cgi->td( { -align=>'CENTER' },
					$cgi->submit (-name=>$_->project_id(),-value=>'Select') 
					),
				$cgi->td( { -align=>'CENTER' },
					$cgi->submit (-name=>$_->project_id(),-value=>'Delete') 
					),
				$cgi->td( { -align=>'CENTER' },$buttonInfo
					),

				
								 );
	}
	$text.=$cgi->startform;
	$text .=$cgi->table( { -border=>1 },
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'<b>Name</b>' ),
				$cgi->td( { -align=>'LEFT' },
					'<b>ID</b>' ),
				$cgi->td( { -align=>'CENTER' },
					'<b>Select</b>' ),
				$cgi->td( { -align=>'CENTER' },
					'<b>Delete</b>' ),
				$cgi->td( { -align=>'CENTER' },
					'<b>Project Info</b>' ),

					),
			$tableRows );
	$text.=$cgi->endform;
	$text .= '<br><br>What would you like to do with these? Think about it. <a href="mailto:igg@nih.gov,bshughes@mit.edu,dcreager@mit.edu,siah@nih.gov,a_falconi_jobs@hotmail.com">email</a> the developers.';
	
	return $text;

}


sub format_project{
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
	$summary.="<p> If you want to switch, please choose a dataset in the list of datasets associated 
	 to this current project.</p>";
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
					$cgi->submit (-name=>'execute',-value=>'Switch') ) ),
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












sub do_request{
 my ($table,$condition,$db)=@_;
 my $result;
 if (defined $db){
      $result=$db->DeleteRecord($table,$condition);
 
 }
 return $result;

}








1;