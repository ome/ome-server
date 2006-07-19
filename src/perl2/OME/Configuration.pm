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

=head1 References to OME objects

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

=head1 Serialized objects

Arrays and hashes are serialized to text using perl syntax, and
are made available as references by the accessor method defined in the
%SERIALIZED_VARS hash:

	my %SERIALIZED_VARS =
	  (
	   import_formats => 'ARRAY',
	   foo_conf       => 'HASH',
	  );

=head1 METHODS

=head2 new

  my $conf = OME::Configuration->new();
  my $conf = OME::Configuration->new($factory, {
    import_chain   => $chain,
    import_formats => [qw/ome-xml tiff ome-tiff/],
    foo_conf       => $foo,
    });

The constructor can be called parameterless to retreive the configuration stored
in the DB.  If there is a configuration in the DB, the parameters have no effect.
Cnfiguration parameters can be provided when initially recording the installation settings. 

=head2 update

  my $conf = OME::Configuration->update($factory, {
    foo_conf       => $foo2,
    });

This call will update the configuration as specified by the supplied hash.
This should really only be called during a synchronized updaate, where there are no
extant processes that may have cached the configuration. 

=head2 ...

... All of the configuration variables specified in new()
or update() are also available as accessor methods.

=cut


package OME::Configuration;

use strict;
use Carp qw (confess cluck);
use Data::Dumper; # serializer
use Safe;         # safer deserializer than eval

use OME;
our $VERSION = $OME::VERSION;

use base qw(Class::Accessor);

our %FOREIGN_KEY_VARS =
  (
   import_chain          => {
                             DBColumn => 'import_chain_id',
                             FKClass  => 'OME::AnalysisChain',
                            },
   annotation_module     => {
                             DBColumn => 'annotation_module_id',
                             FKClass  => 'OME::Module'
                            },
   original_files_module => {
                             DBColumn => 'original_files_module_id',
                             FKClass  => 'OME::Module'
                            },
   global_import_module  => {
                             DBColumn => 'global_import_module_id',
                             FKClass  => 'OME::Module'
                            },
   dataset_import_module => {
                             DBColumn => 'dataset_import_module_id',
                             FKClass  => 'OME::Module'
                            },
   image_import_module   => {
                             DBColumn => 'image_import_module_id',
                             FKClass  => 'OME::Module'
                            },
   administration_module   => {
                             DBColumn => 'administration_module_id',
                             FKClass  => 'OME::Module'
                            },
   repository              => {
                             DBColumn => 'repository_id',
                             FKClass  => 'OME::SemanticType::BootstrapRepository'
                            },
  );

our %SERIALIZED_VARS = (
	import_formats => 'ARRAY',
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $factory = shift;
	my $params = shift;
	my $self = {};

	die "new OME::Configuration called without required factory parameter."
		unless $factory;

	my $safe_eval = new Safe;

	my $vars = $factory->findObjects('OME::Configuration::Variable',
		configuration_id => 1);
	my $var = $vars->next();

	# only pay attention to the params if we don't have any
        # variables stored in the DB yet.
	# The set of variables is write once.

	if (not $var) {
		$self = $proto->update ($factory,$params);
 	} else {

        # We found some variables already in the database.  Ignore
        # any configuration sent in as a parameter.  For each of
        # the foreign key variables, instantiate their objects if
        # they've been set.

        # Assign the variables read from the DB into the $self hash.
        do {
            $self->{$var->name()} = $var->value();
        } while ($var = $vars->next());

        # Instantiate any foreign key variables we found.
        foreach my $fk_name (keys %FOREIGN_KEY_VARS) {
            my $fk_spec = $FOREIGN_KEY_VARS{$fk_name};
            confess "Invalid foreign key spec"
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
            confess "Value for $fk_name ($id) is not a valid $fk_class"
              unless defined $object;

            # Save the instantiated object.
            $self->{$fk_name} = $object;
        }

		# Deserialize any serialized variables
        foreach my $ser_var (keys %SERIALIZED_VARS) {
        	my $deser_val = $safe_eval->reval($self->{$ser_var});
        	$self->{$ser_var} = $deser_val if $deser_val;
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
            *{__PACKAGE__."\:\:$fk_name"} = $accessor unless defined *{__PACKAGE__."\:\:$fk_name"};
        }
    }

	foreach my $ser_var (keys %SERIALIZED_VARS) {
        # Create an accessor which uses the __changeSerializedObj method for
        # its implementation.

        my $accessor = sub {
            my $self = shift;
            $self->{$ser_var} = $self->__changeSerializedObj ($ser_var,shift) if scalar @_;
            return $self->{$ser_var};
        };

        # Save this accessor into the current package
        {
            no strict 'refs';
            *{__PACKAGE__."\:\:$ser_var"} = $accessor unless defined *{__PACKAGE__."\:\:$ser_var"};
        }
	}

	# Make read-only accessors for the variables.
	$self->mk_ro_accessors(keys %{$self});

	return $self;
}

sub update {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $factory = shift;
	my $params = shift;
	my $self = {};

	die "new OME::Configuration called without required factory parameter."
		unless $factory;
	
	my ($name,$value);
	while (($name,$value) = each %$params) {

		# If the key of the hash is a foreign key variable, then
		# the value must be an instance of the specified FK
		# class.  If so, then store that object's ID in the
		# database in the specified ID field.

		if (exists $FOREIGN_KEY_VARS{$name}) {
			my $fk_spec = $FOREIGN_KEY_VARS{$name};
			confess "Invalid foreign key spec"
				unless ref($fk_spec) eq 'HASH'
				&& defined $fk_spec->{DBColumn}
				&& defined $fk_spec->{FKClass};

			my $db_column = $fk_spec->{DBColumn};
			my $fk_class = $fk_spec->{FKClass};

			confess "$name must be an instance of $fk_class"
			  unless UNIVERSAL::isa($value,$fk_class);
			_create_update_DB_Object ($factory,$db_column,$value->id());

			$self->{$name} = $value;
			$self->{$db_column} = $value->id();
		} elsif (exists $SERIALIZED_VARS{$name} and ref ($value) eq $SERIALIZED_VARS{$name}) {
			my $value_dumper = Data::Dumper->new([$value]);
			$value_dumper->Indent(0); # Eliminate whitespace
			$value_dumper->Terse(1);  # Eliminate $VAR*n*
			_create_update_DB_Object ($factory,$name,$value_dumper->Dump());
			$self->{$name} = $value;
		} else {
			# Not a foreign key field.  The value cannot be an unregistered
			# reference.  Just create the variable normally,
			# and store it in the $self hash.

			confess "OME::Configuration->new():  Attempt to store a reference as a configuration variable! $name has a reference to ".ref($value)."\n"
			  if ref ($value);

			_create_update_DB_Object ($factory,$name,$value);
			$self->{$name} = $value;
		}
	}
	
	return $self;
}

sub _create_update_DB_Object {
my ($factory,$db_name,$db_value) = @_;

	my $var_object = $factory->findObject('OME::Configuration::Variable', {
		configuration_id => 1,
		name             => $db_name,
	});
	
	if ($var_object) {
		confess "Configuration->update was called without an active session"
			unless OME::Session->hasInstance();
		$var_object->value ($db_value);
		$var_object->storeObject() if OME::Session->hasInstance();
	} else {
		$var_object = $factory->newObject('OME::Configuration::Variable', {
			configuration_id => 1,
			name             => $db_name,
			value            => $db_value,
		}) or confess "Could not create a new OME::Configuration::Variable for $db_name";
	}
	
	return ($var_object);
}



sub __changeObjRef {
	my ($self,$IDvariable,$objectType,$object) = @_;

	# If the objectType is a Bootstrap ST, then accept an ST parameter
	my $ST = $1 if ref($object) =~ /^OME::SemanticType::__(\w+)$/;
	$objectType = "OME::SemanticType::__$ST" if $objectType =~ /^OME::SemanticType::Bootstrap(\w+)$/ and $ST;

	confess "In OME::Configuration->__changeObjRef, expected parameter of type '$objectType', but got '".
		ref($object)."'\n" unless ref($object) eq $objectType;
	confess "In OME::Configuration->__changeObjRef, object '".ref($object)."' is not an OME::DBObject!\n"
		unless UNIVERSAL::isa($object,"OME::DBObject");
	my $factory = $object->Session()->Factory() or die "In OME::Configuration->__changeObjRef, object '".ref($object)."' has no Factory!\n";

	my $IDobject = _create_update_DB_Object ($factory,$IDvariable,$object->id());
	$self->{$IDvariable} = $IDobject->value();
	$self->mk_ro_accessors ($IDvariable);

	return ( $object ) if $IDobject;
	return ( undef );
}

sub __changeSerializedObj {
	my ($self,$ref_name,$the_ref) = @_;

	confess "In OME::Configuration->__changeSerializedObj, expected a reference parameter, but got a scalar"
		unless ref($the_ref) eq $SERIALIZED_VARS{$ref_name};
	my $factory = OME::Session->instance()->Factory()
		or die "In OME::Configuration->__changeSerializedObj, could not get a Factory!\n";

	my $value_dumper = Data::Dumper->new([$the_ref]);
	$value_dumper->Indent(0); # Eliminate whitespace
	$value_dumper->Terse(1);  # Eliminate $VAR*n*
	my $ser_ref = $value_dumper->Dump();

	my $refObject = _create_update_DB_Object ($factory,$ref_name,$ser_ref);
	$self->{$ref_name} = $the_ref;
	$self->mk_ro_accessors ($ref_name);

	return ( $the_ref ) if $refObject;
	return ( undef );
}
1;

=head1 AUTHOR

Ilya Goldberg <igg@nih.gov>, Open Microscopy Environment

=cut
