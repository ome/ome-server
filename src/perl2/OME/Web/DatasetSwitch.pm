# OME/Web/DatasetSwitch.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  J-M Burel <j.burel@dundee.ac.uk>
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


package OME::Web::DatasetSwitch;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Web::Validation;
use base qw{ OME::Web };

sub getPageTitle {
 	return "Open Microscopy Environment - Switch Dataset";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();

	if ($cgi->param('Switch')){
	  my $newDataset = $session->Factory()->loadObject("OME::Dataset", $cgi->param('newDataset') )
		or die "Unable to load project (id: ".$cgi->param('newDataset').")\n";
	  $session->dataset($newDataset);
	  $session->writeObject();
	}
	$body.=$self->print_form();
	
      return ('HTML',$body);
}






#--------------------
# PRIVATE METHODS
#------------------

sub print_form {
   my $self = shift;
   my $cgi = $self->CGI();
   my $text="";
   my $dataset = $self->Session()->dataset();

  # my @datasets = OME::Dataset->search( group_id => $self->Session()->User()->group()->group_id() );
  
  # Switch to  a dataset you are using
  my @userProjects = OME::Project->search( owner_id => $self->Session()->User()->experimenter_id );
  return "You must define a project first." unless scalar(@userProjects)>0;
  my %datasetList=();
  foreach (@userProjects){
     my @datasets=$_->datasets();
     foreach my $data (@datasets){
	 my @images=$data->images();
       if (scalar(@images)>0){
           $datasetList{$data->dataset_id()}=$data->name() unless $datasetList{$data->dataset_id()};
	 }
     }
  }
  
  #my %datasetList = map { $_->dataset_id() => $_->name()} @datasets if (scalar @datasets) > 0;

   if (defined $dataset){
    $text.=format_currentdataset($dataset,$cgi);
   }else{
    $text.=$cgi->h3('No current dataset');
   }
   $text .= $cgi->startform;
   $text .= $cgi->table(
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					$cgi->popup_menu (
						-name => 'newDataset',
						-values => [keys %datasetList],
						-labels => \%datasetList)
					  ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->submit (-name=>'Switch',-value=>'Switch Datasets') ) ),
		);
			
	$text .= $cgi->endform;
	$text .= "<script>top.title.location.href = top.title.location.href;</script>";


	return $text;
	
}

sub format_currentdataset {
 my ($data,$cgi)=@_;
 my $summary="";
 $summary .= $cgi->h3('Your current dataset is:') ;
 $summary .= "<NOBR><B>Name:</B> ".$data->name()."</NOBR><BR>" ;
 $summary .= "<NOBR><B>ID:</B> ".$data->dataset_id()."</NOBR><BR>" ;
 $summary .= "<B>Description:</B> ".$data->description()."<BR>" ;
 $summary .= "<NOBR><B>Locked:</B> ".($data->locked()?'YES':'NO')."</NOBR><br>";                  
 $summary .= "<NOBR><B>Owner:</B> ".$data->owner()->firstname()." ".$data->owner()->lastname()."</NOBR><BR>";
 $summary.="<NOBR><B>E-mail:</B><a href='mailto:".$data->owner()->email()."'>".$data->owner()->email()."</a></NOBR><BR>";
 $summary .="<NOBR><B>Nb Images in dataset:</B> ".scalar($data->images())."</NOBR>" ;

 return $summary ;

}



1;
