# OME/Web/GetGraphics.pm
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


package OME::Web::DatasetOnGoogleMaps;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

use OME::Tasks::ImageManager;
use OME::Tasks::PixelsManager;
use HTML::Template;
use base qw{ OME::Web };

use Benchmark;

=pod

=head1 NAME

OME::Web::DatasetOnGoogleMaps - A proof of concept

=head1 DESCRIPTION

This overlays image in a dataset onto google maps.

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);

	return $self;
}

sub createOMEPage {
	my $self  = shift;
	my $q	  = $self->CGI();
	my $session = $self->Session();
	my $factory = $session->Factory();

	my $DatasetID = $q->param( 'DatasetID' )
		or die "A DatasetID param is required.";

	my $dataset = $factory->loadObject( 'OME::Dataset', $DatasetID )
		or die "Could not load dataset $DatasetID";
	my @images = $dataset->images();
	
	my $pixelsInfoList = "[\n";
	my $datasetArea = 0;
	foreach my $image( @images ) {
		my $pixels = $image->default_pixels();
		my $moreInfo = $self->Renderer()->render( $image, 'GoogleMapInfo' );
		$moreInfo =~ s/'/\\'/g;
		$pixelsInfoList .= "\t{ ".
			"'id': ".$pixels->ImageServerID.", ".
			"'omeis_url': '".$pixels->Repository->ImageServerURL()."', ".
			"'moreInfo': '". $moreInfo . "'".
			" },\n";
		$datasetArea += $pixels->SizeX() * $pixels->SizeY();
	}
	my $scaleFactor = ( 300000 / ( $datasetArea + scalar( @images ) * ($datasetArea / 50) ) ) ** .5;
	$pixelsInfoList .= "];\n";
	
	# Load & populate the template
	my $tmpl_dir = $self->actionTemplateDir();
	my $tmpl = HTML::Template->new( 
		filename => "DatasetOnGoogleMaps.tmpl",
		path     => $tmpl_dir,
		case_sensitive => 1 );
	$tmpl->param(
		pixelsInfoList => $pixelsInfoList,
		name => $dataset->name(),
		imageScale => $scaleFactor, #.05, #1200000 / $datasetArea, 
		# You must register at http://www.google.com/apis/maps/signup.html to 
		# receive a key for your domain.
		# lgopt2: ABQIAAAAdZqyUVgsyagVhMg3j_sQrBRYtPFswSmyvycW8u65UfdBSplTthQEu3mX7aTyqjIsIyDc0SorhBda_Q
		# lgopt2.grc.nia.nih.gov: ABQIAAAAdZqyUVgsyagVhMg3j_sQrBS0Z9c9NshV1w6uG9mOYMVkHDiQIBTb7KgMtqi7W9N9v3DQ56oh5h3h6g
		apiKey => 'ABQIAAAAdZqyUVgsyagVhMg3j_sQrBRYtPFswSmyvycW8u65UfdBSplTthQEu3mX7aTyqjIsIyDc0SorhBda_Q', 
#		debug => "dArea: $datasetArea   scaleFactor = $scaleFactor<br>",
	);
	my $html = $tmpl->output();
	return('HTML', $html);
}


1;
