# -*- perl -*-

# t/048_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Graphics::GD::Centroids' ); }

my $object = OME::Graphics::GD::Centroids->new ();
isa_ok ($object, 'OME::Graphics::GD::Centroids');


