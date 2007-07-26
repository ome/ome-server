# OME/Web/GuestMenuBuilder.pm
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


package OME::Web::GuestMenuBuilder;

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use CGI qw/-no_xhtml/;

use Carp;

# OME Modules
use OME;
use OME::Web;
use base qw(OME::Web::DefaultMenuBuilder);

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
my $ENABLE_DGAS_ANNOTATIONS = 1;

my @GUEST_MENU = (
	# ** Search **
	{
		web_class => undef,
		type => 'heading',
		text => 'Search',
	},
	{
		web_class => 'OME::Web::Search',
		type => 'link',
		url_param => { SearchType => 'OME::Project' },
		text => 'Projects',
	},
	{
		web_class => 'OME::Web::Search',
		type => 'link',
		url_param => { SearchType => 'OME::Dataset' },
		text => 'Datasets',
	},
	{
		web_class => 'OME::Web::Search',
		type => 'link',
		url_param => { SearchType => 'OME::Image' },
		text => 'Images',
	},
	{
		web_class => 'OME::Web::Search',
		type => 'link',
		url_param => { SearchType => '@CategoryGroup' },
		text => 'Category Group',
	},
	{
		web_class => 'OME::Web::Search',
		type => 'link',
		url_param => { SearchType => 'OME::ModuleExecution' },
		text => 'Module Executions',
	},
	{
		web_class => 'OME::Web::Search',
		type => 'link',
		url_param => { SearchType => 'OME::AnalysisChainExecution' },
		text => 'Chain Executions',
	},
	{
		web_class => 'OME::Web::Search',
		type => 'link',
		text => 'Other',
	},
	# ** Annotate **
 	{
 		web_class => undef,
 		type => 'heading',
 		text => 'Annotation',
 	},
 	{
 		web_class => 'OME::Web::CG_Search',
 		type => 'link',
 		text => 'Search by Annotation',
 	},

        # ** DGAS Annotations ** 
( $ENABLE_DGAS_ANNOTATIONS ? (
 	{
 		web_class => undef,
 		type => 'heading',
 		text => 'DGAS Annotations',
 	},
        {
 		web_class => 'OME::Web::ImageAnnotationTable',
 		type => 'link',
		url_param => { Template=>'GeneProbeTable',
                               Rows => 'Gene',
			       Columns => 'EmbryoStage'},
 		text => 'View AnnotationTable'
 	}
) : () ),
    

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
		web_class => 'OME::Web::Search',
		type => 'link',
		url_param => { SearchType => 'OME::AnalysisChainExecution' },
		text => 'View Chain Results',
	},
	# ** OPTIONS **
	{
		web_class => undef,
		type => 'heading',
		text => 'Options',
	},
	{
		web_class => 'OME::Web::Login',
		type => 'link',
		text => 'Login',
	},
);

sub getMenu {
    my $self = shift;
    return \@GUEST_MENU;
}

1;
