# -*- perl -*-

# t/032_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::ImportExport::Export_writer' ); }

my $object = OME::ImportExport::Export_writer->new ();
isa_ok ($object, 'OME::ImportExport::Export_writer');


