# -*- perl -*-

# t/042_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Graphics::JavaScript' ); }

my $object = OME::Graphics::JavaScript->new (ImageID => 123, Dims=>[1,2,3,4,5,6]);
isa_ok ($object, 'OME::Graphics::JavaScript');


