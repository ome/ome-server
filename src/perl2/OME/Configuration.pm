# OME/Configuration.pm

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

=head1 NAME

OME::Configuration - OME Configuration variables

=head1 SYNOPSIS

	# This is how the configuration variables are originally written to the DB
	use OME::Configuration;
	my $conf = new OME::Configuration ($factory,{var1 => 123, var2 => 'foo'});
	# Normally, the Configuration object is retreived from the OME::Session object
	my $conf = $session->Configuration();
	my $var1 = $conf->var1();

=head1 DESCRIPTION

The Configuration object is used to get configuration variables
established when OME was installed.  In normal use, the variables are
read only, and the Configuration object is retreived from the
L<C<OME::Session>|OME::Session> object.

The constructor can be called from an installation script and passed a
configuration hash along with an L<C<OME::Factory>|OME::Factory>
object:

	my $conf = new OME::Configuration ($factory,{var1 => 123, var2 => 'foo'});

If there are already configuration variables in the DB, the hash will
be ignored.  An
L<C<OME::Configuration::Variable>|OME::Configuration::Variable> object
will be loaded for each variable in the DB.  If the DB does not
contain configuration variables, a new
L<C<OME::DBObject>|OME::DBObject> of type
L<C<OME::Configuration::Variable>|OME::Configuration::Variable> will
be made for each key-value pair in the hash, and written to the DB.
The names of the
L<C<OME::Configuration::Variable>|OME::Configuration::Variable>
objects will be made available as methods of Configuration, returning
the value of the variable when called.  From the example above,
C<$conf-E<gt>var1()> will return I<123>.  The two mutator methods are
described below.

It is likely that some of the configuration variables will be foreign
keys into other database tables.  These variables are defined in the
%FOREIGN_KEY_VARS hash (currently inaccessible outside of the
OME::Configuration module).  The keys of the hash are the names of the
variables as they should be called by code using the Configuration
object; the Configuration constructor will create accessor/mutators
with these names that expect instances of the foreign key object
class.  The values of the hash are an anonymous array specifying the
name of the Configuration variable containing the foreign key ID, and
the name of the foreign key class.  An example is appropriate:

	my %FOREIGN_KEY_VARS =
	  (
	   import_chain => {
	                    DBColumn => 'import_chain_id',
	                    FKClass  => 'OME::AnalysisChain',
	                   },
	  );

This defines a logical configuration variable called C<import_chain>
which points to an instance of the OME::AnalysisChain class.  This
variable is stored in the database in the actual configuration
variable C<import_chain_id>.

Each Configuration object will have an accessor/mutator called
C<import_chain> which expects instances of OME::AnalysisChain, and one
called C<import_chain_id> which expects integer database ID's.
Similarly, when creating a new Configuration object with the hash
parameter to C<new>, the parameter hash can contain B<either> an
C<import_chain> entry keyed to an instance of OME::AnalysisChain,
B<or> an C<import_chain_id> entry keyed to the ID of an analysis
chain.

=head1 METHODS

=cut


package OME::Configuration;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(Class::Accessor);

my %FOREIGN_KEY_VARS =
  (
   import_chain  => {
                     DBColumn => 'import_chain_id',
                     FKClass  => 'OME::AnalysisChain',
                    },
   import_module => {
                     DBColumn => 'import_module_id',
                     FKClass  => 'OME::Module'
                    },
  );

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $factory = shift;
	my $params = shift;
	my $self = {};

	die "new OME::Configuration called without required factory parameter."
		unless $factory;
	$self->{Factory} = $factory;

	my @vars = $factory->findObjects('OME::Configuration::Variable',
		configuration_id => 1);

	# only pay attention to the params if we don't have any
        # variables stored in the DB yet.
	# The set of variables is write once.

	if (not scalar @vars) {
        my ($name,$value);
        while (($name,$value) = each %$params) {

            # If the key of the hash is a foreign key variable, then
            # the value must be an instance of the specified FK
            # class.  If so, then store that object's ID in the
            # database in the specified ID field.

            if (exists $FOREIGN_KEY_VARS{$name}) {
                my $fk_spec = $FOREIGN_KEY_VARS{$name};
                die "Invalid foreign key spec"
                  unless ref($fk_spec) eq 'HASH'
                    && defined $fk_spec->{DBColumn}
                      && defined $fk_spec->{FKClass};

                my $db_column = $fk_spec->{DBColumn};
                my $fk_class = $fk_spec->{FKClass};

                die "$name must be an instance of $fk_class"
                  unless UNIVERSAL::isa($value,$fk_class);

                my $id = $value->id();
                my $success = $factory->
                  newObject('OME::Configuration::Variable',
                            {
                             configuration_id => 1,
                             name             => $db_column,
                             value            => $id,
                            });

                if ($success) {
                    $self->{$db_column} = $id;
                    $self->{$name} = $value;
                }
            } else {

                # Not a foreign key field.  The value cannot be a
                # reference.  Just create the variable normally,
                # and store it in the $self hash.

                die "OME::Configuration->new():  Attempt to store a reference as a configuration variable! $name has a reference to ".ref($value)."\n"
                  if ref ($value);

                $self->{$name} = $value if $factory->
                  newObject('OME::Configuration::Variable',
                            {
                             configuration_id => 1,
                             name => $name,
                             value => $value
                            });
            }
        }
 	} else {

        # We found some variables already in the database.  Ignore
        # any configuration sent in as a parameter.  For each of
        # the foreign key variables, instantiate their objects if
        # they've been set.

        # Assign the variables read from the DB into the $self hash.
        foreach my $var (@vars) {
            $self->{$var->name()} = $var->value();
        }

        # Instantiate any foreign key variables we found.
        foreach my $fk_name (keys %FOREIGN_KEY_VARS) {
            my $fk_spec = $FOREIGN_KEY_VARS{$fk_name};
            die "Invalid foreign key spec"
              unless ref($fk_spec) eq 'HASH'
                && defined $fk_spec->{DBColumn}
                  && defined $fk_spec->{FKClass};

            my $db_column = $fk_spec->{DBColumn};
            my $fk_class = $fk_spec->{FKClass};

            # Skip this variable if it wasn't in the database.
            next unless defined $self->{$db_column};

            # Get the ID that was loaded in
            my $id = $self->{$db_column};

            # Try to load that object from the DB
            my $object = $factory->loadObject($fk_class,$id);

            # If we can't read the object, then there's something
            # horribly wrong with the configuration values.
            die "Value for $fk_name ($id) is not a valid $fk_class"
              unless defined $object;

            # Save the instantiated object.
            $self->{$fk_name} = $object;
        }
	}

	bless($self,$class);

    # Make specialized accessors for the foreign key variables.  We
    # make sure to declare them here, before the call to
    # Class::Accessor->mk_ro_accessors, so make sure that our
    # special foreign key behavior is implemented.  (Class::Accessor
    # will not override an existing method.)

    foreach my $fk_name (keys %FOREIGN_KEY_VARS) {
        # We should have already performed the check to see if this
        # is well-formed.

        my $fk_spec = $FOREIGN_KEY_VARS{$fk_name};
        my $db_column = $fk_spec->{DBColumn};
        my $fk_class = $fk_spec->{FKClass};

        # Create an accessor which uses the __changeObjRef method for
        # its implementation.

        my $accessor = sub {
            my $self = shift;
            $self->{$fk_name} = $self->
              __changeObjRef ($db_column,$fk_class,shift) if scalar @_;
            return $self->{$fk_name};
        };

        # Save this accessor into the current package
        {
            no strict 'refs';
            *{__PACKAGE__."\:\:$fk_name"} = $accessor;
        }
    }

	# Make read-only accessors for the variables.
	$self->mk_ro_accessors(keys %{$self});

	return $self;
}

sub __changeObjRef {
	my ($self,$IDvariable,$objectType,$object) = @_;
	die "In OME::Configuration->__changeObjRef, expected parameter of type '$objectType', but got '".
		ref($object)."'\n" unless ref($object) eq $objectType;
	die "In OME::Configuration->__changeObjRef, object '".ref($object)."' is not an OME::DBObject!\n"
		unless UNIVERSAL::isa($object,"OME::DBObject");
	my $factory = $object->Session()->Factory() or die "In OME::Configuration->__changeObjRef, object '".ref($object)."' has no Factory!\n";
	my $IDobject = $factory->findObject('OME::Configuration::Variable',
		configuration_id => 1,name => $IDvariable);
	if ($IDobject and $IDobject->value() ne $object->id()) {
		$IDobject->value($object->id());
		$IDobject->storeObject();
		$self->{$IDvariable} = $IDobject->value();
	} elsif (not $IDobject) {
		$IDobject = $factory->newObject('OME::Configuration::Variable', {
			configuration_id => 1,
			name => $IDvariable,
			value => $object->id()
		});
		if ($IDobject) {
			$IDobject->storeObject();
			$self->mk_ro_accessors ($IDvariable);
			$self->{$IDvariable} = $IDobject->value();
		}
	}
	return ( $object ) if $IDobject;
	return ( undef );
}
1;

=head1 AUTHOR

Ilya Goldberg <igg@nih.gov>, Open Microscopy Environment

=cut
