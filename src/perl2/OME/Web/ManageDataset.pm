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
use Data::Dumper;

use OME::Tasks::DatasetManager;
use OME::Web::Helper::JScriptFormat;
use OME::Web::Table;

use base qw{ OME::Web };
sub getPageTitle {
	return "Open Microscopy Environment - Dataset Manager";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $session = $self->Session();
	my $datasetManager=new OME::Tasks::DatasetManager($session);
	my $jscriptFormat=new OME::Web::Helper::JScriptFormat;

	my $body = "";
	$body.= $jscriptFormat->popUpDataset();	

	my @selected = $cgi->param('selected');
	my @rel_selected = $cgi->param('rel_selected');
	
	$body .= $cgi->p({-class => 'ome_title'}, 'My Datasets');

	if ($cgi->param('Select')){
		# Warning
		if (scalar(@selected) > 1) {
			$body .= $cgi->p({class => 'ome_error'}, 
				"WARNING: Multiple datasets chosen, selecting first choice ID $selected[0].");
		}

		# Action
		$datasetManager->switch($selected[0]);

		# Data
		$body .= $cgi->p({-class => 'ome_info'}, "Selected dataset $selected[0].");
		
		# Refresh top frame
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
	}elsif ($cgi->param('Remove')){
		# Action
		my $to_remove = {};

		foreach (@rel_selected) {  # Slightly arcane but it works
			my ($dataset, $project) = split(/,/, $_);
			push(@{$to_remove->{$dataset}}, $project);
		}

		$datasetManager->remove($to_remove);
		
		# Data
		$body .= $cgi->p({-class => 'ome_info'}, "Removed relation(s) @rel_selected [DatasetID, ProjectID].");

		# Refresh top frame
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
	}elsif ($cgi->param('Delete')){
		# Action
		foreach (@selected) { $datasetManager->delete($_) }
		
		# Data
		$body .= $cgi->p({-class => 'ome_info'}, "Deleted dataset(s) @selected.");
		
		# Refresh top frame
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
	}

	$body .= $self->displayDatasets();

	return ('HTML',$body);
}


#------------------
#PRIVATE METHODS
#------------------

sub displayDatasets {
	my $self = shift;
	my $t_generator = new OME::Web::Table;
	my $cgi = $self->CGI();;
	my $factory = $self->Session()->Factory();
	
	# Gen our "Datasets in Project" table
	my $html = $t_generator->getTable( {
			type => 'dataset',
			filters => [ ["owner_id", $self->Session()->User()->id()] ],
			options_row => ["Switch To", "Remove", "Delete"],
			relations => 1,
		}
	);

	return $html;
}


1;
