# OME/Web/ManageRelationships.pm
# Web class for managing many to many and one to many maps between OME
# database objects (DBObjects).

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
# Written by:    Chris Allan <callan@blackcat.ca>
#
#-------------------------------------------------------------------------------


package OME::Web::ManageRelationships;

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use CGI;
use Carp;
use Data::Dumper;
use UNIVERSAL::require;

# OME Modules
use OME;
use OME::Web::Table;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web);

#*********
#********* PRIVATE METHODS
#*********

sub __findAccessor {
	my ($self, $object, $r_type) = @_;

	my $relationships = ref($object)->getReferences();

	foreach (keys(%$relationships)) {
		if ($relationships->{$_} eq $r_type) { return $_ }
	}

	return;
}

sub __addRelations {
	my ($self, $o_type, $r_type, $oid, @relations) = @_;

	my ($m_package, $modifier);  # Manager package and modifier method
	
	# Yes, I'm only supporting one way at the moment...
	if ($o_type eq 'OME::Project' and $r_type eq 'OME::Dataset') {
		$m_package = 'OME::Tasks::ProjectManager';
		$modifier = 'addDatasets';
	} elsif ($o_type eq 'OME::Dataset' and $r_type eq 'OME::Image') {
		$m_package = 'OME::Tasks::DatasetManager';
		$modifier = 'addImages';
	} else {
		croak "Automatic addition of '$o_type' relations of type '$r_type' unsupported.";
	}
	
	my @relation_ids = map ($_->id(), @relations);  # Foreach magick
	
	local *relation_modifier;
	*relation_modifier = $m_package . '::' . $modifier;

	$m_package->require();
	my $manager = new $m_package;
	relation_modifier($manager, \@relation_ids, $oid);
}

sub __remRelations {
	my ($self, $o_type, $r_type, $oid, @relations) = @_;
}

sub __getGenericBody {
	my ($self, $o_type, $r_type, $oid) = @_;
	my $q = $self->CGI();
	my $session = $self->Session();
	my $factory = $session->Factory();

	my $body;

	# CGI Parameteres
	my $action = $q->param('action');
	my @add_selected = $q->param('add_selected');
	my @rem_selected = $q->param('rem_selected');
	
	# Cleanup CGI parameters
	$q->delete_all();

	my @t;

	# Get objects from selected items
	foreach (@add_selected) { push(@t, $factory->loadObject($r_type, $_)); }
	@add_selected = @t; undef(@t);
	foreach (@rem_selected) { push(@t, $factory->loadObject($r_type, $_)); }
	@rem_selected = @t; undef(@t);

	if ($action eq 'Add') {
		$self->__addRelations($o_type, $r_type, $oid, @add_selected);
		$body .= $q->p({class => 'ome_info'}, 'Addition successful.');
	} elsif ($action eq 'Remove') {
		$self->__remRelations($o_type, $r_type, $oid, @add_selected);
		$body .= $q->p({class => 'ome_error'}, 'Sorry: Function un-implemented.');
		# FIXME -- Going to leave this until we get the Managers doing DBObject
		# based deletes.
	}


	my $object = $factory->loadObject($o_type, $oid)
		or croak "Unable to load object '$o_type' id '$oid'";
	my $accessor = $self->__findAccessor($object, $r_type) 
		or croak "Unable to find '$r_type' accessor in '$o_type'";

	local *relation_accessor;

	*relation_accessor = $o_type . '::' . $accessor;  # Typeglob voodoo

	print STDERR "*DEBUG*\n";
	my @relations = relation_accessor($object);
	print STDERR "*DEBUG*\n";
	my @relation_ids = map ($_->id(), @relations);  # Foreach magick

	my @non_relations;

	if (@relation_ids) {
		# Objects of $r_type not in the object
		@non_relations = $factory->findObjectsLike(
			$r_type, {id => ['NOT IN', [@relation_ids]]});
	} else {
		# All objects of type $r_type
		@non_relations = $factory->findObjects($r_type);
	}

	# Generic table generator
	my $t_generator = new OME::Web::Table;

	$body .= $t_generator->getTable( {
			select_column => 1,
			select_name => 'rem_selected',
			options_row => ['Remove'],
			parent_form => 1,
		}, @relations);

	$body .= $q->p();

	$body .= $t_generator->getTable( {
			select_column => 1,
			select_name => 'add_selected',
			options_row => ['Add'],
			parent_form => 1,
		}, @non_relations);

	return $body;
}

#*********
#********* PUBLIC METHODS
#*********

# Override's OME::Web
sub getPageTitle {
    return "Open Microscopy Environment - Manage Relationships"; 
}

# Override's OME::Web
sub getMenuText { return undef; }

# Override's OME::Web
sub getOnLoadJS {
	my $js = <<JS;
for (i = 0; i < document.datatable.length; i++)
{
	if (document.datatable.elements[i].type == "checkbox")
		document.datatable.elements[i].checked = false;
}
JS

	return $js;
}

# Override's OME::Web
sub getPageBody {
    my $self = shift;
    my $q = $self->CGI();
	
	foreach ($q->param()) {
		print STDERR "*DEBUG* PARAM[$_]: ", $q->param($_), "\n";
	}

	# Type of the OME object we're managing the relationships of
	my $o_type = $q->param('o_type');

	# OME Object ID
	my $oid = $q->param('oid');

	# Type of OME relationship object
	my $r_type = $q->param('r_type');

	my $body = $q->startform({name => 'datatable'});

	# o_type *hidden*
	$body .= $q->hidden({name => 'o_type', default => $o_type});
	
	# r_type *hidden*
	$body .= $q->hidden({name => 'r_type', default => $r_type});
	
	# oid *hidden*
	$body .= $q->hidden({name => 'oid', default => $oid});
	
	# action *hidden*
	$body .= $q->hidden({name => 'action'});

	$body .= $self->__getGenericBody($o_type, $r_type, $oid);

	$body .= $q->endform();
	
	return ('HTML', $body);
}


1;
