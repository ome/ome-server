#!/usr/bin/perl -w
use strict;
use CGI;
use Graphics::JavaScript;
use Graphics::JavaScript::Layer::Vectors;
use Graphics::JavaScript::Layer::Centroids;
use Graphics::GD::Vectors;
use Graphics::GD::Centroids;
use Benchmark;

my $cgi = new CGI();
my $JSgraphics = new Graphics::JavaScript (theZ=>1,theT=>0);
my $JSvec1 = $JSgraphics->AddLayer (new Graphics::JavaScript::Layer::Vectors (
	allZ=>1, allT=>1, color=>'blue', name=>"Vectors1", LayerCGI=>'GetGraphics.pl'
	));
my $JSvec2 = $JSgraphics->AddLayer (new Graphics::JavaScript::Layer::Vectors (
	allZ=>1, allT=>0, color=>'red', name=>"Vectors2", LayerCGI=>'GetGraphics.pl'
	));

my $JScen1 = $JSgraphics->AddLayer (new Graphics::JavaScript::Layer::Centroids (
	allZ=>1, allT=>0, color=>'green', name=>"Centroids1", LayerCGI=>'GetGraphics.pl'
	));

my @params = $cgi->url_param();
if ( $cgi->url_param('DrawLayersControls') ) {
	DrawLayersControls($cgi,$JSgraphics);
} elsif ( $cgi->url_param('name') ) {
	DrawGraphics ($cgi,$JSgraphics);
} else {
	DrawMainWindow ($cgi,$JSgraphics);
}

undef $JSgraphics;
undef $cgi;

sub DrawMainWindow {
my $cgi = shift;
my $JSgraphics = shift;
my $JS;
$JS = <<ENDJS;
	function MakePopup () {
		var popup = window.open('GetGraphics.pl?DrawLayersControls=1', 'cal', 'dependent=yes, width=300, height=300, screenX=0, screenY=0, titlebar=yes');
		if (!popup.opener) popup.opener = self;
	}
ENDJS



	print $cgi->header(),
		$cgi->start_html(-title=>'Graphics Test', -script=>$JS.$JSgraphics->JSobjectDefs());
	print qq `<center><h3><a href="javascript:MakePopup()">Layers</a></h3></center>\n`;
	print $JSgraphics->JSinstance ('position:absolute; left:0; top:35; visibility:visible; border-width:1 border-style:solid border-color:black');

	print $cgi->end_html;
}

sub DrawGraphics {
my $cgi = shift;
my $JSgraphics = shift;
my @string;
use GD;
my %X = (
	Vectors1 => 0,
	Vectors2 => 120,
	Centroids1 => 240,
	);
my $Y=0;
	my %params;
	foreach ($cgi->url_param()) {
		$params{$_} = $cgi->url_param($_);
		push (@string,$_.' = '.$cgi->url_param($_));
	}
	$params{allZ} = $params{allZ} eq 'true' ? 1 : 0;
	$params{allT} = $params{allT} eq 'true' ? 1 : 0;
	$params{width} = 782;
	$params{height} = 854;
	$params{color} = Graphics::JavaScript::Layer->X11Colors->{$params{color}};
	my $type = delete $params{layerType};
	print STDERR "DrawGraphics\n".join ("\n",@string)."\n";
	my $layer = eval ("new Graphics::GD::$type (%params)");
	$layer->Draw ();

	my $black = $layer->{image}->colorResolve(1,1,1);
	foreach (@string) {
		$layer->{image}->string(gdSmallFont,$X{$params{name}},$Y,$_,$black);
		$Y += 12;
	}

	print $cgi->header('image/png');
	print $layer->{image}->png;
#my $centroids = new Graphics::GD::Centroids (image => $layer->{image}, width=>782, height=>854, color=>[0,0,255]);

}


sub DrawLayersControls {
my $cgi = shift;
my $JSgraphics = shift;

	print $cgi->header(),
		$cgi->start_html(-title=>'Layers Popup');
	print $JSgraphics->Form('opener');
	print $cgi->end_html;
}
