# -*- perl -*-

# t/041_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Graphics::GD' ); }

my $object = OME::Graphics::GD->new ();
isa_ok ($object, 'OME::Graphics::GD');


