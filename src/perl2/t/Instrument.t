# -*- perl -*-

# t/014_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Instrument' ); }

my $object = OME::Instrument->new ();
isa_ok ($object, 'OME::Instrument');


