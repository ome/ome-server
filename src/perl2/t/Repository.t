# -*- perl -*-

# t/018_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Repository' ); }

my $object = OME::Repository->new ();
isa_ok ($object, 'OME::Repository');


