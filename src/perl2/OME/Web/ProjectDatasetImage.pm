# OME/Web/ProjectDatasetImage.pm

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


package OME::Web::ProjectDatasetImage;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Web::Validation;
use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Make Dataset from existing images";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();
	my $project =$session->project();
	if( not defined $project ) {
		$body .= OME::Web::Validation->ReloadHomeScript();
		return ("HTML",$body);
     }
     if ($cgi->param('Create')){
        my $datasetname=$cgi->param('newDataset');
        my @addImages=$cgi->param('ListImage');
	  return ('HTML',"<b>Please enter a name for your dataset.</b>") unless $datasetname;
        my @namedatasets=OME::Dataset->search(name=>$datasetname);
	  return ('HTML',"<b>This name is already used. Please enter a new name for your dataset.</b>") unless scalar(@namedatasets)==0;
	  

	 return ('HTML',"<b>No image selected. Please try again </b>") unless scalar(@addImages)>0;
	
	  my $dataset = $project->newDataset($cgi->param('newDataset'), $cgi->param('description') );
	  die ref($self)."->create:  Could not create dataset '".$cgi->param('newDataset')."'\n" unless defined $dataset;
	  if ($dataset){
		$dataset->writeObject();
            foreach (@addImages){
              my $image=$dataset->addImageID($_);
		}
		$session->dataset($dataset);
		$session->writeObject();
		$body.="Dataset Created";
		$body .= OME::Web::Validation->ReloadHomeScript();
       	$body .= "<script>top.title.location.href = top.title.location.href;</script>";
	 }			




    }else{
	$body .= $self->print_form();
    }
    return ('HTML',$body);

	
}




#--------------------

sub print_form {
 my $self=shift;
 my $cgi=$self->CGI();
 my $text="";
 my $textarea="";
 my $checkbox="";
 my $session=$self->Session();
 my $user=$self->Session()->User() 
	or die ref ($self)."->print_form() say: There is no user defined for this session.";
 my @groupImages = $session->Factory()->findObjects("OME::Image", 'group_id' =>  $user->group()->group_id() ) ; #OME::Dataset->search( group_id => $user->group()->id() );
	
 if (scalar(@groupImages)>0){
   
   $textarea.=print_textarea($cgi);
   $checkbox.=print_checkbox($cgi,\@groupImages);
   #format output
   $text.=$cgi->h3("Create a new dataset from existing images");
   $text.=$cgi->startform;
   $text .= "<CENTER>".$cgi->submit (-name=>'Create',-value=>'Create a new dataset')."</CENTER>";
   $text.=$textarea;
   $text.=$cgi->h3("Please select images in the list below.");
   $text.=$checkbox;
   $text.$cgi->endform;
   $text .= '<br><font size="-1">An asterick (*) denotes a required field</font>';

 }




 return $text;
}


sub print_textarea{
 my ($cgi)=@_;
 my $text="";
 $text .= $cgi->table(
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					  '*Name:'),
				$cgi->td( { -align=>'LEFT' },
					$cgi->textfield(-name=>'newDataset', -size=>32)
					   )
				  ),
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'RIGHT' },
					'Description:' ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->textarea(-name=>'description', -columns=>32, -rows=>3)
					   )
				   )
			 );
	
return $text;

}


sub print_checkbox{
 my ($cgi,$ref)=@_;
 my %List=();
 my %ReverseList=();
 my $text="";
 my @names=();
 # necessary because not control before import process!
 foreach (@$ref){
   $ReverseList{$_->name()}=$_->image_id();
   # push(@names,$_->name());
   
 }
 %List= reverse %ReverseList;
 
foreach (keys %List){
  push(@names,$_);
}
 $text.=$cgi->checkbox_group(-name=>'ListImage',
				     -values=>\@names,
				     -linebreak=>'true',
				     -default=>$names[0],
				     -labels=>\%List);

 return $text;
}





1;
