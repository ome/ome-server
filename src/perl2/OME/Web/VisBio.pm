# OME/Web/VisBio.pm

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
# Written by:   Curtis Rueden <ctrueden@wisc.edu>
#				Tom Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------

package OME::Web::VisBio;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use base qw(OME::Web);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);

	return $self;
}

sub createOMEPage{
	my $self = shift;
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $cgi  = $self->CGI();
	
	my $id = $cgi->url_param('ImageID');
	my $user = $cgi->url_param('user');
	my $server = $cgi->url_param('server');
	
	if (not $id) {	
		return ('HTML', "ERROR: ImageID must be specified. e.g. 'OME::Web::VisBio&ImageID=3'");
	}

	# load system defaults
	if (not defined $server) {
		$server = `hostname`;
		chop($server);
	}
	if (not defined $user) {
		$user = $factory->loadObject( 'OME::SemanticType::BootstrapExperimenter', $session->User->id)->OMEName();
	}
	$self->contentType('application/x-java-jnlp');

	# Output JNLP file with proper arguments
	my $jnlp;
	
	$jnlp .= "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
	$jnlp .= "<jnlp\n";
	$jnlp .= "  spec=\"1.0+\"\n";
	$jnlp .= "  codebase=\"http://www.loci.wisc.edu/visbio/jws\">\n";
	$jnlp .= "  <information>\n";
	$jnlp .= "    <title>VisBio</title>\n";
	$jnlp .= "    <vendor>UW-Madison LOCI</vendor>\n";
	$jnlp .= "    <homepage href=\"http://www.loci.wisc.edu/visbio/index.html\"/>\n";
	$jnlp .= "    <description>A biological visualization tool designed for easy\n";
	$jnlp .= "      visualization and analysis of multidimensional image data</description>\n";
	$jnlp .= "    <icon href=\"visbio-icon.jpg\"/>\n";
	$jnlp .= "    <icon kind=\"splash\" href=\"visbio-logo.jpg\"/>\n";
	$jnlp .= "    <offline-allowed/>\n";
	$jnlp .= "  </information>\n";
	$jnlp .= "  <security>\n";
	$jnlp .= "    <all-permissions/>\n";
	$jnlp .= "  </security>\n";
	$jnlp .= "  <resources>\n";
	$jnlp .= "    <j2se version=\"1.4+\" max-heap-size=\"512m\"/>\n";
	$jnlp .= "    <jar href=\"visbio.jar\"/>\n";
	$jnlp .= "    <jar href=\"commons-httpclient-2.0-rc2.jar\"/>\n";
	$jnlp .= "    <jar href=\"commons-logging.jar\"/>\n";
	$jnlp .= "    <jar href=\"forms-1.0.4.jar\"/>\n";
	$jnlp .= "    <jar href=\"ij.jar\"/>\n";
	$jnlp .= "    <jar href=\"looks-1.2.2.jar\"/>\n";
	$jnlp .= "    <jar href=\"ome-java.jar\"/>\n";
	$jnlp .= "    <jar href=\"visad.jar\"/>\n";
	$jnlp .= "    <jar href=\"xmlrpc-1.2-b1.jar\"/>\n";
	$jnlp .= "  </resources>\n";
	$jnlp .= "  <application-desc main-class=\"loci.visbio.VisBio\">\n";
	$jnlp .= "    <argument>ome-image=$user\@$server:$id</argument>\n";
	$jnlp .= "  </application-desc>\n";
	$jnlp .= "</jnlp>\n";
	
	return ('JNLP', $jnlp, 'LaunchVisBio.jnlp');
}
1;