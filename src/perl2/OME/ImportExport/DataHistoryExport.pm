# OME/ImportExport/DataHistoryExport.pm

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


package OME::ImportExport::DataHistoryExport;

=head1 NAME

OME::ImportExport::DataHistoryExport - Export module executions to describe how data was produced

=head1 SYNOPSIS

	# Make a new DataHistory exporter and a new XML document
	my $exporter = new OME::ImportExport::DataHistoryExport(session => $session);

	# Or - make a new Hierarchy exporter for an existing XML document
	my $exporter = new OME::Tasks::OMEExport (session => $session);
	my $doc = $exporter->doc();
	my $exportH = new OME::ImportExport::DataHistoryExport(session => $session, _doc => $doc);

	# Build a DOM from a list of objects.
	$exportH->buildDOM (@OMEobjects);
	
	# Write an XML file, get the XML as a string, or get the XML document (XML::LibXML), 
	$exportH->exportFile ();
	my $xml = $exportH->exportXML ();
	my $doc = $exportH->doc();

=head1 DESCRIPTION

This class is responsible for exporting the information necessary to reconstruct how data was introduced to the 
system or derived. The xml produced is tied to the data history schema (http://www.openmicroscopy.org/XMLschemas/DataHistory/IR3/DataHistory.xsd).

Currently virtual MEX's are NOT exported. See FIXME note in exportHistory method.

=head1 METHODS

=head2 new

	my $exporter = new OME::ImportExport::DataHistoryExport(session => $session, _doc => $doc );

_doc is optional, session is not

=head2 buildDOM

	# builds a data history for objects passed in as parameters.
	$exporter->buildDOM( [$obj1, $obj2, ...] );

=head2 findDependencies

	# returns objects not in the list that will be referenced when the history of the list is exported
	$exporter->findDependencies( [$obj1, $obj2, ...] );

=head2 exportFile

	# exports the loaded DOM into a file.
	$exporter->exportFile( '/path/filename' );

=head2 exportXML

	# returns the DOM as a string of XML.
	print $exporter->exportXML( );

=head1 AUTHOR

Josiah Johnston <siah@nih.gov>

=head1 SEE ALSO

L<OME::ModuleExecution|OME::ModuleExecution>, L<OME::Module|OME::Module>, L<OME::ModuleExecution::ActualInputs|OME::ModuleExecution::ActualInputs>, 

=cut


use strict;
use OME;
our $VERSION = $OME::VERSION;
our $NAMESPACE = 'http://www.openmicroscopy.org/XMLschemas/DataHistory/IR3/DataHistory.xsd';
our $XSI_NAMESPACE = 'http://www.w3.org/2001/XMLSchema-instance';

our $SCHEMA_LOCATION = $NAMESPACE;


use Carp;
use Log::Agent;
use XML::LibXML;
use OME::Tasks::LSIDManager;


sub new {
	my ($proto, %params) = @_;
	my $class = ref($proto) || $proto;

	my @fieldsILike = qw(session _doc);

	my $self;

	@$self{@fieldsILike} = @params{@fieldsILike};

	logdie $class."->new needs a session"
	  unless exists $self->{session} &&
			 UNIVERSAL::isa($self->{session},'OME::Session');

	if (!defined $self->{_doc}) {
		my $doc = XML::LibXML::Document->new();
		die "Cannot create XML document"
		  unless defined $doc;
		$self->{_doc} = $doc;
	}
	
	$self->{_LSIDresolver} = OME::Tasks::LSIDManager->new();

	return bless $self, $class;
}


sub exportFile {
	my ($self, $filename, %flags) = @_;
	my $doc = $self->doc();
	logdie ref ($self)."->exportFile:  Need a filename parameter to export a file."
		unless defined $filename;
	$doc->setCompression(7);
	logdie ref ($self)."->exportFile:  File could not be written."
		unless $doc->toFile($filename, 1); 
}

sub exportXML {
	my ($self, %flags) = @_;
	return ($self->doc()->toString(1)); 
}

sub doc {
	my $self = shift;
	return ($self->{_doc});
}

sub findDependencies {
	my ($self, $objects) = @_;
	logdie ref ($self)."->buildDOM:	 Need a reference to an array of objects."
		unless ref($objects) eq 'ARRAY';

	my $session = $self->{session};
	my $factory = $session->Factory();
	
	my %dataset_dependencies;
	my @known_datasets;
	
	# Go through the list of objects and export STDs for the ones that inherit from OME::SemanticType::Superclass.
	foreach (@$objects) {
		if( ref($_) eq "OME::Dataset") {
			push( @known_datasets, $_ );
		} elsif( UNIVERSAL::isa($_,"OME::SemanticType::Superclass") ){
			my $mex = $_->module_execution();
			my $dataset; $dataset = $mex->dataset() if $mex;
			$dataset_dependencies{ $dataset->id } = $dataset
				if( $dataset and not exists $dataset_dependencies{ $dataset->id } );
		}
	}
	
	delete $dataset_dependencies{ $_->id() } foreach @known_datasets;
	
	return values %dataset_dependencies;
}

sub buildDOM {
	my ($self, $objects, %flags) = @_;
	logdie ref ($self)."->buildDOM:	 Need a reference to an array of objects."
		unless ref($objects) eq 'ARRAY';

	my $session = $self->{session};
	my $factory = $session->Factory();
	
	# Go through the list of objects and export STDs for the ones that inherit from OME::SemanticType::Superclass.
	foreach (@$objects) {
		if( UNIVERSAL::isa($_,"OME::SemanticType::Superclass") ){
			logdbg "debug", ref ($self)."->buildDOM:  writing history for ".$_->semantic_type->name."(".$_->id.")";
			$self->exportHistory ($_) ;
		}
	}
}

# This method will return the DOM's STD element and create a new one if its not there.
# If there is no root element, root will be set to the STD element
# If there is a root element, the STD element will be inserted as the last child.
# Namespaces and schema locations will be re-used if the root element declared them.
# This method should only be called if there are STDs to export.
sub HistoryElement {
	my $self = shift;
	my $doc = $self->doc();
	my $historyElement = $self->{_historyElement};
	if (not defined $historyElement) {
		my $root = $doc->documentElement();
		if (not defined $root) {
			$historyElement = $root = $doc->createElementNS ($NAMESPACE, "DataHistory" );
			$doc->setDocumentElement($historyElement);

			$historyElement->setNamespace($XSI_NAMESPACE, 'xsi' ,0);
			$historyElement->setAttribute('xsi:schemaLocation' ,"$NAMESPACE $SCHEMA_LOCATION");
		} else {
			$historyElement = $root->getElementsByTagNameNS($NAMESPACE,'DataHistory')->[0]; 
			if (not defined $historyElement) {
				$historyElement = $doc->createElementNS ($NAMESPACE, "DataHistory" );
				$root->appendChild( $historyElement );

				my $xsi_prefix = $historyElement->lookupNamespacePrefix( $XSI_NAMESPACE );
				if (not defined $xsi_prefix) {
					$historyElement->setNamespace($XSI_NAMESPACE, 'xsi' ,0);
					$xsi_prefix = 'xsi';
				}
				my %schemaLocations = split ( /\s/,$historyElement->findvalue('../@'.$xsi_prefix.':schemaLocation'));
				$historyElement->setAttributeNS($XSI_NAMESPACE, "schemaLocation" ,"$NAMESPACE $SCHEMA_LOCATION")
					unless exists $schemaLocations{$NAMESPACE};

			}
		}
		$self->{_historyElement} = $historyElement;		
	}
	return $historyElement;
}

# Export the History for an OME::SemanticType::Superclass object.
sub exportHistory {
	my ($self, $attr) = @_;
	return unless $attr;

	my $factory = $self->{session}->Factory();
	my $LSIDresolver  = $self->{_LSIDresolver};

	my $exportedMEXs   = $self->{_exportedMEXs};
	my $DOM            = $self->doc();
	my $historyElement = $self->HistoryElement();
	my $MEX            = $attr->module_execution();
	my @MEXs2export;

	if( not defined $MEX) {
		logdbg "debug", ref ($self)."->exportHistory:  Attribute $attr has no MEX.";
		return;
	
	}

	my $MEXid = $MEX->id();
	if ( not exists $exportedMEXs->{$MEX}) {
		logdbg "debug", ref ($self)."->exportHistory:  Exporting MEX $MEXid";
	} else {
		logdbg "debug", ref ($self)."->exportHistory:  MEX $MEXid already in DOM";
		return;
	}

	
	push( @MEXs2export, $MEX );
	while( scalar (@MEXs2export ) > 0 ) {
		logdbg "debug", ref ($self)."->exportHistory:  Adding MEX $MEXid to DOM";
		
		# thisMEX is the mex currently being exported.
		my $thisMEX = pop( @MEXs2export );
		next if exists $exportedMEXs->{ $thisMEX->id() };
# FIXME: Export virtual mex's
		next unless $thisMEX->module;
		
		# add upstream MEXs to export list.
		push( @MEXs2export, grep { not exists $exportedMEXs->{ $_->id() } } map( $_->input_module_execution() , $thisMEX->inputs() ) );
	
		# <ModuleExecution>
		my $mexXML = $DOM->createElement( 'ModuleExecution' );
		$mexXML->setAttribute( 'ID', $LSIDresolver->getLSID( $thisMEX ) );
		$mexXML->setAttribute( 'Dependence', $thisMEX->dependence() );
		$mexXML->setAttribute( 'DatasetID', $LSIDresolver->getLSID( $thisMEX->dataset ) ) ;
		$mexXML->setAttribute( 'ModuleID', $LSIDresolver->getLSID( $thisMEX->module ) ) ;
		$historyElement->appendChild( $mexXML );
	
		# <ExecutionHistory>
		my $executionHistoryXML = $DOM->createElement( 'ExecutionHistory' );
		# Maps object accessor names (hash values) to xml attribute names (keys)
		my %executionHistoryCodes = ( 
			'RunTime'             => 'total_time', 
			'Timestamp'           => 'timestamp', 
			'Status'              => 'status',
			'ErrorMessage'        => 'error_message',
			'AttributeCreateTime' => 'attribute_create_time',
			'AttributeSortTime'   => 'attribute_sort_time'
		);
		foreach( keys %executionHistoryCodes ) {
			my $method = $executionHistoryCodes{$_};
			$executionHistoryXML->setAttribute( $_, $thisMEX->$method ) ;
		}
		$mexXML->appendChild( $executionHistoryXML );
		
		
		# <Input>
		foreach my $input ( $thisMEX->inputs() ) {
			my $inputXML = $DOM->createElement( 'Input' );
			$inputXML->setAttribute( 'Name', $input->formal_input()->name()  );
			$inputXML->setAttribute( 'ModuleExecutionID', $LSIDresolver->getLSID( $input->input_module_execution )  );
			$mexXML->appendChild( $inputXML );
		}
		
		# <Output>
		my @FO_list = $thisMEX->module->outputs;
		foreach my $FO ( @FO_list ) {
			my $outputXML = $DOM->createElement( 'Output' );
			$outputXML->setAttribute( 'Name', $FO->name()  );
# FIXME: add code to load untyped attrs.
			next unless $FO->semantic_type();
			my @output_attrs = $factory->findAttributes( $FO->semantic_type(), module_execution => $thisMEX );
			foreach my $attr (@output_attrs) {
				my $LSID = $LSIDresolver->getLSID( $attr )
					or die "Could not make LSID for $attr\n";
				my $attrRefXML = $DOM->createElement( 'AttributeRef' );
				$attrRefXML->setAttribute( 'ID', $LSID);
				$outputXML->appendChild( $attrRefXML );
			}
			$mexXML->appendChild( $outputXML );
		}
		
		$exportedMEXs->{ $thisMEX->id() } = undef;
	}
	
	$self->{_exportedMEXs} = $exportedMEXs;
	logdbg "debug", ref ($self)."->exportHistory:  Finished with $MEXid\n";
}


1;
