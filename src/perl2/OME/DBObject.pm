# This module is the superclass of any Perl object stored in the
# database.

package OME::DBObject;
our $VERSION = '1.0';

use strict;
use Ima::DBI;
use Class::Accessor;
use OME::SessionManager;

use base qw(Class::DBI Class::Accessor Class::Data::Inheritable);
use fields qw(Factory);

__PACKAGE__->mk_classdata('AccessorNames');
__PACKAGE__->AccessorNames({});
__PACKAGE__->mk_ro_accessors(qw(Factory));
__PACKAGE__->set_db('Main',
                  OME::SessionManager->DataSource(),
                  OME::SessionManager->DBUser(),
                  OME::SessionManager->DBPassword());





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

sub Session { my $self = shift; return $self->Factory()->Session(); }
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
}

1;
