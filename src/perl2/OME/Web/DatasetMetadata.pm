# OME/Web/DatasetMetadata.pm

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


package OME::Web::DatasetMetadata;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::Web;
@ISA = ("OME::Web");

sub getPageTitle {
	return "Open Microscopy Environment - Dataset Metadata";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();

	# figure out what to do: save & print info or just print?
	if( $cgi->param('Save')) {

		my $dataset = $session->dataset();
		if (!defined $dataset) {
			# we got problems
			$body .= "Problem: There is not a current dataset defined in session.<br>";
# possible bug: the link in the line below is intended to reload the root window (OME::Home)
# it will not do it in all conditions. When a better solution is found, implement the new
# solution everywhere this current solution is used.
			$body .= "Solutions: Define a dataset. Clicking <a href=\"javascript: top.location.href = top.location.href\">here</a> should take you where you need to go.";
		}
		else {
# FIXME: Better validation is needed
			if(not ($session->User()->experimenter_id() eq $dataset->owner()->experimenter_id()) ) {
				$body .= "You do not have permission to modify this.";
				return ('HTML',$body);
			}
			my $reloadTitleBar = ($dataset->name() eq $cgi->param('name') ? undef : 1);
			# change stuff.
			$dataset->name( $cgi->param('name') );
			$dataset->description( $cgi->param('description') );

			$dataset->writeObject();
			# javascript to reload titlebar
			$body .= "<script>top.title.location.href = top.title.location.href;</script>"
				if defined $reloadTitleBar;
			$body .= "Save successful<br>";
		}
	}
	# print info & form
	$body .= $self->print_stuff();

    return ('HTML',$body);
}

sub print_stuff {
	my $self = shift;
	my $cgi = $self->CGI();
	my $dataset = $self->Session()->dataset();
	
	my $text = '';

	$text .= "\n".$cgi->startform;
	$text .= "<CENTER>\n	".$cgi->submit (-name=>'Save',-value=>'Save Changes')."\n</CENTER>\n";

	$text .= 
		$cgi->table(
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'ID:' ),
				$cgi->td( { -align=>'LEFT' },
					$dataset->dataset_id() ) ),
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'Name:' ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->textfield(-name=>'name', -size=>32, -default=>$dataset->name()) ) ),
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'Description:' ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->textarea(-name=>'description', -columns=>32, -rows=>3, -default=>$dataset->description() ))),
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'Locked/Unlocked:' ),
				$cgi->td( { -align=>'LEFT' },
					($dataset->locked() ? "locked" : "unlocked"))),
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'Owner:' ),
				$cgi->td( { -align=>'LEFT' },
					$dataset->owner()->firstname()." ".$dataset->owner()->lastname()." <a href='mailto:".$dataset->owner()->email()."'>".$dataset->owner()->email()."</a>" ) ),
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'Group:' ),
				$cgi->td( { -align=>'LEFT' },
					$dataset->group()->name() ) )
		);
			
	$text .= $cgi->endform."\n";
	return $text;
}

1;