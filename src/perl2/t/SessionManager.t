# -*- perl -*-

# t/021_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::SessionManager' ); }

my $object = OME::SessionManager->new ();
isa_ok ($object, 'OME::SessionManager');


