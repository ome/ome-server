# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 8 };
use Repacker;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$str =  $stri = "abcd"; $cnt = &Repacker::repack($stri, 4, 1, 1, 1);  print $cnt == 4 && $stri eq $str ? "ok 2" : "not ok 2", "\n";
$str = $stri = "abcd"; $cnt = &Repacker::repack($stri, 4, 2, 1, 1); print $cnt == 4 && $stri == $str ? "ok 3" : "not ok 3", "\n";
$str = $stri = "abcd"; $cnt = &Repacker::repack($stri, 4, 4, 1, 1); print $cnt == 4 && $stri == $str ? "ok 4" : "not ok 4", "\n";
$stri = "abcd"; $cnt = &Repacker::repack($stri, 4, 2, 0, 1);  print $cnt == 4 && $stri eq "badc" ? "ok 5" : "not ok 5", "\n";
$str = $stri = "abcd"; $cnt = &Repacker::repack($stri, 4, 4, 0, 1); print $cnt == 4 && $stri == reverse($str) ? "ok 6" : "not ok 6", "\n";
$str = $stri = "abcd"; $cnt = &Repacker::repack($stri, 4, 1, 1, 1); print $cnt == 4 && $stri == $str ? "ok 7" : "not ok 7", "\n";
$stri = "abcd"; $cnt = &Repacker::repack($stri, 4, 5, 1, 1); print $cnt == 0 ? "ok 8" : "not ok 8", "\n";

