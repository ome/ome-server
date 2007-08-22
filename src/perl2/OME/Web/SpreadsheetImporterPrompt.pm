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
use Log::Agent;

use OME;
use OME::Util::Annotate::SpreadsheetReader;

use base qw(OME::Web::Authenticated);

sub getPageTitle {
	return "OME: Annotate Images";
}

{
	my $menu_text = "Annotate Images";
	sub getMenuText { return $menu_text }
}


sub getAuthenticatedTemplate {

    return OME::Web::TemplateManager->getActionTemplate('SpreadsheetImporterPrompt.tmpl');
}

=head2 getLocation
=cut

sub getLocation {
	my $self = shift;
	my $template = OME::Web::TemplateManager->getLocationTemplate('SpreadsheetImporterPrompt.tmpl');
	return $template->output();
}

sub getPageBody {
	my $self = shift;
	my $tmpl = shift;
	my $q = $self->CGI();
	my $session= $self->Session();
	my $factory = $session->Factory();
	my $output;
    
    if ($q->param( 'Annotate' )) {
    	my $fileToParse = $q->param( 'fileToParse' );
		
		if (not $fileToParse) {
			$output .= $q->p({class => 'ome_error'}, "Choose a File -- no file selected !\n")
		} else  {
			my $tmpFile = $session->getTemporaryFilename('import','xls');
			open TMP, ">$tmpFile";
			while (<$fileToParse>) {
				print TMP $_;
			}
			close TMP;
			$fileToParse= $tmpFile;
	
			my $noop;
			if ($q->param( 'noop' )) {
				$noop = 1;
			} else {
				$noop = 0;
			}

			$output .= $q->p({class => 'ome_error'}, "Filepath $fileToParse is invalid.\n")
				unless (-f $fileToParse);
				
			if (-f $fileToParse) {
				my $results = OME::Util::Annotate::SpreadsheetReader->processFile( $fileToParse, $noop);
				if (!ref $results) {
					$output .= "Error annotating: <br><br>";
					$output .= "<font color='red'>".$results."</font>";
				} else {
					$output .= "Finished annotating. ";
					$output .= $self->printSpreadsheetAnnotationResultsHTML ($results);
				}
				unlink $fileToParse;
			}
		}
	}
    
    # populate the template
	$tmpl->param( 'Output' => $output );
	
	my $html =
		$q->startform( { -name => 'primary', 
				 -enctype => 'multipart/form-data' } ).
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
	my $global_mex     = $Results->{global_mex};
	my @ERRORoutput    = @{$Results->{ERRORoutput}};
	my @newProjs       = @{$Results->{newProjs}};
	my @newDatasets    = @{$Results->{newDatasets}};
	my $newProjDataset = $Results->{newProjDatast};
	my @newCGs         = @{$Results->{newCGs}};
	my $newCategories  = $Results->{newCategories};
	my $newGlobalSTSE  = $Results->{newGlobalSTSE};
	my $images         = $Results->{images};
	
	my $output = "<p>A full record of successfully imported meta-data can be found here: ".$self->Renderer()->render( $global_mex, 'ref' )."</p>";

	if (scalar @ERRORoutput) {
		foreach (@ERRORoutput) {
			$output .= "<font color='red'>$_</font><br>\n";
		}
	}	
	if (scalar @newProjs) {
		$output .= "New Projects:<br>\n";
		$output .= '&nbsp&nbsp&nbsp<a href="'.OME::Web->getObjDetailURL($_).'">'.$_->name()."</a><br>\n"
			foreach (sort {$a->name() cmp $b->name()} @newProjs);
		$output .= "<br>\n"; # spacing
	}
	if (scalar (@newDatasets)) {
		$output .= "New Datasets:<br>\n";
		$output .= '&nbsp&nbsp&nbsp<a href="'.OME::Web->getObjDetailURL($_).'">'.$_->name()."</a><br>\n"
			foreach (sort {$a->name() cmp $b->name()} @newDatasets);
		$output .= "<br>\n"; # spacing
	}
	if (scalar keys %$newProjDataset) {
		$output .= "New Dataset/Project Associations:<br>\n";
		foreach my $pn (sort keys %$newProjDataset) {
			my $project = $factory->findObject ('OME::Project', { name => $pn });
			$output .= '&nbsp&nbsp&nbsp<a href="'.OME::Web->getObjDetailURL($project).'">'.$pn."</a><br>\n";
			foreach my $dn (sort keys %{$newProjDataset->{$pn}}) {
				my $dataset= $factory->findObject ('OME::Dataset', { name => $dn});
				$output .= '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp\\_<a href="'.OME::Web->getObjDetailURL($dataset).'">'.$dn."</a><br>\n";
			}
		}
		$output .= "<br>\n"; # spacing
	}
	if (scalar @newCGs) {
		$output .= "New Category Groups:<br>\n";
		$output .= '&nbsp&nbsp&nbsp<a href="'.OME::Web->getObjDetailURL($_).'">'.$_->Name()."</a><br>\n"
			foreach (sort {$a->Name() cmp $b->Name()} @newCGs);
		$output .= "<br>\n"; # spacing
	}
	if (scalar keys %$newCategories) {
		$output .= "New Categories:<br>\n";
		foreach my $CGName (sort keys %$newCategories) {
			my $CG = $factory->findObject ('@CategoryGroup', { Name => $CGName });
			$output .= '&nbsp&nbsp&nbsp<a href="'.OME::Web->getObjDetailURL($CG).'">'.$CGName."</a><br>\n";
			foreach my $categoryName (sort keys %{$newCategories->{$CGName}}) {
				my $category = $factory->findObject ('@Category', { Name => $categoryName, CategoryGroup => $CG });
				$output .= '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp\\_<a href="'.OME::Web->getObjDetailURL($category).'">'.$categoryName."</a><br>/n";
			}
		}
		$output .= "<br>\n"; # spacing
	}
	if (scalar keys %$newGlobalSTSE) {
		$output .= "New Global Attributes:<br>";
		foreach my $STName (sort keys %$newGlobalSTSE) {
			foreach my $SEName (sort keys %{$newGlobalSTSE->{$STName}}) {
				$output .= "&nbsp&nbsp $STName:$SEName -> `".$newGlobalSTSE->{$STName}->{$SEName}."`<br>\n";
			}
		}
		$output .= "<br>\n"; # spacing
	}
	if (scalar keys %$images) {
		foreach my $imageIdentifier (sort keys %$images) {
			my $image = $images->{$imageIdentifier};
			$output .= '<img src="'. OME::Tasks::ImageManager->getThumbURL($image->{"Image"}).'">';
			$output .= "  (Spreadsheet Identifier: '". $imageIdentifier."' )<br>\n";
			delete $image->{"Image"};

			# specialised Rendering for Dataset association
			if (exists $image->{"Dataset"}) {
				$output .= '&nbsp&nbsp&nbsp&nbsp&nbsp  Dataset: <a href="'.OME::Web->getObjDetailURL($image->{"Dataset"}).'">'.$image->{"Dataset"}->name()."</a><br>\n";
				delete $image->{"Dataset"};
			}
			
			# render attributes
			if (scalar keys %$image) {
				my $attributesMsg .= "&nbsp&nbsp&nbsp&nbsp&nbsp  Attributes:<br>\n";
				my $haveAttributes = 0;
				foreach my $key (sort keys %$image) {
					if( $key =~ m/^ST:(.*)$/ ) {
						$haveAttributes = 1;
						my $STName = $1;
						my $attribute = $factory->findObject('@'."$STName", {id => $image->{$key}->id()});
						if (defined $attribute) {
							$attributesMsg .= '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp\\_ <a href="'.OME::Web->getObjDetailURL($attribute).'">'.$STName."</a>".
								' : '.$image->{$key}->id()."<br>\n";
						} else {
							# the attribute can't be found because it was not written to the database (since --noop was selected)
							$attributesMsg .= '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp\\_ '.$STName." : ".$image->{$key}->id()."<br>\n";
						}
					}
				}
				$output .= $attributesMsg if $haveAttributes;
			}
			
			# render Category Group/Cateogrizations
			if (scalar keys %$image) {
				my $classificationMsg .= "&nbsp&nbsp&nbsp&nbsp&nbsp  Classifications:<br>\n";
				my $haveClassifications = 0;
				foreach my $key (sort keys %$image) {
					unless( $key =~ m/^ST:(.*)$/ ) {
						$haveClassifications = 1;
						my $CG = $factory->findObject('@CategoryGroup', {Name => $key});
						if (defined $CG) {
							$classificationMsg .= '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp\\_ <a href="'.OME::Web->getObjDetailURL($CG).'">'.$key."</a>".
								' : <ahref='.OME::Web->getObjDetailURL($image->{$key}).'">'.$image->{$key}->Name()."</a><br>\n";
						} else {
							# the classification can't be found because it was not written to the database (since --noop was selected)
							$classificationMsg .= '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp\\_ '.$key." : ".$image->{$key}->Name()."<br>\n";
						}
					}
				}
				$output .= $classificationMsg if $haveClassifications; 
			}
			$output .= "<br>\n"; # spacing
		}
	}
	return $output;
}

1;
