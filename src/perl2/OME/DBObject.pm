# OME/DBObject.pm
# This module is the superclass of any Perl object stored in the
# database.

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


package OME::DBObject;
our $VERSION = '1.0';

use strict;
use Ima::DBI;
use Class::Data::Inheritable;
use Class::Accessor;
use OME::SessionManager;
use OME::DBConnection;

use base qw(Class::DBI Class::Accessor Class::Data::Inheritable);

__PACKAGE__->mk_classdata('AccessorNames');
__PACKAGE__->mk_classdata('Session');
__PACKAGE__->AccessorNames({});
__PACKAGE__->set_db('Main',
                  OME::DBConnection->DataSource(),
                  OME::DBConnection->DBUser(),
                  OME::DBConnection->DBPassword(), 
                  { RaiseError => 1 });



sub columns {
    my ($class) = shift;

    if ($ENV{OME_CLASS_DBI_DEBUG} eq '1' && $class eq 'OME::Program') {
        print STDERR "*** ${class}->columns being called\n";
        print STDERR "    Parameters: ".join(' ',@_)."\n";
    }

    $class->SUPER::columns(@_);
}

sub _set_columns {
    my ($class) = shift;

    if ($ENV{OME_CLASS_DBI_DEBUG} eq '1' && $class eq 'OME::Program') {
        print STDERR "*** ${class}->_set_columns being called\n";
        print STDERR "    Parameters: ".join(' ',@_)."\n";
    }

    $class->SUPER::_set_columns(@_);
}


# Accessors
# ---------

sub ID {
    my $self = shift;
    return $self->id(@_);
}

sub accessor_name {
    my ($class, $column) = @_;
    my $names = $class->AccessorNames();
    return $names->{$column} if (exists $names->{$column});
    return $column;
}
sub DBH { my $self = shift; return $self->db_Main(); }


# Field accessor
# --------------

sub Field {
    my $self = shift;
    my $field = shift;

    return $self->$field(@_);
}    


sub writeObject {
    my $self = shift;
    $self->commit();
    $self->dbi_commit();
}

1;
