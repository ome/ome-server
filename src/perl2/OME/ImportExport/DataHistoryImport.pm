# OME/ImportExport/DataHistoryImport.pm

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


package OME::ImportExport::DataHistoryImport;

use strict;
use OME;
use OME::Session;
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

	my @fieldsILike = qw(_doc objects);

	my $self;

	@$self{@fieldsILike} = @params{@fieldsILike};

    if (!defined $self->{_parser}) {
        my $parser = XML::LibXML->new();
        logdie "Cannot create XML parser"
          unless defined $parser;

        $parser->validation(exists $params{ValidateXML}?
                            $params{ValidateXML}: 0);
        $self->{_parser} = $parser;
    }
	
	$self->{_LSIDresolver} = OME::Tasks::LSIDManager->new();

	return bless $self, $class;
}


sub importFile {
    my ($self, $filename, %flags) = @_;
    my $doc = $self->{_parser}->parse_file($filename)
      or logdie "Cannot parse file $filename";
    return $self->processDOM($doc->getDocumentElement(),%flags);
}

sub importXML {
    my ($self, $xml, %flags) = @_;
    my $doc = $self->{_parser}->parse_string($xml)
      or logdie "Cannot parse XML string";
    return $self->processDOM($doc->getDocumentElement(),%flags);
}

sub processDOM {
	my ($self, $root, %flags) = @_;

	my $LSIDresolver  = $self->{_LSIDresolver};
	my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my $objectLookup = $self->{objects};
	my @objects2store;

	logdbg "debug", ref($self)."->processDOM called. Importing history";
	
	my $historyXML = $root->getElementsByTagNameNS($NAMESPACE,'DataHistory')->[0]; 
	return undef unless defined $historyXML;
	my %newMEXhash;
	# Import MEX and outputs
	foreach my $mexXML ( @{ $historyXML->getElementsByTagNameNS($NAMESPACE,'ModuleExecution') } ){
		logdbg "debug", ref($self)."->processDOM processing MEX ".$mexXML->getAttribute('ID');
		my $executionHistory = $mexXML->getElementsByTagNameNS($NAMESPACE,'ExecutionHistory')->[0];
		
		# MEX
		my $mex = $LSIDresolver->getLocalObject( $mexXML->getAttribute( 'ID' ));
		next if ($mex);
		my $dataset_lsid = $mexXML->getAttribute( 'DatasetID' );
		my $dataset = $objectLookup->{ $dataset_lsid } || $LSIDresolver->getObject( $dataset_lsid )
			or die "couldn't resolve dataset lsid $dataset_lsid\n";
		my $module  = $LSIDresolver->getObject( $mexXML->getAttribute( 'ModuleID' ))
			or die "Could not load module with lsid '".$mexXML->getAttribute( 'ModuleID' )."'\n";
		$mex = $factory->newObject("OME::ModuleExecution",
			{
				module_id     => $module,
				dependence    => $mexXML->getAttribute( 'Dependence' ),
				dataset_id    => $dataset->id(),
				timestamp     => $executionHistory->getAttribute( 'Timestamp' ),
				status        => $executionHistory->getAttribute( 'Status' ),
				total_time    => $executionHistory->getAttribute( 'RunTime' ),
				error_message => $executionHistory->getAttribute( 'ErrorMessage' ),
				attribute_create_time => $executionHistory->getAttribute( 'AttributeCreateTime' ),
				attribute_sort_time   => $executionHistory->getAttribute( 'AttributeSortTime' ),
			}) or die "Couldn't make a new ModuleExecution";
		push( @objects2store, $mex );
		my $lsid = $LSIDresolver->setLSID( $mex, $mexXML->getAttribute( 'ID' ) );
		push( @objects2store, $lsid ) if $lsid;
		
		# set MEX on outputs.
		foreach my $outputXML ($mexXML->getElementsByTagNameNS($NAMESPACE,'Output') ) {
			logdbg "debug", ref($self)."->processDOM processing formal output ".$outputXML->getAttribute('Name')."";
			my $fo = $factory->findObject( "OME::Module::FormalOutput", {
				'module_id' => $mex->module_id,
				'name'      => $outputXML->getAttribute( 'Name' )
				}) or die ref($self)."->processDOM could not load Formal Output '".
				$outputXML->getAttribute( 'Name' )."' of module '".$mex->module_id."'\n";
			foreach my $attrRefXML( $outputXML->getElementsByTagNameNS($NAMESPACE,'AttributeRef') ) {
				my $LSID = $attrRefXML->getAttribute( 'ID' );
				my $attr;
				if (exists $objectLookup->{ $LSID } ) {
					$attr = $objectLookup->{ $LSID };
				} else {
					$attr = $LSIDresolver->getObject( $LSID )
						or die "Could not load object from LSID ".$attrRefXML->getAttribute( 'ID' );
				}
				$attr->module_execution( $mex );
				push( @objects2store, $attr );
			}
		}
		
		$newMEXhash{ $mexXML->getAttribute( 'ID' ) } = $mex;
		
	}
	
	# Import Inputs after MEXs have been imported
	foreach my $mexXML ( @{ $historyXML->getElementsByTagNameNS($NAMESPACE,'ModuleExecution') } ) {
		my $mex = $newMEXhash{ $mexXML->getAttribute( 'ID' ) }
			or next;
		
		# Actual Inputs
		foreach my $inputXML ($mexXML->getElementsByTagNameNS($NAMESPACE,'Input') ) {
			logdbg "debug", ref($self)."->processDOM processing input ".$inputXML->getAttribute('Name');
			my $fi = $factory->findObject( "OME::Module::FormalInput", {
				'module_id' => $mex->module_id,
				'name'      => $inputXML->getAttribute( 'Name' )
				}) or die ref($self)."->processDOM could not load Formal Input '".
				$inputXML->getAttribute( 'Name' )."' of module '".$mex->module_id."'\n";
			my $input_mex = $LSIDresolver->getObject( $inputXML->getAttribute( 'ModuleExecutionID' ))
				or die "Could not load input module execution from lsid ".$inputXML->getAttribute( 'ModuleExecutionID' );
			my $actual_input = $factory->
				newObject("OME::ModuleExecution::ActualInput",
				{
					module_execution          => $mex->id(),
					formal_input_id           => $fi->id(),
					input_module_execution_id => $input_mex,
				});
		}
		
		
	}
	$_->storeObject() foreach @objects2store;
}

1;
