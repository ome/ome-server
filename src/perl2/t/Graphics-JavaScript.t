# -*- perl -*-

# t/042_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Graphics::JavaScript' ); }

my $object = OME::Graphics::JavaScript->new ();
isa_ok ($object, 'OME::Graphics::JavaScript');


