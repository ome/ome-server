#!/usr/bin/perl -w
use Expect;
my $user = shift @ARGV;
my $pass = shift @ARGV;

my $timeout = 600;

my $exp = Expect->spawn('perl', 'install.pl', '-y')
	or die "Cannot spawn install.pl: $!\n";
$exp->expect($timeout,
	[ qr/LSID Authority.+/ => sub { my $exp = shift;
		$exp->send("\n");
		$exp->exp_continue(); } ],
	[ qr/Set password for OME user.+/ => sub { my $exp = shift;
		$exp->send("$pass\n");
		$exp->exp_continue(); } ],
	[ qr/Verify.+/ => sub { my $exp = shift;
		$exp->send("$pass\n");
		$exp->exp_continue(); } ],
	[ qr/URL of the OME Image server.+/ => sub { my $exp = shift;
		$exp->send("\n");
		$exp->exp_continue(); } ],
	[ qr/OME Install Successful.+/ => sub { my $exp = shift;
		$exp->soft_close(); } ],
	[ qr/died.+/ => sub { my $exp = shift;
		$exp->soft_close(); } ],
);
$exp->hard_close();
