# -*- perl -*-

# t/037_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::ImportExport::STKreader' ); }

my $object = OME::ImportExport::STKreader->new ();
isa_ok ($object, 'OME::ImportExport::STKreader');


