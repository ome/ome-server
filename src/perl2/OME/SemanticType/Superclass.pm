# OME/SemanticType/Superclass.pm

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


package OME::SemanticType::Superclass;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use Class::Data::Inheritable;
use base qw(OME::DBObject Class::Data::Inheritable);
__PACKAGE__->mk_classdata('_attribute_type');

use Carp;
use Log::Agent;
use fields qw(_data_table_rows _target _module_execution _id );
use vars qw($AUTOLOAD);

=head1 NAME

OME::SemanticType::Superclass

=head1 DESCRIPTION

The C<AttributeType::Superclass> class is the superclass every piece of
semantically-typed data in OME.  This includes attributes created by
the user during image import, and any attributes created as output by
the execution of module_execution modules.

Each attribute has a single semantic type, which is represented by an
instance of L<AttributeType>.  Based on the semantic type's
granularity, the attribute will be a property of (or, equivalently,
has a target of) a dataset, image, or feature, or it will be a global
attribute (and have a target of C<undef>.)

Most attributes will be generated computationally as the result of an
analysis module.  The module_execution (and by extension, module) which
generated the attribute can be retrieved with the L<getAnalysis()>
method.

=head1 METHODS

The following methods are available to all attribute subclasses.  In
addition, accessor/mutator methods will automatically be created for
each semantic element in the attribute's semantic type. Finally,
accessor methods for has-many relationships will be dynamically created
as they are called. For example,
	$categoryGroup->CategoryList();
will result in a has-many accessor transparently being created and
called. AUTOLOAD magic is used to implement this functionality.

=cut

=pod

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($session,$target,$id,$rows) = @_;

    die "Cannot create attribute without data rows"
      if !scalar(%$rows);

    my $self = {};
    $self->{_data_table_rows} = $rows;
    $self->{_target} = $target;
    $self->{_id} = $id;

    my $module_execution;
    foreach my $row (values %$rows) {
        $module_execution = $row->module_execution();
        last if defined $module_execution;
    }
    $self->{_module_execution} = $module_execution;

    bless $self, $class;
    return $self;
}

sub load {
    my ($proto,$session,$id) = @_;
    my $class = ref($proto) || $proto;

    my $rows = {};
    my ($target,$module_execution);
    my $factory = $session->Factory();

    my $semantic_type = $class->_attribute_type();
    my $granularity = $semantic_type->granularity();
    my $semantic_elements = $semantic_type->semantic_elements();
	my $found_data_row = 0;

    while (my $semantic_element = $semantic_elements->next()) {
        my $data_column = $semantic_element->data_column();
        my $data_table = $data_column->data_table();
        my $data_table_pkg = $data_table->requireDataTablePackage();
        my $data_tableID = $data_table->id();
        next if exists $rows->{$data_tableID};

        my $data_row = $factory->loadObject($data_table_pkg,$id);
		next unless defined $data_row;
		$found_data_row = 1;

        $rows->{$data_tableID} = $data_row;

        if (!defined $target) {
            if ($granularity eq 'D') {
                $target = $data_row->dataset();
            } elsif ($granularity eq 'I') {
                $target = $data_row->image();
            } elsif ($granularity eq 'F') {
                $target = $data_row->feature();
            }
        }

        if (!defined $module_execution) {
            $module_execution = $data_row->module_execution();
        }
    }

	return undef unless $found_data_row;
    return $class->new($session,$target,$id,$rows);
}

=cut

=head2 verifyType

	$attribute->verifyType($type_name);

Ensures that this attribute has the given semantic type.  If not, an
exception is thrown.  The semantic type is specified by name, and is
retrieved using the factory that created the attribute.

=cut

sub verifyType {
    my ($self, $type_name) = @_;
    die "Object is not an attribute"
      unless UNIVERSAL::isa($self,__PACKAGE__);
    my $type = $self->_attribute_type();
    my $real_name = $type->name();
    die "Attribute is of the wrong type: Expected $type_name, got $real_name"
      unless $type_name eq $real_name;
    return 1;
}

=head2 id

	my $id = $attribute->id();

Returns the primary key ID of the attribute.

=head2 Session

	my $session = $attribute->Session();

Returns the OME session used to create this attribute.

=head2 semantic_type

	my $semantic_type = $attribute->semantic_type();

Returns the semantic type of this attribute.

=head2 module_execution

	my $module_execution = $attribute->module_execution();

Returns the module_execution that generated this attribute, or undef if it was
created directly by the user.

=cut

sub ID { return shift->id(); }
sub semantic_type { return shift->_attribute_type(); }

=head2 getDataHash

	my $data_hash = $attribute->getDataHash();

Returns a reference to a hash of all of the semantic elements of the
attribute and their values.  This hash will not include entries for
the module_execution, target, semantic type, or primary key ID.

=cut

sub getDataHash {
    my ($self) = @_;

    my %return_hash;

    my $semantic_type = $self->_attribute_type();
    my @columns = $semantic_type->semantic_elements();

    foreach my $column (@columns) {
        my $column_name = $column->name();
        my $value = $self->$column_name();
        $return_hash{$column_name} = $value;
    }

    return \%return_hash;
}

=head2 dataset, image, feature

	my $dataset = $attribute->dataset();
	my $image = $attribute->image();
	my $feature = $attribute->feature();

Returns the target of this attribute.  Only the method appropriate to
the granularity of the attribute's semantic type will be defined.

=head2 storeObject

	$attribute->storeObject();

This instance methods writes any unsaved changes to the database.

=cut

=head2 getFormalName

	my $formal_name = $class->getFormalName();

Returns the formal name of the semantic type. i.e. @Semantic_Type_Name.
Overrides method in DBObject

=cut

sub getFormalName {
    my $proto = shift;
    return '@'.$proto->semantic_type()->name();
}

=head2 getInferredHasMany

	my @all_possible_has_many_accessors = 
		__PACKAGE__->getInferredHasMany();
	
This is similar, but distinct from getHasMany. In addition to returning
the has-many accessors that were declared at package creation, it
discovers every possible has-many relationship to any SemanticType.

i.e.
	$experimenter->getInferredHasMany();
Will return:
	( RenderingSettingsList, GroupListByLeader, GroupListByContact
	  ExperimenterGroup, ExperimentList, DatasetAnnotationList,
	  ImageAnnotationList )

Notice that 'ExperimenterGroup' is included and 'OME::Image' is not. It
does an exhaustive search across STs, but not DBObjects defined in
packages. It does not distiguish many-to-many mapping STs from other
STs. It rides on a completely relational model without inferred or
explicit structural descriptions. We humans know ExperimenterGroup is a
mapping class because of the naming convention, its set of elements (2
references), and it's written description. The only part of that to do
definitive inference on is the pair of reference elements. Writing code
to indentify ExperimenterGroup as a mapping table that should basically
be hidden is the beginning of implementing a more semantically rich
modeling environment than can be given by a relational model.

Accessors for the discovered relationships will be created dynamically
via AUTOLOAD magic. The naming convention is [ST_returned].'List'
(i.e. ExperimentList), or when ambiguity arises because of multiple
relations, [ST_returned].'ListBy'.[SE_link] (i.e. GroupListByLeader,
GroupListByContact)

These inferred has-many relationships will never be returned by
getHasMany.

=cut

sub getInferredHasMany {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    # Find all SEs that refer to this package. 
	my $factory = $proto->getFactory();
    my @reference_elements_to_me = $factory->
      findObjects('OME::SemanticType::Element',
                  {
                   'data_column.sql_type'       => 'reference',
                   'data_column.reference_type' => $proto->semantic_type()->name(),
                  });

	# Group reference SEs by ST
	my ( %foreign_key_class_by_STs, %ST_package_names );
	foreach my $element (@reference_elements_to_me) {
		my $st                = $element->semantic_type();
		my $foreign_key_class = '@'.$st->name();
		push( 
			@{ $foreign_key_class_by_STs{$foreign_key_class} },
			$element->name()
		);
		$ST_package_names{ $foreign_key_class } = $st->getAttributeTypePackage();
	}

	# Examine each relationship, discard ones that are flagged as
	# explicitly defined, flag ones that are discovered, and store
	# their proper accessor names.
    my %inferredHasMany;
	foreach my $foreign_key_class (sort keys %foreign_key_class_by_STs) {
	    my @foreign_key_alias_list = sort @{ $foreign_key_class_by_STs{ $foreign_key_class } };
		foreach my $foreign_key_alias ( @foreign_key_alias_list ) {
			# strip the leading '@' from the st name when compiling the method name
			my $method_name = substr( $foreign_key_class, 1 ).'List';
			# a simple name is ambiguous if there are more than one foreign keys
			$method_name .= 'By'.$foreign_key_alias
				if( scalar(@foreign_key_alias_list) > 1);
			# skip this relationship if it's been explicitly defined.
			# This step is completely unnecessary until we expand STDs
			next if( $proto->__wasRelationshipExplicitlyDefined( $foreign_key_class, $foreign_key_alias ) );
			$inferredHasMany{ $method_name } = $ST_package_names{$foreign_key_class};
			# record method & mark as inferred
			$proto->__hasManysReverseLookup()->{ $foreign_key_class }{ $foreign_key_alias } = [ $method_name, 1 ];
# FIXME: Add remote prototypes entry?
		}
	}
	
	return \%inferredHasMany;
}


# Returns ( $foreign_key_class, $foreign_key_alias ) if $alias follows syntax
# conventions of inferred has-many accessors and the relationship is
# valid. Otherwise, returns undef.
# Overrides DBObject method
sub __parseHasManyAccessor {
	my ($proto, $alias) = @_;
	my $class = ref( $proto ) || $proto;
	my $factory = $proto->getFactory();

	if( $alias =~ m/^(count_)?(\w+)List(By)?(\w+)?$/ ) {
		my $foreign_key_class = $2;
		my $foreign_key_alias = $4;
		my $st = $factory->findObject( 'OME::SemanticType', name => $foreign_key_class )
			or return undef;
		# foreign key alias is optional if there is only one appropriate alias
		# if it was unspecified, figure out what it is
		unless( $foreign_key_alias ) {
			my @foreign_key_alias_canidates = $factory->
			  findObjects('OME::SemanticType::Element',
						  {
						   'data_column.sql_type'       => 'reference',
						   'data_column.reference_type' => $proto->semantic_type->name,
						   'semantic_type'              => $st
						  });
			return undef
				if scalar( @foreign_key_alias_canidates ) ne 1;
			$foreign_key_alias = $foreign_key_alias_canidates[0]->name;
		}
		return ( '@'.$foreign_key_class, $foreign_key_alias );
	}
	return undef;
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

