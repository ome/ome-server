#!/usr/bin/perl -w
use Expect;

my $timeout = 1800;
my $time_limit_reached;

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
		exp_continue; } ],
	[ qr/Password.+/ => sub { my $exp = shift;
		$exp->send("$pass\n");
		exp_continue; } ],
	[ timeout => sub { my $exp = shift;
		print "Timeout of $timeout seconds expired\n";
		$time_limit_reached = 1; } ],

);

