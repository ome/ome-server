# -*- perl -*-

# t/020_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Session' ); }

my $object = OME::Session->new ();
isa_ok ($object, 'OME::Session');


