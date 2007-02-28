# OME/Web/Wizards/ImportAndAnnotateImages.pm
# OME local image browser and importer for the OME Web interface.

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------

package OME::Web::Wizards::ImportAndAnnotateImages;

#*********
#********* INCLUDES
#*********

use strict;
use warnings;
use vars qw($VERSION);
use Carp;
use File::Spec;

# OME Modules
use OME;
use OME::Tasks::DatasetManager;
use OME::Tasks::ImageTasks;
use OME::Fork;
use OME::Util::Annotate::SpreadsheetWriter;
use OME::Util::Annotate::SpreadsheetReader;


#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web::Authenticated);

use constant UNIX_STYLE => 1;
use constant FTP_STYLE  => 2;

my $STYLE = FTP_STYLE;

#*********
#********* PUBLIC METHODS
#*********

# Override's OME::Web
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new(@_);
	
	# This is here to fix mod_perl/Apache keep alive dispatch. [Bug #174]
	$self->{'_headers'} = {'-Connection' => 'Close'};

	return $self;
}

# Override's OME::Web
sub getPageTitle {
	return "Open Microscopy Environment - Wizard: Import and Annotate Images ";
}

=head2 getLocation
=cut

sub getLocation {
	my $self = shift;
	my $template = OME::Web::TemplateManager->getLocationTemplate('ImportAndAnnotateImages.tmpl');
	return $template->output();
}

# Override's OME::Web
{
	my $menu_text = "Import and Annotate Images";

	sub getMenuText { return $menu_text }
}

sub getAuthenticatedTemplate {

    return OME::Web::TemplateManager->getActionTemplate('ImportAndAnnotateImages.tmpl');
}

# Override's OME::Web
sub getPageBody {
	my $self = shift;
	my $tmpl = shift;
	my $q = $self->CGI();
	my $session= $self->Session();
	my $factory = $session->Factory();
	
	if ($q->param('action') && ( $q->param('action') eq 'UploadImportAnnotate') ) {
		my @warningMsgs;
		
		# Write the uploaded zip file to disk.
    	my $zipFileName = $q->param( 'zipFile' );
    	my $zipFileHandle = $q->upload( 'zipFile' );
		my $tmpFile = $session->getTemporaryFilename('UploadImportAnnotate', 'zip');
		open (OUTFILE, ">", $tmpFile);
		my $buffer;
		while (my $bytesread=read($zipFileHandle,$buffer,1024)) {
			print OUTFILE $buffer;
		}
		close OUTFILE;
		
		# Unzip the file
		my $tmpDir = $session->getScratchDir( $zipFileName, 'zip')
			or die "Couldn't make a temporary directory to upzip the file.";
		my $targetDir = "$tmpDir/$zipFileName";
		mkdir $targetDir
			or die "Couldn't make a temporary directory to upzip the file.";
		`unzip $tmpFile -d $targetDir`;
		
		# Identify the name of the directory inside the tmp dir. 
		opendir( ZIP_DIR, $targetDir )
			or die "Could not open the temporary directory $targetDir. Import failed.";
		my @entries = grep( m/^[^\.]/, readdir( ZIP_DIR ) );
		# On my OS X machine, an extraneous directory called '__MACOSX' is
		# created in the target directory after the unzip command is called.
		# This directory dissapears on its own before I can manually inspect
		# it, but its presence here causes problems. So, we'll screen it out.
		@entries = grep( !m/^__MACOSX/, @entries );
		closedir ZIP_DIR;
		my @fileEntries = grep( -f "$targetDir/$_", @entries );
		my @dirEntries  = grep( -d "$targetDir/$_", @entries );
		my $exp_dir_name = $dirEntries[0];
		my $cg_name      = $exp_dir_name;
		my $exp_dir_path = File::Spec->rel2abs( $exp_dir_name, $targetDir );

		# Error checking
		return( 'HTML', $self->getForm($tmpl, 
			"More than one master directory was placed in the zip file: ".join( ", ", @dirEntries ).". Cannot interpret. Halting import and annotation."
		) ) if( scalar( @dirEntries ) > 1 );
		push( @warningMsgs, 
			scalar( @fileEntries )." files found in the zip file alongside the master directory. These will be ignored."
		) if( scalar( @fileEntries ) > 0 );		
		
		# Identify the names of the subdirectories that will become categories
		opendir( EXP_DIR, $exp_dir_path )
			or die "Could not open the temporary directory $exp_dir_path. Import failed.";
		@entries = grep( m/^[^\.]/, readdir( EXP_DIR ) );
		closedir EXP_DIR;
		@fileEntries = grep( -f "$exp_dir_path/$_", @entries );
		my @catNames = grep( -d "$exp_dir_path/$_", @entries );

		# Error checking
		push( @warningMsgs, 
			scalar( @fileEntries )." files found directly under the master directory. These will be ignored."
		) if( scalar( @fileEntries ) > 0 );
		
		# Use the ome commander utilities to make a CGC spreadsheet
		chdir( $tmpDir )
			or die "Couldn't change directories to $tmpDir";
		my $spreadSheetPath = $session->getTemporaryFilename('UploadImportAnnotate', 'tsv');
		my %categoriesAndPaths = map{ $_ => "$zipFileName/$cg_name/$_/*" } @catNames;
		OME::Util::Annotate::SpreadsheetWriter->processFile( 
			$spreadSheetPath, 
			{
				ColumnName => "'".$cg_name."'",
				%categoriesAndPaths
			},
			'_RelativePaths'
		) or die "Could not make a spreadsheet to store the annotations.\n\ttmpDir: $tmpDir\n\tspreadSheetPath: $spreadSheetPath\n\tCategories:\n\t\t".
			join( "\n\t\t", map( $_." => ".$categoriesAndPaths{ $_ }, keys %categoriesAndPaths ) )."\n";

		# Identify the image files in the unzipped directory. 
		my @catRelPaths = map( "$zipFileName/$cg_name/$_", @catNames );
		my @imagePaths;
		foreach my $catPath ( @catRelPaths ) {
			opendir( CAT_DIR, $catPath ) or die "Could not open directory $catPath";
			my @entries = grep( m/^[^\.]/, readdir( CAT_DIR ) );
			closedir CAT_DIR;
			push( @imagePaths, map( "$catPath/$_", @entries ) );
		}

		# Make a single master dataset for these images.
		my $dataset_name = $q->param( 'experiment_name' );
		my $dataset = OME::Tasks::DatasetManager->newDataset(
			$dataset_name,
		);
		
		# Fork a process to import images, then the spreadsheets, 
		# then to clean up our temporary files
		my $task = OME::Tasks::NotificationManager->
		  new('Importing and annotating images',4 + scalar(@imagePaths));
		$task->setPID($$);
		$task->step();
		$task->setMessage('Starting image import');
			
		OME::Fork->doLater ( sub {
			# Ensure we are in the right directory after the fork. Otherwise,
			# the relative paths won't work.
			chdir( $tmpDir )
				or die "Couldn't change directories to $tmpDir";
			OME::Tasks::ImageTasks::importFiles($dataset, \@imagePaths, {}, $task);
			$task->step();
			$task->setMessage("Importing spreadsheet annotations");
			my $importedObjects = OME::Util::Annotate::SpreadsheetReader->processFile( $spreadSheetPath );
			if( $importedObjects ) {
				$task->setMessage( "Successfully imported spreadsheet annotations" );
			} else {
				$task->setMessage( "Had errors while importing spreadsheet annotations" );
			}
			$session->finishTemporaryFile( $spreadSheetPath );
			$session->finishTemporaryFile( $tmpFile );
			$session->finishTemporaryFile( $tmpDir );
			$session->commitTransaction();
		} );

		# If we've made it this far, then there should be an import task
		# for the user to view. Forward them to the task page.
		return( 'REDIRECT', $self->pageURL('OME::Web::TaskProgress') );
	}
	
	return( 'HTML', $self->getForm($tmpl) );
}

sub getForm() {
	my $self = shift;
	my $tmpl = shift;
	my $errorMsg = shift;
	my $q = $self->CGI();
	
	my $now = localtime;
	$tmpl->param( {
		file_upload_field => $q->filefield(
			-name    => 'zipFile',
			-size    => 50,
		), 
		submit            => $q->button(
			-value   => 'Upload, Import, and Annotate',
			-onClick => "javascript: document.forms['primary'].elements['action'].value='UploadImportAnnotate'; document.forms['primary'].submit();"
		),
		experiment_name   => $q->textfield(
			-name      => 'experiment_name',
			-default   => $now,
			-size      => 50,
			-maxlength => 80
		),
		error_msg         => $errorMsg,
	} );
	
	my $html =
		$q->startform( { -name => 'primary', 
				 -enctype => 'multipart/form-data' } ).
		$tmpl->output().
		$q->hidden( -name => 'action' ).
		$q->endform();

	return $html;
}
