# OME/Tasks/ModuleExecutionManager.pm

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
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Tasks::SemanticTypeManager;

=head1 NAME

OME::Tasks::SemanticTypeManager - Workflow methods for handling
semantic types

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use OME::SemanticType;
use OME::SemanticType::Element;
use OME::DataTable;


sub createSemanticType {
    my $class = shift;
    my ($name,$granularity,$description) = @_;
    my $factory = OME::Session->instance()->Factory();

    my $st = $factory->findObject('OME::SemanticType',
                                  name => $name);
    unless (defined $st) {
        $st = $factory->
          newObject('OME::SemanticType',
                    {
                     name        => $name,
                     granularity => $granularity,
                     description => $description,
                    });
        die "Could not create $name type"
          unless defined $st;
    }

    return $st;
}

sub addSemanticElement {
    my $class = shift;
    my ($st,$name,$dc,$description) = @_;
    my $factory = OME::Session->instance()->Factory();

    my $se = $factory->findObject('OME::SemanticType::Element',
                                  semantic_type => $st,
                                  name          => $name);
    unless (defined $se) {
        $se = $factory->
          newObject('OME::SemanticType::Element',
                    {
                     semantic_type => $st,
                     name          => $name,
                     data_column   => $dc,
                     description   => $description,
                    });
        die "Could not create $name element"
          unless defined $se;
    }

    return $se;
}


sub createDataTable {
    my $class = shift;
    my ($name,$granularity,$description) = @_;
    my $factory = OME::Session->instance()->Factory();

    my $dt = $factory->findObject('OME::DataTable',
                                  table_name => $name);
    unless (defined $dt) {
        $dt = $factory->
          newObject('OME::DataTable',
                    {
                     table_name  => $name,
                     granularity => $granularity,
                     description => $description,
                    });
        die "Could not create $name table"
          unless defined $dt;
    }

    return $dt;
}

sub addDataColumn {
    my $class = shift;
    my ($dt,$name,$type,$param1,$param2) = @_;
    my ($description,$reftype);
    if ($type eq 'reference') {
        $reftype = $param1;
        $description = $param2;
    } else {
        $reftype = undef;
        $description = $param1;
    }
    my $factory = OME::Session->instance()->Factory();

    my $dc = $factory->findObject('OME::DataTable::Column',
                                  column_name => $name,
                                  data_table  => $dt);
    unless (defined $dc) {
        $dc = $factory->
          newObject('OME::DataTable::Column',
                    {
                     data_table     => $dt,
                     column_name    => $name,
                     sql_type       => $type,
                     reference_type => $reftype,
                     description    => $description,
                    });
        die "Could not create $name column"
          unless defined $dc;
    }

    return $dc;
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
