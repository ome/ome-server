# -*- perl -*-

# t/046_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Graphics::JavaScript::Layer::Vectors' ); }

my $object = OME::Graphics::JavaScript::Layer::Vectors->new ();
isa_ok ($object, 'OME::Graphics::JavaScript::Layer::Vectors');


