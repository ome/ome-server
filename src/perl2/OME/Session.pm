# OME::Session

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


package OME::Session;
our $VERSION = '1.00';

use strict;

use OME::DBObject;
use base qw(OME::DBObject);
use POSIX;


use fields qw(Factory Manager DBH ApacheSession SessionKey);
__PACKAGE__->mk_ro_accessors(qw(Factory Manager DBH ApacheSession SessionKey));
__PACKAGE__->AccessorNames({
    dataset_id      => 'dataset',
    project_id      => 'project',
    analysis_id     => 'analysis',
});

__PACKAGE__->table('ome_sessions');
__PACKAGE__->sequence('session_seq');
__PACKAGE__->columns(Primary => qw(session_id));
__PACKAGE__->columns(Essential => qw(experimenter_id dataset_id project_id last_access));
__PACKAGE__->columns(Others => qw(host image_view feature_view display_settings analysis_id started));
#__PACKAGE__->has_a(experimenter_id => 'OME::AttributeType::__Experimenter',
#b                   inflate => 'load', deflate => 'id');
__PACKAGE__->has_a(dataset_id => 'OME::Dataset');
__PACKAGE__->has_a(project_id => 'OME::Project');
__PACKAGE__->has_a(analysis_id => 'OME::Analysis');


sub closeSession {
    my ($self) = @_;

    # When we log out, break any circular links between the Session
    # and other objects, to allow them all to get garbage-collected.
    $self->{Factory} = undef;
    $self->{Manager} = undef;
}

DESTROY {
    print STDERR "OME::Session->DESTROY\n";
}


# Accessors
# ---------
sub DBH { my $self = shift; return $self->{Manager}->DBH(); }
sub User {
    my $self = shift;
    return $self->Factory()->loadAttribute("Experimenter",
                                           $self->experimenter_id());
}

sub getTemporaryFilename {
    my $self = shift;
    my $progName = shift;
    my $extension = shift;
    my $count=-1;

    my $base_name;
	my $tmpRoot = $self->Configuration()->tmp_dir();
	
	local *FH;
    until (defined(fileno(FH)) || $count++ > 999)
    {
	$base_name = sprintf("%s/%s-%03d.%s", 
				$tmpRoot,
			     $progName,$count,$extension);
	sysopen(FH, $base_name, O_WRONLY|O_EXCL|O_CREAT);
    }
    if (defined(fileno(FH)) )
    {
	close (FH);
	return ($base_name);
    } else {
	return ();
    }
}

# get a scratch directory under a repository
sub getScratchDirRepository {
    my $self = shift;
    my %params = @_;
    my $repository = $params{repository} ||
    	die "OME::Session->getScratchDirRepository was called incorectly!\n";

	return $self->getScratchDir( $params{progName}, $params{extension}, $repository->Path() );

}

# get a scratch directory under OME's tmp dir
sub getScratchDir {
    my $self = shift;
    my $progName = shift;
    my $extension = shift;
    my $tmpRoot = shift;
    $tmpRoot = $self->Configuration()->tmp_dir()
    	unless $tmpRoot;
    my $count=0;
    my $base_name;
	my $dir = undef;
	
	local *DH;
    do {
		$base_name = sprintf("%s/%s-%03d.%s", $tmpRoot,$progName,$count,$extension);
		$base_name =~ s/\/\//\//g;
	    if( opendir( DH, $base_name ) ) {
	    	closedir DH;
	    } else {
	    	$dir = $base_name;
	    }
    } while ( not defined $dir || $count++ > 999);
    if (defined $dir ) {
		mkdir $dir
			or die "Couldn't make directory $dir\n";
		return ($dir);
    } else {
		closedir (DH);
		return ();
    }
}


# added by josiah, 2/6
# centralized place to get configuration table.
sub Configuration {
	my $self = shift;
	# we have exactly one entry in configuration so ID is always 1
	return $self->Factory->loadObject("OME::Configuration", 1);
}

1;

