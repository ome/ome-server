# -*- perl -*-

# t/010_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Feature' ); }

my $object = OME::Feature->new ();
isa_ok ($object, 'OME::Feature');


