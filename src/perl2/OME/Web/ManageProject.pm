# OME/Web/ManageProject.pm

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
# Written by:    JM Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::ManageProject;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;

use OME::Tasks::ProjectManager;
use OME::Web::Helper::HTMLFormat;
use OME::Web::ProjectTable;


use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Project Manager";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	
	my $session = $self->Session();
	my $currentproject=$session->project();
	my $projectManager=new OME::Tasks::ProjectManager();
	my $htmlFormat= new OME::Web::Helper::HTMLFormat;

	my $body = $cgi->p({class => 'ome_title'}, 'My projects');

	# Projects that were selected
	my @selected = $cgi->param('selected');

	# Action field propagation
	my $action = $cgi->param('action');

	if ($action eq 'Switch To') {
		# Warning
		if (scalar(@selected) > 1) {
			$body .= $cgi->p({class => 'ome_error'}, 
				"WARNING: Multiple projects chosen, selecting first choice ID $selected[0].");
		}
		
		# Action
		$projectManager->switch($selected[0]);
		
		$body .= $cgi->p({-class => 'ome_info'}, "Selected project $selected[0]."); 

		# Top frame refresh
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
	}
	
	$body .= $self->print_form($projectManager);

    return ('HTML',$body);
}

#####################
# PRIVATE METHODS	#
#####################

sub print_form {
	my ($self, $p_manager) = @_;
	my $t_generator = new OME::Web::ProjectTable;

	my $html = $t_generator->getTable( {
			options_row => ["Switch To"],
			select_column => 1,
		},
		$p_manager->getUserProjects()
	);

	return $html;
}

sub format_datasetList{
	my ($htmlFormat,$dataname,$ref,$cgi)=@_;
 	my $html="";
 	if (defined $dataname){
 		$html.="<P>Your current dataset is: <B>".$dataname."</B></P>";
 	}else{
		$html.="No dataset defined for this project";
	 }
 	if (scalar(@$ref)>1){
		my %datasetList= map {$_->id() => $_->name()} @$ref;
		$html.="<p> If you want to switch, please choose a dataset in the list below.</p>";
		$html.=$cgi->startform;
		$html.=$htmlFormat->dropDownTable("newdataset",\%datasetList,"execute","Switch Dataset");			
		$html .= $cgi->endform;

 	}
 	return $html;
}

1;
