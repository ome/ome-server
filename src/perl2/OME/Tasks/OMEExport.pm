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
use Log::Agent;
use XML::LibXML;
use XML::LibXSLT;

use OME::ImportExport::SemanticTypeExport;
#use OME::Tasks::ProgramExport;
#use OME::Tasks::ChainExport;
use OME::ImportExport::HierarchyExport;
use OME::ImportExport::InsertFiles;
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
	my $parser  = $self->{_parser};
	my $insert = OME::ImportExport::InsertFiles->new( session => $session, parser => $parser );

 	# Apply Stylesheet
 	my $xslt = XML::LibXSLT->new();
 	my $style_doc_path = $session->Configuration()->xml_dir() . "/OME-CA2OME.xslt";
 	my $style_doc = $parser->parse_file( $style_doc_path );
	my $stylesheet = $xslt->parse_stylesheet($style_doc);
	my $CA_doc = $stylesheet->transform($doc);

# these hacks were added by josiah <siah@nih.gov>

#	REMOVE THIS HACK WHEN $stylesheet->transform($doc); PRODUCES SOMETHING USEFUL 
# CA_doc is blank except for <OME>. I haven't yet figured out why. 
# until I figure out why, I'm applying the stylesheet via command line.
# this is a hack - CLI application of the style sheet
my $tmpFile = $session->getTemporaryFilename();
$doc->toFile($tmpFile, 1) 
	or die "Could not write to temp file ('$tmpFile')\n";
`xsltproc $style_doc_path $tmpFile > $filename`;
$CA_doc = $parser->parse_file( $filename )
	or die "Could not parse file ('$tmpFile')\n";
$session->finishTemporaryFile( $tmpFile );
# end hack

	$insert->exportFile( $filename, $CA_doc );

}

# this method commented out by Josiah, June 17, 2003
# because: cannot currently apply stylesheet to loaded DOM w/o first writing it to file (no biggie)
#	&& insertBinData (C prog using SAX parser) has to read info from file. we need to find other methods for dealing w/ this stuff or think heavily before publishing this method
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
$flags{ExportHistory} = 0;
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
