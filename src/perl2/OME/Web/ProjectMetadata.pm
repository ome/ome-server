# OME/Web/ProjectMetadata.pm

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

# JM 12-03-03
package OME::Web::ProjectMetadata;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Web::Validation;
use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Project Metadata";
}

# FIXME: Add some method of doing error check on Forms. Obvious choices are javascript or func in this package.

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();
	my $project = $session->project()
		or die "Project is not defined for the session.\n";

	# figure out what to do: save & print info or just print?
	if( $cgi->param('Save')) {
# FIXME: Some validation is needed here
	my $projectname=cleaning($cgi->param('name'));
	return ('HTML',"<b>Please enter a name for your project.</b>") unless $projectname;
	if ($project->name() ne $cgi->param('name')){
         my @nameprojects=$session->Factory()->findObjects("OME::Project",'name'=>$projectname);
         #my @nameprojects=OME::Project->search(name=>$projectname);
	   return ('HTML',"<b>This name is already used. Please enter a new name for your project.</b>") unless scalar(@nameprojects)==0;
      }

		
		my $reloadTitleBar = ($project->name() eq $cgi->param('name') ? undef : 1);
		# change stuff.
		$project->name( $cgi->param('name') );
		$project->description( $cgi->param('description') );

		$project->writeObject();
		$body .= "Save successful<br>";
		# javascript to reload titlebar
		$body .= "<script>top.title.location.href = top.title.location.href;</script>"
			if $reloadTitleBar;
		# this will add a script to reload OME::Home if it's necessary
		$body .= OME::Web::Validation->ReloadHomeScript();
	}
	# print info & form
	$body .= $self->print_form();

    return ('HTML',$body);
}

sub print_form {
	my $self = shift;
	my $cgi = $self->CGI();
	my $project = $self->Session()->project();
	
	my $text = '';

	$text .= $cgi->startform;
	$text .= "<CENTER>".$cgi->submit (-name=>'Save',-value=>'Save Changes')."</CENTER>";

	$text .= 
		$cgi->table(
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'ID:' ),
				$cgi->td( { -align=>'LEFT' },
					$project->project_id() ) ),
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'*Name:' ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->textfield(-name=>'name', -size=>32, -default=>$project->name()) ) ),
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'Description:' ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->textarea(-name=>'description', -columns=>32, -rows=>3, -default=>$project->description() ))),
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'Owner:' ),
				$cgi->td( { -align=>'LEFT' },
					$project->owner()->firstname()." ".$project->owner()->lastname()." (<a href='mailto:".$project->owner()->email()."'>".$project->owner()->email()."</a>)" ) ),
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'Group:' ),
				$cgi->td( { -align=>'LEFT' },
					$project->group()->name() ) )
		);
			
	$text .= $cgi->endform;
	$text .= '<br><font size="-1">An asterick (*) denotes a required field</font>';
	return $text;
}

#-----------------
# PRIVATE METHODS
#------------------


sub cleaning{
		  my ($string)=@_;
		 chomp($string);
 $string=~ s/^\s*(.*\S)\s*/$1/;
 return $string;

}



1;