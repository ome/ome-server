# needs to be ran from OME/src/perl2

my $failures = 0;
my $tests = 4;

die "Could not make temporary directory!\n" if system("mkdir tmp") ne 0;
die "insertBinData returned an error!\n" if system("/OME/bin/insertBinData Insert-ExtractBinDataTest.xml > tmp/insert_output.ome") ne 0;
die "extractBinData returned an error!\n" if system("/OME/bin/extractBinData tmp/ tmp/ tmp/insert_output.ome > tmp/extract_output.ome") ne 0;
if (`diff tmp/1.out ../../perl2/t/tinyTest-BE.raw 2>&1`) {
	print "bzip2 test failed on a BigEndian file!\n";
	$failures++;
}
if (`diff tmp/2.out ../../perl2/t/tinyTest-BE.raw 2>&1`) {
	print "zlib test failed on a BigEndian file!\n";
	$failures++;
}
if (`diff tmp/3.out ../../perl2/t/tinyTest-LE.raw 2>&1`) {
	print "bzip2 test failed on a LittleEndian file!\n";
	$failures++;
}
if (`diff tmp/4.out ../../perl2/t/tinyTest-LE.raw 2>&1`) {
	print "zlib test failed on a LittleEndian file!\n";
	$failures++;
}
die "Could not remove temporary directory!\n" if system("rm -rf tmp") ne 0;

print "Pixel insertion & extraction works fine!\n" if $failures eq 0;
print "Failed $failures/$tests tests.\n" if $failures ne 0;
