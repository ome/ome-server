# -*- perl -*-

# t/049_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Graphics::GD::Vectors' ); }

my $object = OME::Graphics::GD::Vectors->new ();
isa_ok ($object, 'OME::Graphics::GD::Vectors');


