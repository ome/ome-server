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

sub getObjectLabel {
	my ($proto,$obj,$format) = @_;

	if( $obj->module() ) {
		$obj->timestamp() =~ m/(\d+)\-(\d+)\-(\d+) (\d+)\:(\d+)\:(\d+)\..*$/
			or die "Could not parse timestamp ".$obj->timestamp();
		my ( $yr, $mo, $dy, $hr, $min, $sec ) = ($1, $2, $3, $4, $5, $6);
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
		return $obj->module()->name()." ($yr ".$month_abbr{ int($mo) }." ".int($dy).")";
	}

	return $obj->id();
}
=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
