# OME/Web/DBObjRender/__OME_Task.pm
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
#	Ilya Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjRender::__OME_Task;
use base qw(OME::Web::DBObjRender);

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Web::DBObjRender);


=pod

=head1 NAME

OME::Web::DBObjRender::__OME_Task

=head2 _renderData

makes virtual fields thumb_url and original_file
original file doesn't make sense for images with multiple source files

=cut

sub _renderData {
	my ($self, $obj, $field_requests, $options) = @_;
	my %record;

	# start time
	if( exists $field_requests->{ 't_elapsed' } ) {
		foreach my $request ( @{ $field_requests->{ 't_elapsed' } } ) {
			my $request_string = $request->{ 'request_string' };

			# create a virtual column "t_elapsed" in the table
			my ($t6, $t5, $t4, $t3, $t2, $year, $wday, $yday, $isdst) = localtime(time);
			$t2 += 1; # month range is from 0 to 11 not 1 to 12
		
			my $t_start = $obj->t_start();
			my $t_stop  = $obj->{"__fields"}->{tasks}->{"t_stop"};
			
			use integer;
			$t_start =~ m/^(\d*)-(\d*)-(\d*) (\d*):(\d*):(\d*)/;
			my $sec_start = ((($2 * 30 + $3) * 24 + $4) * 60 + $5) * 60 + $6;
	
			my $sec_stop;
			if (defined($t_stop) and $t_stop ne 'now') {
				$t_stop =~ m/^(\d*)-(\d*)-(\d*) (\d*):(\d*):(\d*)/;
				$sec_stop  = ((($2 * 30 + $3) * 24 + $4) * 60 + $5) * 60 + $6;
			} else {
				$sec_stop  = ((($t2 * 30 + $t3) * 24 + $t4) * 60 + $t5) * 60 + $t6;
			}
			
			my $remain_sec = $sec_stop - $sec_start;
			my $hrs  = $remain_sec / (60*60);
			$remain_sec -= $hrs * (60*60);
			my $mins = $remain_sec / 60;
			$remain_sec -= $mins * 60;
			
			$record{ $request_string }
				= sprintf("%02d:%02d:%02d", $hrs, $mins, $remain_sec);		
		}
	}
	
	return %record;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
