# OME/Web/DefaultMenuBuilder.pm
# Default menu generation class for a non-overriden getPageMenu()

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
# Written by:    Chris Allan <callan@blackcat.ca>
#
#-------------------------------------------------------------------------------


package OME::Web::DefaultMenuBuilder;

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use CGI;
use Carp;

# OME Modules
use OME;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;

my @MENU = (
	# ** CREATE **
	{
		web_class => undef,
		type => 'heading',
		text => 'Create',
	},
	{
		web_class => 'OME::Web::MakeNewProject',
		type => 'link',
		text => undef,
	},
	{
		web_class => 'OME::Web::MakeNewDataset',
		type => 'link',
		text => undef,
	},
	{
		web_class => 'OME::Web::ImportFiles',
		type => 'link',
		text => undef,
	},
	# ** BROWSE **
	{
		web_class => undef,
		type => 'heading',
		text => 'Browse',
	},
	{
		web_class => 'OME::Web::DBObjTable',
		type => 'link',
		url_param => { Type => 'OME::Project' },
		text => 'Project',
	},
	{
		web_class => 'OME::Web::DBObjTable',
		type => 'link',
		url_param => { Type => 'OME::Dataset' },
		text => 'Dataset',
	},
	{
		web_class => 'OME::Web::DBObjTable',
		type => 'link',
		url_param => { Type => 'OME::Image' },
		text => 'Image',
	},
	{
		web_class => 'OME::Web::DBObjTable',
		type => 'link',
		url_param => { Type => 'OME::ModuleExecution' },
		text => 'Module Executions',
	},
#	{
#		web_class => 'OME::Web::ImageTable',
#		type => 'link',
#		text => undef,
#	},
#	{
#		web_class => 'OME::Web::ProjectTable',
#		type => 'link',
#		text => undef,
#	},
#	{
#		web_class => 'OME::Web::DatasetTable',
#		type => 'link',
#		text => undef,
#	},
#	{
#		web_class => 'OME::Web::MEXTable',
#		type => 'link',
#		text => undef,
#	},
	# ** XML **
	{
		web_class => undef,
		type => 'heading',
		text => 'XML',
	},
	{
		web_class => 'OME::Web::XMLFileExport',
		type => 'link',
		text => undef,
	},
	#{
	#	web_class => 'N/A',
	#	type => 'link',
	#	text => 'Import Image(s)',
	#},
	# ** ANALYSIS **
	{
		web_class => undef,
		type => 'heading',
		text => 'Analysis',
	},
	{
		web_class => 'OME::Web::FindSpots',
		type => 'link',
		text => undef,
	},
	{
		web_class => 'OME::Web::ExecuteChain',
		type => 'link',
		text => undef,
	},
	{
		web_class => 'OME::Web::ViewMEXresults',
		type => 'link',
		text => undef,
	},
	# ** OPTIONS **
	{
		web_class => undef,
		type => 'heading',
		text => 'Options',
	},
	{
		web_class => 'OME::Web::Logout',
		type => 'link',
		text => undef,
	},
);


#*********
#********* PRIVATE METHODS
#*********

# Accessors
sub __getWebClass { return shift->{'__web_class'} }
sub __getWebInstance { return shift->{'__web_instance'} }
sub __getMenuLinkage { return shift->{'__class_header_linkage'} }
sub __CGI { return shift->{'__CGI_pm'} }

# Session Macro (Pseudo-private)
sub Session { OME::Session->instance() }

sub __getMenuEntryOfCurrentClass { 
	my $self = shift;
	my $web_instance = $self->__getWebInstance();
	my $web_class    = $self->__getWebClass();
	my $q = $web_instance->CGI();
	
	my @menu_entries = grep( $_->{web_class} eq $web_class, @MENU );
	return $menu_entries[0] if scalar( @menu_entries ) eq 1;
	
	foreach my $entry ( @menu_entries ) {
		next unless $entry->{url_param};
		my $url_params_Match = 1;
		foreach my $url_param( %{ $entry->{url_param} } ) {
			$url_params_Match = 0
				unless $q->url_param( $url_param ) eq $entry->{url_param}->{$url_param};
		}
		return $entry if $url_params_Match;
	}
	
	return undef;
}

sub __preProcessMenu {
	my ($self, @menu) = @_;

	my $linkage = {};  # Class->Heading linkage
	my $active_heading = 'HEAD';
	
	foreach my $element (@menu) {
		if ($element->{'type'} eq 'heading') {
			$active_heading = $element->{'text'};
		} elsif ($element->{'type'} eq 'link') {
			$linkage->{$element->{'web_class'}} = $active_heading;
		} else {
			croak "Unknown menu element type: '$element->{'type'}'";
		}
	}

	return $linkage;
}

sub __processElement {
	my ($self, $menu_element) = @_;
	my $q = $self->__CGI();

	my $element_data;
	my $current_web_class = $self->__getWebClass();
	my $current_web_instance = $self->__getWebInstance();
	my $current_menu_entry    = $self->__getMenuEntryOfCurrentClass();

	my $css_class = 'ome_main_menu_heading';
	my $web_class = $menu_element->{'web_class'};

	# HEADING
	if ($menu_element->{'type'} eq 'heading') {
		# Build TR
		$element_data .= $q->Tr($q->td(
			{class => $css_class, align => 'center'},
			$q->span({class => 'ome_main_menu_heading'}, $menu_element->{'text'})
		));
	# LINK
	} elsif ($menu_element->{'type'} eq 'link') {
		# Pick CSS class
		if ($current_menu_entry eq $menu_element) {
			$css_class = 'ome_main_menu_link_active';
		} else {
			$css_class = 'ome_main_menu_link';
		}

		# Get link text
		my $text;
		$web_class->require();

		if( $menu_element->{'text'} ) {
			$text = $menu_element->{'text'};
		} else {
			if ($web_class->can('getMenuText')) {
				$text = $web_class->getMenuText();
			}
		}

		# Get HREF
		my $href = $web_class->pageURL($web_class, $menu_element->{ url_param } );

		# Build TR
		$element_data .= $q->Tr($q->td(
			{class => $css_class},
			$q->a({class => $css_class, href => $href}, $text)
		));
	} else {
		carp "Unknown menu type '$menu_element->{'type'}'";
	}

	return $element_data;
}

#*********
#********* PUBLIC METHODS
#*********

sub new {
	my ($proto, $web_instance) = @_;
	my $class = ref($proto) || $proto;

	# Need this for highlighting
	croak "Unable to decern the identity of the web class."
		unless defined $web_instance;
		
	my $self = {
		__web_class => ref( $web_instance ), 
		__web_instance => $web_instance,
		__CGI_pm => new CGI,
	};

	# Bless so we can call methods
	$self = bless($self, $class);

	# Build our linkage hashref
	$self->{'__class_header_linkage'} = $self->__preProcessMenu(@MENU);

	return $self;
}

sub getPageMenu {
	my $self = shift;
	my $q = $self->__CGI();

	my $menu_data;

	# Process @MENU
	foreach my $menu_element (@MENU) {
		$menu_data .= $self->__processElement($menu_element);
	}

	return $q->table({width => '100%', class => 'ome_main_menu'}, $menu_data);
}

sub getPageLocationMenu {
	my $self = shift;
	my $q = $self->__CGI();

	my $linkage = $self->__getMenuLinkage();
	my $web_instance = $self->__getWebInstance();
	my $web_class = $self->__getWebClass();
	my $current_entry = $self->__getMenuEntryOfCurrentClass();
	my $class_header = $linkage->{$web_class};

	# Make sure the class is loaded
	my $menu_text;
	if( $current_entry->{ text } ) {
		$menu_text = $current_entry->{ text };
	} elsif ($web_instance->can('getMenuText')) {
		$menu_text = $web_instance->getMenuText();
	}

	# OME::Web::Home specific
	if ( UNIVERSAL::isa( $web_instance, 'OME::Web::Home') ) {
		return $q->span({class => 'ome_quiet'},
			"Home");
	}

	return $q->span({class => 'ome_quiet'},
		"Home -> $class_header -> " . $menu_text);
}


1;
