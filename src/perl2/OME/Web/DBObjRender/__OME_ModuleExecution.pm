# OME/Web/DBObjRender/__OME_ModuleExecution.pm
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


package OME::Web::DBObjRender::__OME_ModuleExecution;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_ModuleExecution - Specialized rendering for OME::ModuleExecution

=head1 DESCRIPTION

Provides custom behavior for rendering an OME::ModuleExecution

=head1 METHODS

=cut

use strict;
use vars qw($VERSION);
use OME;
use OME::Session;
use base qw(OME::Web::DBObjRender);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	
	$self->{ _summaryFields } = [
		'module',
		'timestamp',
		'image',
		'dataset',
		'status',
		 'experimenter'
	];
	$self->{ _allFields } = [
		'id',
		@{ $self->{ _summaryFields } },
		'dependence',
		'virtual_mex',
		'total_time',
		'error_message',
		'iterator_tag',
		'new_feature_tag',
	];
	
	return $self;
}

=head2 _renderData

in summary mode and html format, module will link to a detailed view of the module execution

=cut

sub _renderData {
	my ( $self, $obj, $field_names, $format, $mode, $options ) = @_;
	# override module field to link to MEX detail
	if( grep( m/^module$/, @$field_names ) && $mode eq 'summary' && $format eq 'html' && $obj->module()) {
		my $q = $self->CGI();
		my $module_name = $obj->module()->name();
		return ( module => $q->a( 
			{ 
				href  => $self->getObjDetailURL( $obj ),
				title => "More information about this Module Execution",
				class => 'ome_detail'
			},
			$module_name
		) );
	}
	return ();
}

=head2 _getName

returns module name

=cut

sub _getName {
	my ($self, $obj, $options) = @_;

	if( $obj->module() ) {
		$obj->timestamp() =~ m/(\d+)\-(\d+)\-(\d+) (\d+)\:(\d+)\:(\d+)/
			or die "Could not parse timestamp ".$obj->timestamp();
		my ( $yr, $mo, $dy, $hr, $min, $sec ) = ($1, $2, $3, $4, $5, $6);
		( $mo, $dy, $hr ) = map( int( $_ ), ( $mo, $dy, $hr ) );
		my %month_abbr = (
			1  => 'Jan',
			2  => 'Feb',
			3  => 'Mar',
			4  => 'Apr',
			5  => 'May',
			6  => 'Jun',
			7  => 'Jul',
			8  => 'Aug',
			9  => 'Sep',
			10 => 'Oct',
			11 => 'Nov',
			12 => 'Dec'
		);
		my $name = $obj->module()->name();
return $self->_trim( $name, $options );
		# don't add the date if there is not plenth of room for it and the name
		if( exists $options->{max_text_length} && $options->{max_text_length} < 30 ) {
			my $len = $options->{max_text_length};
			$name =~ s/^(.{$len})....*$/$1\.\.\./;
			return $name;
		} elsif( exists $options->{max_text_length} ) {
			my $len = $options->{max_text_length} - 23;
			$name =~ s/^(.{$len})....*$/$1\.\.\./;
		}
		return $name." ".$month_abbr{$mo}." $dy, $yr $hr:$min";
	}

	return 'Virtual MEX '.$obj->id();
}

=head2 _getRef

returns "[ref to MEX] ran against [ref to target]"

=cut

sub _getRef {
	my ($self, $obj, $format, $options) = @_;

	return $obj->id()
		if( $format eq 'txt' );

	my $q = $self->CGI();
	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $obj );
	return  $q->a( 
		{ 
			href => $self->getObjDetailURL( $obj ),
			title => "Detailed info about this $common_name",
			class => 'ome_detail'
		},
		$self->getName( $obj )
	) . 
	( $obj->image || $obj->dataset ? 
		' ran against ' .
		$self->getRef( $obj->image(), 'html' ) .
		$self->getRef( $obj->dataset(), 'html' ) 
	:
		' execution '. $obj->id
	);
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
