# Author:  Ilya G. Goldberg (igg@mit.edu)
# Copyright 1999-2001 Ilya G. Goldberg
# This file is part of OME.
# 
#     OME is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     OME is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with OME; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# 
#

package OMEfeature;
use strict;
use vars qw($AUTOLOAD);

#
# The data members of this class are specified by calling new with a list of attributes and optionally values.
# An attribute is specified as TABLE.COLUMN as it exists in the OME database.  The only exception
# is the attribute that allways exists which is the feature ID.  It is specified as 'ID'.
# The class will not contain any data members other than the ones specified with this call (ID will always exist).
# The class has methods to get a list of features associated with a praticular dataset, a particular analysis, etc.
# These return a list of Feature objects.  Other methods are for changing specified attributes of the
# the features, and for writing them to the databse.
# This class needs some methods from the OMEpl class, but is not really an inherited class.  More like an
# interface.  Normally, one wouldn't call the new method directly - one would call one of the methods that produce
# a list.  The new method only makes an instance of the OMEfeature class - it does not make a new feature in the OME
# database.  To make a new feature in the OME database associated with a particular analysis+dataset, call NewOMEfeature.
# In this case, attributes specified for the analysis must be passed in as parameters (not necessarily with pre-set values), and
# additional parameters may be specified.  These are "user" parameters, and will not end up in the database.

# The parameters are named:
# ID => $featureID,  # Required!
# Table.Column => $attributeValue
# There can be one or more Table.column parameters
# 
sub new
{
	my $proto = shift;
	my %params = @_;
	my $attribute;

	my $class = ref($proto) || $proto;
	my $self = {
		ID  => undef
	};

	foreach $attribute (keys %params)
	{
		$self->{$attribute} = $params{$attribute};
	}

	bless ($self, $class);
	
	return $self;
}









sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self)
		or die "$self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully-qualified portion

	return if $name eq 'DESTROY';
	
	unless (exists $self->{$name} ) {
    	die "Can't access `$name' field in class $type";
	}

	if (@_) {
	# Can't set the ID once its set.
		if ($name ne 'ID' || ! defined $self->{ID}) { return $self->{$name} = shift; }
		else { return $self->{$name}; }
	} else {
    	return $self->{$name};
	}
}



1;
