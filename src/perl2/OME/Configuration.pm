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

sub import_module {
	my $self = shift;
	$self->changeObjRef ('import_module_id','OME::Module',shift) if scalar @_;
	return ( $self->Factory()->loadObject ('OME::Module',$self->import_module_id()) );
}
sub import_chain {
	my $self = shift;
	$self->changeObjRef ('import_chain_id','OME::AnalysisChain',shift) if scalar @_;
	return ( $self->Factory()->loadObject ('OME::AnalysisChain',$self->import_chain_id()) );
}


sub changeObjRef {
	my ($self,$IDvariable,$objectType,$object) = @_;
	die "In OME::Configuration->changeObjRef, expected parameter of type '$objectType', but got '".
		ref($object)."'\n" unless ref($object) eq $objectType;
	my $factory = $self->Factory();
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
