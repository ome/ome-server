#!/usr/bin/perl
use strict;

my ($t_file_path, $t_file_size) = ( "Sample.ome", 26248 );

my ($returnMsg, $fileID, $localPath);
my ($n_tests, $n_passes, $system_return) = ( 0, 0, 0 );

undef $/;

$n_tests++;
print "testing uploadFile...\n";
open( UPLOAD_FILE, "cat Sample.ome | ../omeis Method=UploadFile UploadSize=$t_file_size File=$t_file_path |" );
$returnMsg = <UPLOAD_FILE>;
$fileID = $1 if( $returnMsg =~ m/^Content-Type: text\/plain\s+(\d+)/ );
close( UPLOAD_FILE );
if( $fileID ) {
	print "\tTest Passed. FileID = $fileID\n" ;
	$n_passes++; 
} else {
	print "\tTest Failed. UploadFile returned:\n'$returnMsg'\n";
}

$n_tests++;
print "testing GetLocalPath...\n";
open( GET_LOCAL_PATH, "../omeis Method=GetLocalPath FileID=$fileID |" );
$returnMsg = <GET_LOCAL_PATH>;
$localPath = $1 if( $returnMsg =~ m/^Content-Type: text\/plain\s+(\S+)/ );
close( GET_LOCAL_PATH );
if( $localPath ) {
	print "\tTest Passed. LocalPath = $localPath\n" ;
	$n_passes++; 
} else {
	print "\tTest Failed. GetLocalPath returned:\n'$returnMsg'\n";
}

$n_tests++;
print "testing FileInfo...\n";
$system_return = system( "../omeis Method=FileInfo FileID=$fileID > FileInfo; diff FileInfo _FileInfo > /dev/null" );
if( $system_return == 0 ) {
	print "\tTest Passed.\n" ;
	$n_passes++; 
} else {
	print "\tTest Failed. FileInfo return message is in file 'FileInfo'\n";
}

$n_tests++;
print "testing FileSHA1...\n";
$system_return = system( "../omeis Method=FileSHA1 FileID=$fileID > FileSHA1; diff FileSHA1 _FileSHA1 > /dev/null" );
if( $system_return == 0 ) {
	print "\tTest Passed.\n" ;
	$n_passes++; 
} else {
	print "\tTest Failed. FileSHA1 return message is in file 'FileInfo'\n";
}

$n_tests++;
print "testing ReadFile...\n";
$system_return = system( "../omeis Method=ReadFile FileID=$fileID Offset=0 Length=$t_file_size > ReadFile; diff ReadFile _ReadFile > /dev/null" );
if( $system_return == 0 ) {
	print "\tTest Passed.\n" ;
	$n_passes++; 
} else {
	print "\tTest Failed. ReadFile return message is in file 'ReadFile'\n";
}

$n_tests++;
print "testing ImportOMEfile...\n";
open( IMPORT_OME_FILE, "../omeis Method=ImportOMEfile FileID=$fileID > ImportOMEfile; diff ImportOMEfile _ImportOMEfile |" );
$returnMsg = <IMPORT_OME_FILE>;
close( IMPORT_OME_FILE );
if( $returnMsg =~ m/^124c124\s*<\s*<External xmlns="http:\/\/www\.openmicroscopy\.org\/XMLschemas\/BinaryFile\/RC1\/BinaryFile\.xsd" href="\d+" SHA1=""\/><\/Pixels>\s*---\s*>\s*<External xmlns="http:\/\/www\.openmicroscopy\.org\/XMLschemas\/BinaryFile\/RC1\/BinaryFile\.xsd" href="\d+" SHA1=""\/><\/Pixels>\s*$/ ) {
	print "\tTest Passed.\n" ;
	$n_passes++; 
} else {
	print "\tTest Failed. $returnMsg ImportOMEfile return message is in file 'ImportOMEfile'\n";
}

print "Passed all $n_tests tests!\n" if ( $n_tests == $n_passes );
print "Failed ".($n_tests - $n_passes)."/$n_tests tests.\n" unless ( $n_tests == $n_passes );

=pod

# add tests for NewPixels, SetPixels, SetPlane, SetStack, SetROI, ConvertFile, and FinishPixels
echo "testing GetPlaneStats..."
../omeis Method=GetPlaneStats PixelsID=1
echo "testing PixelsInfo..."
../omeis Method=PixelsInfo PixelsID=1
echo "testing PixelsSHA1..."
../omeis Method=PixelsSHA1 PixelsID=1
echo "testing GetPixels..."
../omeis Method=GetPixels PixelsID=1 > GetPixels; diff GetPixels _GetPixels
echo "testing GetPlane..."
../omeis Method=GetPlane PixelsID=1 theZ=0 theC=0 theT=0 > GetPlane; diff GetPlane _GetPlane
echo "testing GetStack..."
../omeis Method=GetStack PixelsID=1 theC=0 theT=0 > GetStack; diff GetStack _GetStack
echo "testing GetROI..."
../omeis Method=GetROI PixelsID=1 ROI=0,0,0,0,0,1,1,1,0,0 > GetROI; diff GetROI _GetROI
=cut
