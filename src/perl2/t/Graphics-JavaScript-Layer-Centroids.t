# -*- perl -*-

# t/044_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Graphics::JavaScript::Layer::Centroids' ); }

my $object = OME::Graphics::JavaScript::Layer::Centroids->new ();
isa_ok ($object, 'OME::Graphics::JavaScript::Layer::Centroids');


