# OME/Tasks/OMEImport.pm

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


package OME::Tasks::OMEImport;

use strict;
our $VERSION = '1.0';

use Carp;
use Log::Agent;
use XML::LibXML;

use OME::Tasks::SemanticTypeImport;
use OME::Tasks::ProgramImport;
use OME::Tasks::ChainImport;
use OME::Tasks::HierarchyImport;

sub new {
    my ($proto, %params) = @_;
    my $class = ref($proto) || $proto;

    my @fieldsILike = qw(session _parser debug);

    my $self;

    @$self{@fieldsILike} = @params{@fieldsILike};

    die "I need a session"
      unless exists $self->{session} &&
             UNIVERSAL::isa($self->{session},'OME::Session');

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


sub importFile {
    my ($self, $filename, %flags) = @_;
    my $doc = $self->{_parser}->parse_file($filename)
      or die "Cannot parse file $filename";
    return $self->processDOM($doc->getDocumentElement(),%flags);
}

sub importXML {
    my ($self, $xml, %flags) = @_;
    my $doc = $self->{_parser}->parse_string($xml)
      or die "Cannot parse XML string";
    return $self->processDOM($doc->getDocumentElement(),%flags);
}


sub processDOM {
    my ($self, $root, %flags) = @_;

    # Parse the semantic types

    my $typeImporter = OME::Tasks::SemanticTypeImport->
      new(session => $self->{session},
          _parser => $self->{_parser},
          debug => $self->{debug});

    my $stdElement = $root->
      getElementsByLocalName("SemanticTypeDefinitions" )->[0];

    my $semanticTypeList = $typeImporter->processDOM($stdElement,%flags)
        if defined $stdElement;

    my $semanticTypes = $typeImporter->SemanticTypes();
    my $semanticColumns = $typeImporter->SemanticColumns();

    # Parse the modules

    my $moduleImporter = OME::Tasks::ProgramImport->
      new(session         => $self->{session},
          _parser         => $self->{_parser},
          semanticTypes   => $semanticTypes,
          semanticColumns => $semanticColumns,
         debug => $self->{debug});

    my $amlElement = $root->
      getElementsByLocalName("AnalysisModuleLibrary" )->[0];

    my $moduleList = $moduleImporter->processDOM($amlElement,%flags)
      if defined $amlElement;

    # Parse the chains

    my $chainImporter = OME::Tasks::ChainImport->
      new(session => $self->{session},
          _parser => $self->{_parser});

    my $chainList = $chainImporter->processDOM($root,%flags);


    # Parse the hierarchy and custom attributes

    my $hierarchyImporter = OME::Tasks::HierarchyImport->
      new(session         => $self->{session},
          _parser         => $self->{_parser},
          semanticTypes   => $semanticTypes,
          semanticColumns => $semanticColumns,
          debug           => $self->{debug});

    $hierarchyImporter->processDOM($root);

}


1;
