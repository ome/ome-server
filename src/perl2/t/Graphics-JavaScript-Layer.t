# -*- perl -*-

# t/043_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Graphics::JavaScript::Layer' ); }

my $object = OME::Graphics::JavaScript::Layer->new ();
isa_ok ($object, 'OME::Graphics::JavaScript::Layer');


