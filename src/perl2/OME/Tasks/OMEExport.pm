# OME/Tasks/OMEExport.pm

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
# Written by:    Ilya Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Tasks::OMEExport;

use strict;
use OME;
our $VERSION = $OME::VERSION;
our $NAMESPACE = 'http://www.openmicroscopy.org/XMLschemas/CA/RC1/CA.xsd';
our $SCHEMA_LOCATION = $NAMESPACE;
our $XSI_NAMESPACE = 'http://www.w3.org/2001/XMLSchema-instance';

use Carp;
use IPC::Run;
use Log::Agent;
use XML::LibXML;
use XML::LibXSLT;

use OME::ImportExport::SemanticTypeExport;
#use OME::Tasks::ProgramExport;
#use OME::Tasks::ChainExport;
use OME::ImportExport::HierarchyExport;
use OME::ImportExport::DataHistoryExport;

sub new {
	my ($proto, %params) = @_;
	my $class = ref($proto) || $proto;

	my @fieldsILike = qw(session _doc _parser);

	my $self;

	@$self{@fieldsILike} = @params{@fieldsILike};

	die $class."->new needs a session"
	  unless exists $self->{session} &&
			 UNIVERSAL::isa($self->{session},'OME::Session');

	if (!defined $self->{_doc}) {
		my $doc = XML::LibXML::Document->new();
		die "Cannot create XML document"
		  unless defined $doc;
		my $root = $doc->createElementNS($NAMESPACE,'OME');
		$root->setNamespace($XSI_NAMESPACE, 'xsi',0);
		$root->setAttributeNS($XSI_NAMESPACE,'schemaLocation',"$NAMESPACE $SCHEMA_LOCATION");
		$doc->setDocumentElement($root);
		$self->{_doc} = $doc;
	}

    if (!defined $self->{_parser}) {
        my $parser = XML::LibXML->new();
        die "Cannot create XML parser"
          unless defined $parser;

        $parser->validation(exists $params{ValidateXML}?
                            $params{ValidateXML}: 0);
        $self->{_parser} = $parser;
    }

	return bless $self, $class;
}


sub exportFile {
	my ($self, $filename, %flags) = @_;
	my $doc = $self->doc();
	logdie ref ($self)."->exportFile:  Need a filename parameter to export a file."
		unless defined $filename;
		
	my $session = $self->{session};

 	# Apply Stylesheet
 	my $style_doc_path = $session->Configuration()->xml_dir() . "/OME-CA2OME.xslt";
# 	my $xslt = XML::LibXSLT->new();
# 	my $stylesheet = $xslt->parse_stylesheet_file( $style_doc_path );
#	my $CA_doc = $stylesheet->transform($doc);
#	$stylesheet->output_file( $CA_doc, $filename );

# these hacks were added by josiah <siah@nih.gov>

#	REMOVE THIS HACK WHEN $stylesheet->transform($doc); PRODUCES SOMETHING USEFUL 
# CA_doc is blank except for <OME>. It appears to be a bug in XML::LibXSLT.
# Until a new version rolls out, I'm applying the stylesheet via command line.

	my $CA_file = $session->getTemporaryFilename('ome_export', 'tmp');
	$doc->toFile($CA_file, 1) 
		or die "Could not write to temp file ('$CA_file')\n";
	# find the path to xsltproc
	my $xsltproc_path;
	( -e $_ and $xsltproc_path = $_ and last ) 
		foreach ( '/usr/bin/xsltproc', '/usr/local/bin/xsltproc', '/sw/bin/xsltproc' );
	die "Could not find xsltproc." unless $xsltproc_path;

	my $OME_file_no_pixels = $session->getTemporaryFilename('ome_export', 'tmp');
	my $errorStream = '';
	open( OUT, "> $OME_file_no_pixels" ) or die $!;
	IPC::Run::run (
		[$xsltproc_path, $style_doc_path, $CA_file],
		\undef,
		\*OUT,
		\$errorStream
	) or die "$xsltproc_path returned non-zero exit status: $?\n$errorStream" ;
	$session->finishTemporaryFile( $CA_file );

	open( XML_OUT, "> $filename" );
	print XML_OUT OME::Image::Server->exportOMEFile( $OME_file_no_pixels );
	close( XML_OUT );
	$session->finishTemporaryFile( $OME_file_no_pixels );
}

# this method commented out by Josiah, June 17, 2003
# because: cannot currently apply stylesheet to loaded DOM w/o first
#	writing it to file (no biggie).
# Hmm. The architecture has changed significantly since I originally wrote 
# this. We may be able to have this functionality again. 2/3/5
#sub exportXML {
#	my ($self, %flags) = @_;
#	return ($self->doc()->toString(1)); 
#}

sub doc {
	my $self = shift;
	return ($self->{_doc});
}

sub historyExporter {
	my $self = shift;
	return $self->{_historyExporter} if exists $self->{_historyExporter};
	$self->{_historyExporter} = new OME::ImportExport::DataHistoryExport (session => $self->{session}, _doc => $self->doc());
	return $self->{_historyExporter};
}

sub buildDOM {
	my ($self, $objects, %flags) = @_;
	my $doc = $self->doc();
	logdie ref ($self)."->buildDOM:  Need a reference to an array of objects."
		unless ref($objects) eq 'ARRAY';

	if ($flags{ResolveAllRefs}) {
		$self->resolveAllRefs ($objects, %flags);
	}

	# Export the hierarchy and custom attributes
	logdbg "debug", ref ($self).'->buildDOM:  Getting a Hierarchy Exporter';
	my $hierarchyExporter = new OME::ImportExport::HierarchyExport (session  => $self->{session}, _doc => $doc);
	logdbg "debug", ref ($self).'->buildDOM:  Exporting Hierarchy to DOM';
	$hierarchyExporter->buildDOM($objects,%flags);

	# Export semantic type definitions only if ExportSTDs is set
	if ($flags{ExportSTDs}) {
		logdbg "debug", ref ($self).'->buildDOM:  Getting a STD Exporter';
		my $typeExporter = new OME::ImportExport::SemanticTypeExport (session => $self->{session}, _doc => $doc);
		logdbg "debug", ref ($self).'->buildDOM:  Exporting STDs to DOM';
		$typeExporter->buildDOM($objects,%flags);
	}
	
	
	# Export modules
#	my $moduleExporter = OME::Tasks::ProgramExport->
#	  new(session		  => $self->{session},
#			  _doc => $doc);

#	$moduleExporter->buildDOM($objects,%flags);

	# Export the chains
#	my $chainExporter = OME::Tasks::ChainExport->
#	  new(session => $self->{session},
#			  _doc => $doc);

#	$chainExporter->buildDOM($objects,%flags);

	# Export semantic type definitions only if ExportSTDs is set
	if ($flags{ExportHistory}) {
		logdbg "debug", ref ($self).'->buildDOM:  Getting a Data History Exporter';
		my $historyExporter = $self->historyExporter();
		logdbg "debug", ref ($self).'->buildDOM:  Exporting Data History to DOM';
		$historyExporter->buildDOM($objects,%flags);
	}
	
	


}


sub resolveAllRefs {
	my ($self, $objects, %flags) = @_;

	if ($flags{ExportHistory}) {
		my $historyExporter = $self->historyExporter();
		push( @$objects, $historyExporter->findDependencies( $objects ) );
	}
	return undef;
}
1;
