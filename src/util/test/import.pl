#!/usr/bin/perl -w
use Expect;

my $timeout = 120;

print "Importing images.  Command line:\n$0 ";
print "'$_'" foreach @ARGV;
print "\n";

my $user = shift @ARGV;
my $pass = shift @ARGV;

my $exp = Expect->spawn('ome', 'import', @ARGV)
	or die "Cannot spawn ome import: $!\n";
$exp->expect($timeout,
	[ qr/Username.+/ => sub { my $exp = shift;
		$exp->send("$user\n");
		$exp->exp_continue(); } ],
	[ qr/Password.+/ => sub { my $exp = shift;
		$exp->send("$pass\n");
		$exp->exp_continue(); } ],
	[ qr/Exiting.+/ => sub { my $exp = shift;
		$exp->soft_close(); } ],
);

$exp->hard_close();
