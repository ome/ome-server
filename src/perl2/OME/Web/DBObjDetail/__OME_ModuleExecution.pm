# OME/Web/DBObjDetail/__OME_ModuleExecution.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjDetail::__OME_ModuleExecution;

=pod

=head1 NAME

OME::Web::DBObjDetail::__OME_ModuleExecution - Show details of a ModuleExecution

=cut

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use CGI;
use Log::Agent;

use OME;
use OME::Web::DBObjRender;
use OME::Web::DBObjTable;
use OME::Tasks::ModuleExecutionManager;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web::DBObjDetail);

#*********
#********* PUBLIC METHODS
#*********

sub getPageBody {
	my $self = shift;
	my $q = $self->CGI();

	my $mex = $self->_loadObject();
	return $self->SUPER::getPageBody()
		if $mex->virtual_mex();

	( $self->{ form_name } = $q->param( 'Type' ).$q->param( 'ID' ) ) =~ s/[:@]/_/g;
	my $html = $q->startform( { -name => $self->{ form_name } } ).
	           $q->hidden({-name => 'Type', -default => $q->param( 'Type' ) }).
	           $q->hidden({-name => 'ID', -default => $q->param( 'ID' ) }).
	           $q->hidden({-name => 'action', -default => ''});

	my @actual_inputs = $mex->inputs();
	my @formal_outputs = $mex->module()->outputs();
	my @formal_inputs = $mex->module()->inputs();
	my @untyped_outputs = $mex->untypedOutputs();

	# Inputs & Outputs Table
	my $ioTable = $q->table( { -class => 'ome_table' },
		$q->Tr(
			$q->td( { -class => 'ome_td' }, [
				'Inputs', 'Outputs'
			]),
		),
		$q->Tr(
			$q->td( { -class => 'ome_td', -rowspan => 3, -valign => 'top' },
				join( '<br>',map( 
					$q->a( { href => '#'.$_->name() }, $_->name() ),
					@formal_inputs
				) ),
			),
			$q->td( { -class => 'ome_td', -valign => 'top' },
				join( '<br>',map( 
					$q->a( { href => '#'.$_->name() }, $_->name() ),
					@formal_outputs
				) ),
			),
		),
		$q->Tr(
			$q->td( { -class => 'ome_td', -valign => 'top' },
				join( '<br>',map( 
					$q->a( { href => '#untyped_'.$_->semantic_type->name() }, $_->semantic_type->name() ),
					@untyped_outputs
				) ),
			),
		)
	);

	# Big Table
	$html .= $q->table( {-cellpadding => 10 },
		$q->Tr(
			$q->td(  { -width => '50%', -valign => 'top', -align => 'center'}, 
				$self->getObjDetail( $mex )
			),
			$q->td(  { -width => '50%', -valign => 'top', -align => 'center'}, 
				$ioTable
			),
		)
	);

	# Actual Outputs Tables
	my $tableMaker = OME::Web::DBObjTable->new( CGI => $q );
	$html .= $q->h1( 'Outputs' );
	my @table_data;
	foreach my $fo ( @formal_outputs ) {
		next unless $fo->semantic_type;
		my $attributes = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX($mex,$fo->semantic_type);
		push @table_data, {
			title   => $fo->name(),
			type    => $self->_STformalName( $fo->semantic_type() ),
			objects => $attributes
		};
	}
	my @tables = $tableMaker->getJoinTable( 
		{
			excludeFields    => { module_execution => undef },
			embedded_in_form => $self->{ form_name },
		},
		\@table_data
	);
	$html .= join( '<br>', @tables );

	# Untyped Outputs Tables
	$html .= $q->h1( 'Untyped Outputs' );
	foreach my $sto ( @untyped_outputs ) {
		my $attributes = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX($mex,$sto->semantic_type);
		$html .= 
			$q->a( { -name => 'untyped_'.$sto->semantic_type->name() }, ' ').
			$tableMaker->getTable( 
				{
					excludeFields    => { module_execution => undef },
					embedded_in_form => $self->{ form_name },
					title            => $sto->semantic_type->name(),
				},
				$self->_STformalName( $sto->semantic_type() ),
				$attributes
			);
	}

	# Actual Inputs Tables
	$html .= $q->h1( 'Inputs' );
	foreach my $ai ( @actual_inputs ) {
		my $attributes = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX($ai->input_module_execution,$ai->formal_input()->semantic_type);
		$html .= 
			$q->a( { -name => $ai->formal_input()->name() }, ' ' ).
			$tableMaker->getTable( 
				{
					embedded_in_form => $self->{ form_name },
					title            => $ai->formal_input()->name(),
				},
				$self->_STformalName( $ai->formal_input()->semantic_type() ),
				$attributes
			);
	}
	
	$html .= $q->endform();

	$self->_takeAction( );

	return ('HTML', $html);
}

sub _STformalName {
	my ($self, $ST) = @_;
	return '@'.$ST->name();
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
