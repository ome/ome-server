# OME/Web/SpreadsheetImporterPrompt.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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
# Written by:    Arpun Nagaraja <arpun@mit.edu>
#                Tom Macura <tmacura@nih.gov> wrote printSpreadsheetAnnotationResultsHTML()
#-------------------------------------------------------------------------------

package OME::Web::SpreadsheetImporterPrompt;

use strict;
use Carp 'cluck';
use vars qw($VERSION);
use OME::Util::Annotate::SpreadsheetReader;

use base qw(OME::Web);

sub getPageTitle {
	return "OME: Annotate Images";
}

{
	my $menu_text = "Annotate Images";
	sub getMenuText { return $menu_text }
}

sub getPageBody {
	my $self = shift;
	my $q = $self->CGI();
	my $session= $self->Session();
	my $factory = $session->Factory();
	my $output;
    
    if ($q->param( 'Annotate' )) {
    	my $fileToParse = $q->param( 'fileToParse' );
    	die "File $fileToParse is invalid\n" unless( $fileToParse );

		$output .= $q->p({class => 'ome_error'}, "Filepath $fileToParse is invalid.\n")
			unless (-f $fileToParse);
			
		if (-f $fileToParse) {
			my $results = OME::Util::Annotate::SpreadsheetReader->processFile( $fileToParse );
			if (!ref $results) {
				$output .= "Error annotating: <br><br>";
				$output .= "<font color='red'>".$results."</font>";
			} else {
				$output .= "Finished annotating: <br><br>";
				$output .= OME::Web::SpreadsheetImporterPrompt->printSpreadsheetAnnotationResultsHTML ($results);
			}
		}
	}
    
    # Load & populate the template
	my $tmpl_dir = $self->actionTemplateDir();
	my $tmpl = HTML::Template->new( filename => "SpreadsheetImporterPrompt.tmpl",
									path => $tmpl_dir,
	                                case_sensitive => 1 );
	
	$tmpl->param( 'Output' => $output );
	
	my $html =
		$q->startform( { -name => 'primary' } ).
		$tmpl->output().
		$q->endform();

	return ('HTML',$html);
}


# prints a "Results Hash" in a command-line readable format.
sub printSpreadsheetAnnotationResultsHTML {
	my ($self, $Results) = @_;
	my $session = $self->Session();	
	my $factory = $session->Factory();
	
	die "second input to printResultsHTML is expected to be a hash"	if (ref $Results ne "HASH");	
	my @ERRORoutput    = @{$Results->{ERRORoutput}};
	my @newProjs       = @{$Results->{newProjs}};
	my @newDatasets    = @{$Results->{newDatasets}};
	my $newProjDataset = $Results->{newProjDatast};
	my @newCGs         = @{$Results->{newCGs}};
	my $newCategories  = $Results->{newCategories};
	my $newGlobalSTSE  = $Results->{newGlobalSTSE};
	my $images         = $Results->{images};
	
	my $output;
	if (scalar @ERRORoutput) {
		foreach (@ERRORoutput) {
			$output .= "<font color='red'>$_</font><br>";
		}
	}	
	if (scalar @newProjs) {
		$output .= "New Projects:<br>";
		$output .= '&nbsp&nbsp&nbsp<a href="'.OME::Web->getObjDetailURL($_).'">'.$_->name().'</a><br>'
			foreach (sort {$a->name() cmp $b->name()} @newProjs);
		$output .= "<br>"; # spacing
	}
	if (scalar (@newDatasets)) {
		$output .= "New Datasets:<br>";
		$output .= '&nbsp&nbsp&nbsp<a href="'.OME::Web->getObjDetailURL($_).'">'.$_->name().'</a><br>'
			foreach (sort {$a->name() cmp $b->name()} @newDatasets);
		$output .= "<br>"; # spacing
	}
	if (scalar keys %$newProjDataset) {
		$output .= "New Dataset/Project Associations: <br>";
		foreach my $pn (sort keys %$newProjDataset) {
			my $project = $factory->findObject ('OME::Project', { name => $pn });
			$output .= '&nbsp&nbsp&nbsp<a href="'.OME::Web->getObjDetailURL($project).'">'.$pn.'</a><br>';
			foreach my $dn (sort keys %{$newProjDataset->{$pn}}) {
				my $dataset= $factory->findObject ('OME::Dataset', { name => $dn});
				$output .= '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp\\_<a href="'.OME::Web->getObjDetailURL($dataset).'">'.$dn.'</a><br>';
			}
		}
		$output .= "<br>"; # spacing
	}
	if (scalar @newCGs) {
		$output .= "New Category Groups:<br>";
		$output .= '&nbsp&nbsp&nbsp<a href="'.OME::Web->getObjDetailURL($_).'">'.$_->Name().'</a><br>'
			foreach (sort {$a->Name() cmp $b->Name()} @newCGs);
		$output .= "<br>"; # spacing
	}
	if (scalar keys %$newCategories) {
		$output .= "New Categories:<br>";
		foreach my $CGName (sort keys %$newCategories) {
			my $CG = $factory->findObject ('@CategoryGroup', { Name => $CGName });
			$output .= '&nbsp&nbsp&nbsp<a href="'.OME::Web->getObjDetailURL($CG).'">'.$CGName.'</a><br>';
			foreach my $categoryName (sort keys %{$newCategories->{$CGName}}) {
				my $category = $factory->findObject ('@Category', { Name => $categoryName, CategoryGroup => $CG });
				$output .= '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp\\_<a href="'.OME::Web->getObjDetailURL($category).'">'.$categoryName.'</a><br>';
			}
		}
		$output .= "<br>"; # spacing
	}
	if (scalar keys %$newGlobalSTSE) {
		$output .= "New Global Attributes:<br>";
		foreach my $STName (sort keys %$newGlobalSTSE) {
			foreach my $SEName (sort keys %{$newGlobalSTSE->{$STName}}) {
				$output .= "&nbsp&nbsp $STName:$SEName -> `".$newGlobalSTSE->{$STName}->{$SEName}."`<br>";
			}
		}
		$output .= "<br>"; # spacing
	}

	if (scalar keys %$images) {
		foreach my $imageIdentifier (sort keys %$images) {
			my $image = $images->{$imageIdentifier};
			$output .= '<img src="'. OME::Tasks::ImageManager->getThumbURL($image->{"Image"}).'">';
			$output .= "  (Spreadsheet Identifier: '". $imageIdentifier."' )<br>";
			delete $image->{"Image"};

			# specialised Rendering for Dataset association
			if (exists $image->{"Dataset"}) {
				$output .= '&nbsp&nbsp&nbsp&nbsp&nbsp  Dataset: <a href="'.OME::Web->getObjDetailURL($image->{"Dataset"}).'">'.$image->{"Dataset"}->name().'</a><br>';
				delete $image->{"Dataset"};
			}
			
			# generic rendering e.g. for Category Group/Cateogrizations
			if (scalar keys %$image) {
				$output .= '&nbsp&nbsp&nbsp&nbsp&nbsp  Classifications:<br>';
				foreach my $key (sort keys %$image) {
					my $CG = $factory->findObject ('@CategoryGroup', { Name => $key });
					$output .= '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp\\_ <a href="'.OME::Web->getObjDetailURL($CG).'">'.$key."</a>".
					' : <a href='.OME::Web->getObjDetailURL($image->{$key}).'">'.$image->{$key}->Name().'</a><br>';
				}
			}
			$output .= "<br>"; # spacing
		}
	}
	return $output;
}

1;