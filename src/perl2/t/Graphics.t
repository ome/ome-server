# -*- perl -*-

# t/011_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Graphics' ); }

my $object = OME::Graphics->new ();
isa_ok ($object, 'OME::Graphics');


