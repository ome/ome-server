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

# Class data
__PACKAGE__->_fieldLabels( {
	'id'             => "ID",
});
__PACKAGE__->_fieldNames( [
	'id',
	'module',
	'timestamp',
	'image',
	'dataset',
	'status',
] ) ;
__PACKAGE__->_allFieldNames( [
	@{__PACKAGE__->_fieldNames() },
	'dependence',
	'virtual_mex',
	'total_time',
	'error_message',
	'iterator_tag',
	'new_feature_tag',
] ) ;

=head2 getObjectLabel

returns module name & formatted timestamp

=cut

sub getObjectLabel {
	my ($proto,$obj) = @_;

	if( $obj->module() ) {
		$obj->timestamp() =~ m/(\d+)\-(\d+)\-(\d+) (\d+)\:(\d+)\:(\d+)\..*$/
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
		return $obj->module()->name()." ($yr ".$month_abbr{ $mo }." $dy $hr:$min:$sec)";
	}

	return $obj->id();
}

#=head2 renderSingle
#
#Module links to MEX
#
#=cut
#
#sub renderSingle {
#	my ($proto,$obj,$format,$fieldnames) = @_;
#	
#	my $factory = $obj->Session()->Factory();
#	my $q       = new CGI;
#	my @filtered_field_names = grep( !m/^module$/, @$fieldnames);
#	my $record  = $proto->SUPER::renderSingle($obj,$format,\@filtered_field_names);
#
#	# override module field to link to MEX detail
#	if( scalar( @filtered_field_names ) ne scalar( @$fieldnames ) and $obj->module()) {
#		my $module_name = $obj->module()->name();
#		my $detail_url = "serve.pl?Page=OME::Web::DBObjDetail&Type=OME::ModuleExecution&ID=".$obj->id();
#		$record->{ 'module' } = $q->a( 
#			{ 
#				href  => $detail_url,
#				title => "More information about this Module Execution",
#				class => 'ome_detail'
#			},
#			$module_name
#		) if( $format eq 'html' );
#		$record->{ 'module' } = $module_name
#			if( $format eq 'txt' );
#	}
#	
#	return %$record if wantarray;
#	return $record;
#}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
