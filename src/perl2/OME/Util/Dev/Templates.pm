# OME/Util/Dev/Templates.pm

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

package OME::Util::Dev::Templates;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Carp;
use OME::Tasks::ModuleExecutionManager;

use Getopt::Long;
Getopt::Long::Configure("bundling");



sub getCommands {
    return
      {
       'update' => 'update',
      };
}

sub update_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:
    $script $command_name [<options>]

This utility will scan the html template directory and register each
template file in the database by creating template attributes. Files
already registered will be ignored.

Options:

	-u all          		Update all template directories.
	-u Display/One  		Update the Display/One directory
	-u Display/Many 		Update the Display/Many directory
	-u Actions/Annotator	Update the Actions/Annotator directory
	-u Browse				Update the Browse directory

USAGE
    CORE::exit(1);
}


sub update {
	my ($self,$commands) = @_;
	my %allowed_paths = (
	#   'Path'        	    => [ 'updateFunction', @parameters_to_pass_into_function ],
		'System/Display/One'       => [ 'updateDisplayTemplates', 'one' ],
		'System/Display/Many'      => [ 'updateDisplayTemplates', 'many' ],
		'System/Actions/Annotator' => [ 'updateAnnotationTemplates'],
		'System/Browse'            => [ 'updateBrowseTemplates' ]
	);
	my $session = $self->getSession();
	my $factory = $session->Factory();
	
	my( $update_dir );
	GetOptions('u=s' => \$update_dir);

	# Error checking, parameter massaging
	if( not defined $update_dir ) {
		die "You must specify a directory to update.";
	} elsif( $update_dir eq 'all' ) {
		$update_dir = [ keys %allowed_paths ];
	} elsif( $update_dir =~ m/,/ ) {
		$update_dir = [ split( m/,/, $update_dir ) ];
	} else {
		$update_dir = [ $update_dir ];
	}
	
	# update every requested directory
	foreach my $tmpl_dir ( @$update_dir ) {
		die "Template directory $tmpl_dir is unknown or unallowed"
			unless( exists $allowed_paths{ $tmpl_dir } );
		print "updating $tmpl_dir...\n";
		my $tmpl_root = $session->Configuration()->template_dir();
		my ( $function, @extra_params ) = @{ $allowed_paths{ $tmpl_dir } };
		# Call the update function
		my( $mex, @new_tmpl_attrs) = $self->$function( $tmpl_root.'/'.$tmpl_dir, @extra_params );
		print "Created ".scalar(@new_tmpl_attrs)." new templates. MEX id is ".$mex->id."\n";
	}
}

sub updateDisplayTemplates {
	my ($self, $tmpl_dir, $arity) = @_;
	my $session = $self->getSession();
	my $factory = $session->Factory();
	my $module = $factory->findObject( 'OME::Module', name => 'Global import' )
		or die "couldn't laod Global import module";
	my $mex = OME::Tasks::ModuleExecutionManager->createMEX($module,'G' )
		or die "Couldn't get mex for Global import";
	my @new_tmpls;
	
	print "\tScanning $tmpl_dir\n";
	my @file_paths = get_template_files( $tmpl_dir, 0);
	foreach my $path (@file_paths) {
		# parse the path
		my $file = $path;
		$file =~ s/$tmpl_dir\/?//;
		my @parts = split( /\//, $file );
		$file = pop @parts;
	
		# figure out mode & object type
		( my $mode = $file ) =~ s/\.tmpl//;
		my $object_type;
		# a DBObject template?
		if( @parts && $parts[0] eq 'OME' ) {
			$object_type = join( '::', @parts );
		# or a ST template?
		} elsif( scalar( @parts) > 0 ) {
			$object_type = '@'.$parts[0];
		}
		# object_type will be blank IFF it's a generic template
		unless ($object_type) {
			$object_type = '_generic';
			$mode        =~ s/generic_//;
		}
	
		# get the file contents
#		open( FH, "< $path" );
#		my $file_contents;
#		while( defined( my $line = <FH> ) ) {
#			$file_contents .= $line;
#		}
#		close(FH);
		$file =~ s/_\d+.tmpl$//;
		my %data_hash = (
			Name       => $file,
			Arity      => $arity,
			Mode       => $mode,
			ObjectType => $object_type,
#			Template   => $file_contents
			Template   => $path
		);
		
		# turn all this into a new DisplayTemplate?
		unless( $factory->findAttribute( "DisplayTemplate", \%data_hash ) ) {
			print "\tCreating new template attribute for $path\n";
			my $new_tmpl = $factory->newAttribute( "DisplayTemplate", undef, $mex, \%data_hash ) 
				or die "Couldn't make a new DisplayTemplate for $path";
			push( @new_tmpls, $new_tmpl );
		}
	}
	$mex->status( 'FINISHED' );
	$mex->storeObject();
	$session->commitTransaction();
	return ($mex, @new_tmpls );
}

sub updateAnnotationTemplates {
	my ($self, $tmpl_dir, $arity) = @_;
	my $session = $self->getSession();
	my $factory = $session->Factory();
	my $module = $factory->findObject( 'OME::Module', name => 'Global import' )
		or die "couldn't laod Global import module";
	my $mex = OME::Tasks::ModuleExecutionManager->createMEX($module,'G' )
		or die "Couldn't get mex for Global import";
	my @new_tmpls;
	
	print "\tScanning $tmpl_dir\n";
	my @file_paths = get_template_files( $tmpl_dir, 1);
	foreach my $path (@file_paths) {
		# parse the path
		my $file = $path;
		$file =~ s/$tmpl_dir\/?//;
		my @parts = split( /\//, $file );
		$file = pop @parts;
		
		# figure out object type
		my $object_type;
		# a DBObject template?
		if( @parts && $parts[0] eq 'OME' ) {
			$object_type = join( '::', @parts );
		# or a ST template?
		} elsif( scalar( @parts) > 0 ) {
			$object_type = '@'.$parts[0];
		}
		
		# object_type will be generic IFF it's a generic template
		$object_type = '_generic' unless ($object_type);
	
		# get the file contents
#		open( FH, "< $path" );
#		my $file_contents;
#		while( defined( my $line = <FH> ) ) {
#			$file_contents .= $line;
#		}
#		close(FH);
		$file =~ s/_\d+.tmpl$//;
		my %data_hash = (
			Name       => $file,
#			Arity      => $arity,
			ObjectType => $object_type,
#			Template   => $file_contents
			Template   => $path,
#			ImplementedBy => ?
		);
		
		# turn all this into a new AnnotationTemplate?
		unless( $factory->findAttribute( "AnnotationTemplate", \%data_hash ) ) {
			print "\tCreating new template attribute for $path\n";
			my $new_tmpl = $factory->newAttribute( "AnnotationTemplate", undef, $mex, \%data_hash ) 
				or die "Couldn't make a new AnnotationTemplate for $path";
			push( @new_tmpls, $new_tmpl );
		}
	}
	$mex->status( 'FINISHED' );
	$mex->storeObject();
	$session->commitTransaction();
	return ($mex, @new_tmpls );
}

sub updateBrowseTemplates {
	my ($self, $tmpl_dir) = @_;
	my $session = $self->getSession();
	my $factory = $session->Factory();
	my $module = $factory->findObject( 'OME::Module', name => 'Global import' )
		or die "couldn't laod Global import module";
	my $mex = OME::Tasks::ModuleExecutionManager->createMEX($module,'G' )
		or die "Couldn't get mex for Global import";
	my @new_tmpls;
	
	print "\tScanning $tmpl_dir\n";
	my @file_paths = get_template_files( $tmpl_dir, 1);
	foreach my $path (@file_paths) {
		# parse the path
		my $file = $path;
		$file =~ s/$tmpl_dir\/?//;
		my @parts = split( /\//, $file );
		$file = pop @parts;
		
		# figure out object type
		my $object_type;
		# a DBObject template?
		if( @parts && $parts[0] eq 'OME' ) {
			$object_type = join( '::', @parts );
		# or a ST template?
		} elsif( scalar( @parts) > 0 ) {
			$object_type = '@'.$parts[0];
		}
		
		# object_type will be generic IFF it's a generic template
		$object_type = '_generic' unless ($object_type);
	
		# get the file contents
#		open( FH, "< $path" );
#		my $file_contents;
#		while( defined( my $line = <FH> ) ) {
#			$file_contents .= $line;
#		}
#		close(FH);
		$file =~ s/_\d+.tmpl$//;
		my %data_hash = (
			Name       => $file,
			ObjectType => $object_type,
#			Template   => $file_contents
			Template   => $path,
#			ImplementedBy => CG_Search.pm
		);
		
		# turn all this into a new BrowseTemplate?
		unless( $factory->findAttribute( "BrowseTemplate", \%data_hash ) ) {
			print "\tCreating new template attribute for $path\n";
			my $new_tmpl = $factory->newAttribute( "BrowseTemplate", undef, $mex, \%data_hash ) 
				or die "Couldn't make a new BrowseTemplate for $path";
			push( @new_tmpls, $new_tmpl );
		}
	}
	$mex->status( 'FINISHED' );
	$mex->storeObject();
	$session->commitTransaction();
	return ($mex, @new_tmpls );
}

sub get_template_files {
	my $root_dir = shift;
	my $depth = shift;
	opendir( DH, $root_dir );
	my( @files, @dirs);
	while( defined (my $file = readdir DH )) {
		next if $file =~ m/^\.|CVS/;
		my $full_path = $root_dir."/".$file;
		if( $file =~ m/\.tmpl$/ ) {
			push @files, $full_path;
		} else {
			push @dirs, $full_path;		
		}
	}
	closedir( DH);
	push @files, get_template_files( $_, $depth+1 ) foreach @dirs;	
	return @files;
}

1;
