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

The Configuration object is used to get configuration variables established when
OME was installed.  In normal use, the variables are read only, and the Configuration
object is retreived from the L<C<OME::Session>|OME::Session> object.

The constructor can be called from an installation script and passed a configuration hash
along with an L<C<OME::Factory>|OME::Factory> object:

	my $conf = new OME::Configuration ($factory,{var1 => 123, var2 => 'foo'});

If there are already configuration variables in the DB, the hash will be ignored.
An L<C<OME::Configuration::Variable>|OME::Configuration::Variable> object will be loaded for each variable in the DB.
If the DB does not contain configuration variables, a new L<C<OME::DBObject>|OME::DBObject> of type
L<C<OME::Configuration::Variable>|OME::Configuration::Variable> will be made for each key-value pair in the hash,
and written to the DB.  The names of the L<C<OME::Configuration::Variable>|OME::Configuration::Variable> objects will be made available as
methods of Configuration, returning the value of the variable when called.  From the example above, C<$conf-E<gt>var1()>
will return I<123>.
The two mutator methods are described below.

=head1 METHODS

=cut


package OME::Configuration;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(Class::Accessor);

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

	foreach my $var (@vars) {
		$self->{$var->name()} = $var->value();
	}

	# only pay attention to the params if we don't have any variables stored in the DB yet.
	# The set of variables is write once.
	if (not scalar @vars) {
		my ($name,$value);
		while (($name,$value) = each %$params) {
			die "OME::Configuration->new():  Attempt to store a reference as a configuration variable! $name has a reference to ".ref($value)."\n"
				if ref ($value);
			$self->{$name} = $value if $factory->newObject('OME::Configuration::Variable', {
				configuration_id => 1,
				name => $name,
				value => $value
			});
		}
	}

	bless($self,$class);

	# Make read-only accessors for the variables.
	$self->mk_ro_accessors(keys %{$self});

	return $self;
}

=head2 import_module

accessor/mutator for the import_module configuration variable.  This methods sets/gets
an L<C<OME::Module>|OME::Module> object.  The ID of this object is stored in import_module_id().

=cut

sub import_module {
	my $self = shift;
	$self->{import_module} = $self->__changeObjRef ('import_module_id','OME::Module',shift) if scalar @_;
	return ( $self->{import_module} );
}


=head2 import_chain

accessor/mutator for the import_chain configuration variable.  This methods sets/gets
an L<C<OME::AnalysisChain>|OME::AnalysisChain> object.  The ID of this object is stored in import_chain_id().

=cut

sub import_chain {
	my $self = shift;
	$self->{import_chain} = $self->__changeObjRef ('import_chain_id','OME::AnalysisChain',shift) if scalar @_;
	return ( $self->{import_chain} );
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
