#!/usr/bin/perl -w
use Expect;
my $user = shift @ARGV;
my $pass = shift @ARGV;

my $timeout = 600;
my $status = '';

my $exp = Expect->spawn('perl', 'install.pl', '-y')
	or die "Cannot spawn install.pl: $!\n";
$exp->expect($timeout,
	[ qr/LSID Authority.+/ => sub { my $exp = shift;
		$exp->send("\n");
		exp_continue; } ],
	[ qr/Set password for OME user.+/ => sub { my $exp = shift;
		$exp->send("$pass\n");
		exp_continue; } ],
	[ qr/Verify.+/ => sub { my $exp = shift;
		$exp->send("$pass\n");
		exp_continue; } ],
	[ qr/URL of the OME Image server.+/ => sub { my $exp = shift;
		$exp->send("\n");
		exp_continue; } ],
	[ qr/OME Install Successful.+/ => sub { my $exp = shift;
		sleep 1;
		$status = 'SUCCESS';
		$exp->soft_close() } ],
	[ qr/died.+/ => sub { my $exp = shift;
		$status = 'DIED';
		$exp->soft_close(); } ],
	[ timeout => sub { my $exp = shift;
		$status = 'TIMEOUT'; } ],
);

if ($status eq 'SUCCESS') {
	print "Install successful\n";
} elsif ($status eq 'TIMEOUT') {
	print "Time limit of $timeout seconds expired.\n";
} elsif ($status eq 'DIED') {
	print "Install died.\n";
} else {
	print "Install terminated for unknown reasons.\n"
}


