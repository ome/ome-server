# OME/Web/ProjectDataset.pm

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


=pod

=head1 Package OME::Web::ProjectDataset

Description: Generate HTML to describe & control datasets belonging to
the project specified in session.

=cut

package OME::Web::ProjectDataset;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Web::Validation;
use OME::Dataset;
use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Datasets in this project";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();
	my $project = $session->project();
	
	# This is not meant to take the place of OME::Web::Validation->isRedirectNecessary
	# It is explicit variable validity verification. Validation may eventually have other checks as well. This only needs these checks.
	if( not defined $project ) {
		$body .= OME::Web::Validation->ReloadHomeScript();
		return ("HTML",$body);
	}

	# cgi parameters to remove & switch datasets show up as ID=Remove and ID=Select
	# I need to reverse name, value pairs in the cgi hash to see if Remove or Select is in there
	my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;

# FIXME: Some validation is needed for these.
	# Àdo we need to remove a dataset?
	if( exists $revArgs{Remove} ) {
		my $dataset = $session->Factory()->loadObject("OME::Dataset",$revArgs{Remove});
		if( not defined $dataset ) {
			die "Could not load dataset ( ID = '".$revArgs{Remove}."' ). It has not been removed.<br>";
		}
		else {
			my $name = $dataset->name();
			# call a function in project to remove this dataset. don't forget to error check for session's dataset & save everything
	
			# this will add a script to reload OME::Home if it's necessary
			$body .= OME::Web::Validation->ReloadHomeScript();
#			$body .= "Dataset '$name' has been deleted.<br>";
			$body .= "I haven't implemented this feature yet.<br>";
		}
	}
	# Àdo we need to switch to another dataset?
	if( exists $revArgs{Select} ) {
		my $dataset = $session->Factory()->loadObject("OME::Dataset",$revArgs{Select})
			or die "Unable to load dataset ( ID = ".$revArgs{Select}." ). Action cancelled<br>";
		if( $project->doesDatasetBelong( $dataset ) ) {
		# does this dataset belong to the current project?
			$session->dataset($dataset);
			$session->writeObject();
	
			# this will add a script to reload OME::Home if it's necessary
			$body .= OME::Web::Validation->ReloadHomeScript();
			$body .= "Operation successful. Current dataset is: ".$session->dataset()->name()."<br>";

			# update titlebar
			$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		} else {
			die "Dataset '".$dataset->name."' does not belong to the current project.<br>";
		}
	}
	# Àdo we need to add a dataset to the project?
	if( defined $cgi->param('addDataset') ) {
		my $dataset = $project->addDatasetID( $cgi->param('addDatasetID') )
			or die ref $self." died when trying to add dataset (".$cgi->param('addDatasetID');
		$session->dataset($dataset);
		$session->writeObject();
		$project->writeObject();
		
		$body .= "Dataset '".$dataset->name()."' successfully added to this project and set to current dataset.<br>";
		# this will add a script to reload OME::Home if it's necessary
		$body .= OME::Web::Validation->ReloadHomeScript();

		# update titlebar
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
	}

	# display datasets that user owns 
	$body .= $self->print_form();

    return ('HTML',$body);
}

sub print_form {
	my $self = shift;
	my $session = $self->Session();
	my $project = $session->project();
	my @projectDatasets = $project->datasets();
	my $user    = $session->User()
		or die ref ($self)."->print_form() say: There is no user defined for this session.";
	my @groupDatasets = $session->Factory()->findObjects("OME::Dataset", 'group_id' =>  $user->group()->id() ) ; #OME::Dataset->search( group_id => $user->group()->id() );
	my %datasetList;
	foreach (@groupDatasets) {
	print STDERR "\n".$project->doesDatasetBelong($_)." ".$_->ID();
		if (not $project->doesDatasetBelong($_)) {
			$datasetList{$_->ID()} = $_->name();
		}
	}

	my $cgi = $self->CGI();
	my $text = '';
	my ($tableRows);
	
	$text .= "Project '".$project->name()."' contains ".(scalar @projectDatasets > 0 ? "these" : "no")." datasets.<br><br>";
	
	foreach (@projectDatasets) {
		$tableRows .= 
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					$_->name() ),
				$cgi->td( { -align=>'LEFT' },
					( $_->locked() == 0 ? 'Unlocked' : 'Locked' ) ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->submit( { -name  => $_->dataset_id() ,
					                -value => 'Remove' } ) ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->submit( { -name  => $_->dataset_id() ,
					                -value => 'Select' } ) ) );
	}
	
	$text .= $cgi->startform;
	$text .=
		$cgi->table( { -border=>1 },
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'CENTER' },
					'<b>Name</b>' ),
				$cgi->td( { -align=>'CENTER' },
					'<b>Locked/Unlocked</b>' ),
				$cgi->td( { -align=>'CENTER' },
					'<b>Remove</b>' ),
				$cgi->td( { -align=>'CENTER' },
					'<b>Make this the current dataset</b>' ) ),
			$tableRows )
		if(scalar @projectDatasets > 0 );
	
	$text .= "<br>".
		$cgi->popup_menu (
			-name => 'addDatasetID',
			-values => [keys %datasetList],
			-labels => \%datasetList
		).$cgi->submit (
			-name=>'addDataset',
			-value=>'add Dataset to this project')
		if (scalar keys %datasetList) > 0;


	$text .= $cgi->endform;
	$text .= '<br>What else would you like to do with these? Think about it. <a href="mailto:igg@nih.gov,bshughes@mit.edu,dcreager@mit.edu,siah@nih.gov,a_falconi_jobs@hotmail.com">email</a> the developers.';
	
	return $text;

}

1;