# OME/Web/DatasetManager.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
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
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:    Jean-Marie Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::ManageDataset;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;

use OME::Tasks::DatasetManager;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Helper::JScriptFormat;

use base qw{ OME::Web };
sub getPageTitle {
	return "Open Microscopy Environment - Dataset Manager";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $session = $self->Session();
	my $datasetManager=new OME::Tasks::DatasetManager($session);
	my $htmlFormat=new OME::Web::Helper::HTMLFormat;
	my $jscriptFormat=new OME::Web::Helper::JScriptFormat;

	my $body = "";
     	my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;
	$body.= $jscriptFormat->popUpDataset();	

	if (exists $revArgs{Select}){
	   	$datasetManager->switch($revArgs{Select});
	   	$body.=$htmlFormat->formatDataset($session->dataset());
	   	$body .= "<script>top.title.location.href = top.title.location.href;</script>";

	}elsif (exists $revArgs{Remove}){
		my @group=$cgi->param('List');
		my ($a,$b)=remove_dataset(\@group,$session,$datasetManager);  
		$body.=$a;
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		if (!defined $b){
		  $body .=retrieve_result($session,$datasetManager,$htmlFormat,$cgi);
		}
	}elsif (exists $revArgs{Delete}){
	   	my $rep=$datasetManager->delete($revArgs{Delete});
	  	if (defined $rep){
         	  $body .= retrieve_result($session,$datasetManager,$htmlFormat,$cgi);
	   	  $body .= "<script>top.title.location.href = top.title.location.href;</script>";
	   	}else{
	   	  $body.="cannot delete selected dataset";
	   	}
	}else{
	  	$body.=retrieve_result($session,$datasetManager,$htmlFormat,$cgi);
      }
	return ('HTML',$body);
}


#------------------
#PRIVATE METHODS
#------------------

sub remove_dataset{
  my ($ref,$session,$datasetManager)=@_;
  my $table="project_dataset_map";
  my $text="";
  my $bool=undef;
  return ("<b>Please select at least one project</b>",1) if scalar(@$ref)==0;	
  my %list=();
  foreach (@$ref){
      my ($datasetID,$projectID)=split('-',$_);
	if (exists $list{$datasetID}){
	  my $val=$list{$datasetID};
	  push(@$val,$projectID);
	  $list{$datasetID}=$val;
	}else{
	  my @a=();
	  push(@a,$projectID);
	  $list{$datasetID}=\@a;

	}
  }
  $datasetManager->remove(\%list);
  return ($text,$bool);

}

####
sub retrieve_result{
  my ($session,$datasetManager,$htmlFormat,$cgi)=@_;
  my @a=($session->User()->Group()->id());
  my ($share,$use,$count)=$datasetManager->manage(\@a);
  my %list=();
  my $text="";
  if ($count==0){
	$text.="<b>No dataset used </b>";
	return $text;
 }
   foreach my $s (keys %$use){
	my $format;
	my $object=${$use}{$s}->{object};
	my $userID=$object->owner_id();
	my $user=$session->Factory()->loadAttribute("Experimenter",$userID);	

	if (exists(${$share}{$s})){
	  $format=format_dataset($object,$session->User()->id(),$htmlFormat,$user,1);
      }else{
	  $format=format_dataset($object,$session->User()->id(),$htmlFormat,$user);
      }
	$list{$s}->{text}=$format;
	$list{$s}->{list}=${$use}{$s}->{project};		 
  }
  
  $text.=format_output(\%list,$htmlFormat,$cgi);

  return $text;

}


sub format_dataset {
	my ($dataset,$userID,$htmlFormat,$user,$bool)=@_;
	my $summary="";
	$summary .=$htmlFormat->formatDataset($dataset,1);
	$summary .=$htmlFormat->buttonControl($dataset,$userID,$user,$bool,"dataset");
      return $summary;

}


sub format_output {
	my ($ref,$htmlFormat,$cgi)=@_;
	my $text="";
	$text.="<h3>List of dataset(s) used:</h3>";
  	$text.=$cgi->startform;
	$text.=$htmlFormat->manager($ref,"Remove","Remove","dataset");
	#$text.=$htmlFormat->buttonValid("Remove","Remove");
	$text.=$cgi->endform;
	return $text;
}






1;
