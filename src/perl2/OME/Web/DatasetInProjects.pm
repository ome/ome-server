# OME/Web/DatasetInProjects.pm

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



package OME::Web::DatasetInProjects;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use base qw{ OME::Web };
sub getPageTitle {
	return "Open Microscopy Environment - Projects Containing Current Dataset";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();
      my @list=$session->project()->datasets();
      if (scalar(@list)==0){
		$body.=$cgi->h3("No current dataset. Please define a dataset");
		 return ('HTML',$body);


	}
	# better if others options later
	my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;

	if (exists	$revArgs{Select}){
	   my $newproject=$session->Factory()->loadObject("OME::Project",$revArgs{Select})
         or die "Unable to load project ( ID = ".$revArgs{Select}." ). Action cancelled<br>";
         $session->project($newproject);
	   $session->writeObject();
         my $projectnew=$session->project();
	   my @datasets=$projectnew->datasets();
         $body.=format_currentproject($projectnew,$cgi);
	   $body.=format_dataset($session->dataset()->name(),\@datasets,$cgi);
	   $body .= "<script>top.title.location.href = top.title.location.href;</script>";

	}elsif ($cgi->param('execute')){
	   my $newdataset= $session->Factory()->loadObject("OME::Dataset", $cgi->param('newdataset'))
			or die "Unable to load dataset (id: ".$cgi->param('newdataset').")\n";

	   $session->dataset($newdataset);
	   $session->writeObject();
	   my $name=$session->dataset()->name();
	   my $formatproject=format_currentproject($session->project(),$cgi);
	   my @datasets=$session->project()->datasets();
	   my $formatdata=format_dataset($name,\@datasets,$cgi);
	   $body.=$formatproject;
	   $body.=$formatdata;
	   $body .= "<script>top.title.location.href = top.title.location.href;</script>";

	}else{
	   my $dataset=$session->dataset();
         my @listprojects=();
         if (defined $dataset){
            @listprojects=$dataset->projects();
	      $body.=format_currentdataset($dataset,$cgi);
            if (scalar(@listprojects)>0){
		   $body.=format_projects(\@listprojects,$cgi);
            }else{
	         $body.=$cgi->h3('The current dataset is contained in no project.') ;
            }
         }else{
            $body .= $cgi->h3('You have no dataset currently selected. Please select one.') ;
         }

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
 $summary .= "<NOBR><B>Locked:</B> ".($dset->locked()?'YES':'NO')."</NOBR></BR>" ;
 $summary .="<NOBR><B>Nb Images in dataset:</B> ".scalar($dset->images())."</NOBR></P>" ;

 return $summary ;

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
					$cgi->submit (-name=>'execute',-value=>'Switch') ) ),
		);
	$summary .= $cgi->endform;
		
 }else{
 	$summary.="<P>Your current dataset is: <B>".$dataname."</B></P>";
 }
 return $summary;
}







sub format_projects{

  my ($ref,$cgi)=@_;
  my $summary="";
  if (scalar(@$ref)==1){
     $summary .= $cgi->h3('The current dataset is contained in the project listed below.') ;
  }else{
     $summary .= $cgi->h3('The current dataset is contained in the projects listed below.') ;
  }
  my $tableRows="";
  foreach (@$ref){
     $tableRows .= $cgi->Tr( {-valign=>'middle'},
					$cgi->td({-align=>'left'},$_->name()),
					$cgi->td({-align=>'left'},$_->project_id()),
					$cgi->td({-align=>'left'},$_->description()),
					$cgi->td( { -align=>'CENTER' },
						$cgi->submit (-name=>$_->project_id(),-value=>'Select')
					),
				    );
  }
  $summary.=$cgi->startform;
  $summary .= $cgi->table( {-border=>1},
		  $cgi->Tr( {-valign=>'middle'},
		  		$cgi->td({-align=>'left'},'<B>Name</B>'),
		 		$cgi->td({-align=>'left'},'<B>ID</B>'),  
		  		$cgi->td({-align=>'left'},'<B>Description</B>'),
				$cgi->td( { -align=>'CENTER' },'<b>Select</b>' ),
			  ),
			$tableRows ) ;
 $summary.=$cgi->endform;

 return $summary;
}



1;
