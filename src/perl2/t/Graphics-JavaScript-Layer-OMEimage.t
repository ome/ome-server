# -*- perl -*-

# t/045_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Graphics::JavaScript::Layer::OMEimage' ); }

my $object = OME::Graphics::JavaScript::Layer::OMEimage->new ();
isa_ok ($object, 'OME::Graphics::JavaScript::Layer::OMEimage');


