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
use OME;
our $VERSION = $OME::VERSION;
use Log::Agent;
use HTML::Template;

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
	my $factory = $self->Session()->Factory();
	my $q = $self->CGI();

	my $mex = $self->_loadObject();
	return $self->SUPER::getPageBody()
		if $mex->virtual_mex();

	( $self->{ form_name } = $q->param( 'Type' ).$q->param( 'ID' ) ) =~ s/[:@]/_/g;
	my $html = $q->startform( -name => $self->{ form_name }  ).
	           $q->hidden(-name => 'Type', -default => $q->param( 'Type' ) ).
	           $q->hidden(-name => 'ID', -default => $q->param( 'ID' ) );
	
	my @actual_inputs = $mex->inputs();
	my @formal_outputs = $mex->module()->outputs();
	@formal_outputs = grep( defined $_->semantic_type(), @formal_outputs );
	my @formal_inputs = $mex->module()->inputs();
	my @untyped_outputs = $mex->untypedOutputs();
	my $tmpl_path = $self->Renderer()->_findTemplate( ref( $mex ), 'detail1' );
	my $tmpl = HTML::Template->new( filename => $tmpl_path, case_sensitive => 1 );
	my %tmpl_data;
	my $tableMaker = OME::Web::DBObjTable->new( CGI => $q );	
	
	############
	#	 Merge outputs
	
	# pick up the previously stored merged groups of outputs
	my @merged_output_groups;
	if( $q->param( 'merged_output_groups' ) ) {
		@merged_output_groups = $q->param( 'merged_output_groups' );
		# remove groups as requested
		@merged_output_groups = grep( $_ ne $q->param( 'UngroupID' ), @merged_output_groups );
		# parse the comma delimited ids
		@merged_output_groups = map( [ split( ',', $_ ) ], @merged_output_groups );
		# turn ids into objects for each merge group
		foreach my $merged_output( @merged_output_groups ) {
			$merged_output = [ map( 
				$factory->loadObject( "OME::Module::FormalOutput", $_ ), 
				@$merged_output ) ];
		}
	}
	
	# pick up recent merge request & store it
	if( $q->param( 'Merge Outputs' ) && $q->param( 'formal_outputs_to_merge' )) {
		my @formal_outputs_to_merge = $q->param( 'formal_outputs_to_merge' );
		# load the formal output object for each id
		@formal_outputs_to_merge = map( 
			$factory->loadObject( "OME::Module::FormalOutput", $_ ), 
			@formal_outputs_to_merge );
		# add to the list of groups
		push( @merged_output_groups, \@formal_outputs_to_merge );
	}
	
	# save formal output groupings 
	my @merged_output_groups_id;
	# make an array that looks like ('id,id,id', 'id,id')
	foreach my $output_set ( @merged_output_groups ) {
		push @merged_output_groups_id, join( ',', map( $_->id(), @$output_set ) );
	}
 	$html .= $q->hidden(
		-name => 'merged_output_groups', 
		-default => \@merged_output_groups_id, 
		-override => 1 
	);


	##############
	#	Start Rendering

	# Execution Details
	$tmpl_data{ mex_detail } = $self->Renderer()->render( $mex, 'detail' );

	# I/O Table
	# input column of i/o table
	$tmpl_data{ input_names } = [ map( { name => $q->a( { href => '#'.$_->name() }, $_->name() ) }, @formal_inputs) ];
	# output column of i/o table
	$tmpl_data{ output_names } = [ map( { 
		name => $q->a( { href => '#'.$_->name() }, $_->name() ),
		checkbox => $q->checkbox( -name => 'formal_outputs_to_merge', -value => $_->id(), -label => '', -checked => undef )
	}, @formal_outputs) ];
	# untyped outputs column of i/o table
	$tmpl_data{ untyped_output_names } = [ map( { 
		name => $q->td( $q->a( { href => '#untyped_'.$_->semantic_type->name() }, $_->semantic_type->name() ) ),
#		checkbox => $q->checkbox( -name => 'untyped_outputs_to_merge', -value => $_->id(), -label => '', -checked => undef )
	}, @untyped_outputs) ];
	# Ouput Groups column
	foreach my $group ( @merged_output_groups ) {
		push( @{ $tmpl_data{ output_groups } }, { 
		group => $q->a( { href => '#'.join( ',', map( $_->id(), @$group ) ) }, join( ', ', map( $_->name(), @$group ) ) ),
		# Should I add an ungroup button here?
		} );
	}
	# button to merge outputs
	$tmpl_data{ merge_button } = $q->submit( -name => 'Merge Outputs' );
	


	# Merged outputs.
	foreach my $group( @merged_output_groups ) {
		my @table_data;
		my $group_id = join( ',', map( $_->id, @{$group} ) );
		foreach my $fo ( @{$group} ) {
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
		push( @{ $tmpl_data{ grouped_outputs } }, { output => 
			$q->a( { 
				-title => 'Click here to Ungroup these Outputs', 
				-href  => "javascript: document.forms['".$self->{ form_name }."'].elements['UngroupID'].value='$group_id'; document.forms['".$self->{ form_name }."'].submit();", 
			}, "Ungroup Outputs" )."<br>".
			$q->a( { -name => $group_id }, ' ').
			join( '<br>', @tables ) 
		} );
	}
	
	# Render outputs ( ungrouped )
	foreach my $fo ( @formal_outputs ) {
		my $attributes = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX($mex,$fo->semantic_type);		
		push( @{ $tmpl_data{ outputs } }, { 
			output => $tableMaker->getTable( 
				{
					noSearch => 1,
					title    => $fo->name(),
					embedded_in_form => $self->{ form_name },
				},
				$self->_STformalName( $fo->semantic_type() ),
				$attributes
			)
		} );
	}
		
	# Untyped Outputs Tables
	foreach my $sto ( @untyped_outputs ) {
		my $attributes = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX($mex,$sto->semantic_type);
		push( @{ $tmpl_data{ untyped_outputs } }, { untyped_output => 
			$q->a( { -name => 'untyped_'.$sto->semantic_type->name() }, ' ').
			$tableMaker->getTable( 
				{
					excludeFields    => { module_execution => undef },
					embedded_in_form => $self->{ form_name },
					title            => $sto->semantic_type->name(),
				},
				$self->_STformalName( $sto->semantic_type() ),
				$attributes
			)
		} );
	}

	# Actual Inputs Tables
	foreach my $ai ( @actual_inputs ) {
		my $attributes = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX($ai->input_module_execution,$ai->formal_input()->semantic_type);
		push( @{ $tmpl_data{ inputs } }, { input => 
			$q->a( { -name => $ai->formal_input()->name() }, ' ' ).
			$tableMaker->getTable( 
				{
					embedded_in_form => $self->{ form_name },
					title            => $ai->formal_input()->name(),
				},
				$self->_STformalName( $ai->formal_input()->semantic_type() ),
				$attributes
			)
		} );
	}
	
	# populate the template & print it out
	$tmpl->param( %tmpl_data );
	$html .= $tmpl->output();
	$q->delete( 'UngroupID' );
	$html .= $q->hidden(-name => 'UngroupID' );
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
