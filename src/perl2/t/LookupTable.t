# -*- perl -*-

# t/015_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::LookupTable' ); }

my $object = OME::LookupTable->new ();
isa_ok ($object, 'OME::LookupTable');


