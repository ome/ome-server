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

Description: Generate HTML describing & linking to datasets belonging to
a the project specified in session.

=cut

package OME::Web::ProjectDataset;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::Web;
@ISA = ("OME::Web");

sub getPageTitle {
	return "Open Microscopy Environment - Datasets in this project";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();
	
	# do we need to do anything?
	# ... check for switch datasets in cgi params, switch, update title bar, display message

	# display datasets that user owns 
	$body .= $self->print_form();
	

    return ('HTML',$body);
}

sub print_form {
	my $self = shift;
	my $session = $self->Session();
	my $project = $session->project();
	my @projectDatasets = $project->datasets();
	my $cgi = $self->CGI();
	my $text = '';
	my ($tableRows);
	
	$text .= "Project '".$project->name()."' contains these datasets.<br><br>";
	
	foreach (@projectDatasets) {
		$tableRows .= 
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					$_->name() ),
				$cgi->td( { -align=>'LEFT' },
					( $_->locked() == 0 ? 'Unlocked' : 'Locked' ) ),
				$cgi->td( { -align=>'LEFT' },
					'<font color=red>[button goes here]</font>'),
				$cgi->td( { -align=>'LEFT' },
					'<font color=red>[button goes here]</font>'));
	}
	
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
			$tableRows );
	
	$text .= '<p><font color=red>[Something to add datasets to this projects should go here.]</font><br>Which datasets should the user be able to add? Ones in this user\'s group that aren\'t already in this project? Should they go in a popup? the popup could get might big.</p>';
	$text .= '<br>What else would you like to do with these? Think about it. <a href="mailto:igg@nih.gov,bshughes@mit.edu,dcreager@mit.edu,siah@nih.gov,a_falconi_jobs@hotmail.com">email</a> the developers.';
	
	return $text;

}

1;