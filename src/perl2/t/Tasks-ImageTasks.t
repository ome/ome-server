# -*- perl -*-

# t/028_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Tasks::ImageTasks' ); }

my $object = OME::Tasks::ImageTasks->new ();
isa_ok ($object, 'OME::Tasks::ImageTasks');


