# OME/Web/DBObjRender/__OME_ModuleExecution_SemanticTypeOutput.pm
#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institute of Technology,
#		National Institutes of Health,
#		University of Dundee
#
#
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#
# Written by:  
#	Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjRender::__OME_ModuleExecution_SemanticTypeOutput;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_ModuleExecution_SemanticTypeOutput -
Specialized rendering for OME::ModuleExecution::SemanticTypeOutput

=head1 DESCRIPTION

Provides custom behavior for rendering an OME::ModuleExecution::SemanticTypeOutput

=head1 METHODS

=cut

use strict;
use vars qw($VERSION);
use OME;
use OME::Web;
use OME::Tasks::ModuleExecutionManager;
use base qw(OME::Web::DBObjRender);

# Class data
__PACKAGE__->_fieldLabels( {
	'id'             => "ID",
});
__PACKAGE__->_fieldNames( [
	'id',
	'module_execution',
	'semantic_type',
] ) ;
__PACKAGE__->_allFieldNames( [
	@{__PACKAGE__->_fieldNames() },
] ) ;

sub getObjectLabel {
	my ($proto,$obj,$format) = @_;

	return $obj->semantic_type()->name()
		if( $obj->semantic_type() );
	return $obj->id();
}

=head2 getRelationAccessors

DBObject methods + attributes

=cut

sub getRelationAccessors {
	my ($proto,$obj) = @_;

	my ($objects, $methods, $params, $return_types, $names, $titles, $call_as_scalar )
		= $proto->__gather_PublishedManyRefs( $obj );

	my $object      = 'OME::Tasks::ModuleExecutionManager';
	my $method      = 'getAttributesForMEX';
	my $return_type = $obj->semantic_type();
	my $mex         = $obj->module_execution();
	my $param       = [$mex,$return_type];
	my $name        = 'attributes';
	my $title       = 'Attributes';

	push( @$objects,        \$object);
	push( @$methods,        $method);
	push( @$params,         $param);
	push( @$return_types,   $return_type);
	push( @$names,          $name);
	push( @$titles,         $title);
	push( @$call_as_scalar, 1);

	my $iterator = OME::Web::DBObjRender::RelationIterator->new( 
		$objects, $methods, $params, $return_types, $names, $titles, $call_as_scalar );
	return $iterator;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
