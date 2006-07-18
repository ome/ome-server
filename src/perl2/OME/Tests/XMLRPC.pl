#!perl -w
use Term::ReadKey;
use Data::Dumper;
use Safe;

use XMLRPC::Lite 
on_fault => sub { my($soap, $res) = @_; 
      die ref $res ? $res->faultstring : $soap->transport->status, "\n";
    };
    

my $host = $ARGV[0] || 'http://localhost/shoola/';
print <<END_PRINT;
XMLRPC command-line tester for OME
(you can specify the host as an argument to this script)

You will first need to login to OME and get a SessionKey.
After this, you can call any available method and supply any
required parameters.  The exact call and the result will be reported.
If the result is not a primitive type, it will be deparsed into perl syntax.
When prompted, enter one parameter per line.
The parameters will be evaled, so you can send arrays and hashes specified in perl syntax.
Terminate parameter entry with a blank line.

Using OME server '$host'

END_PRINT

print "Please login to OME:\n";

print "Username? ";
ReadMode(1);
my $username = ReadLine(0);
chomp($username);

print "Password? ";
ReadMode(2);
my $password = ReadLine(0);
chomp($password);
print "\n";
ReadMode(1);


use SOAP::Lite;

my $soap = XMLRPC::Lite
  -> proxy ($host);

$soap->on_debug(sub { print @_ })
  if $ARGV[1];

#print $soap
#  ->call('whichToolkit')
#  ->result();

#exit;

my ($method,$result);
my @params;

$method = 'createSession';
@params = ($username,$password);
print "Calling $method ($username,***PASSWORD HIDDEN***)\n";
my $session = $soap
	-> call ($method => @params)
	-> result;

print "Got '$session'\n\n";
die unless $session;


my $RPCmethod;
while (1) {
	print "Method? ";
	ReadMode(1);
	$RPCmethod = ReadLine(0);
	chomp($RPCmethod);
	last unless $RPCmethod;
	
	my $line;
	my $safe = new Safe;
	$method = 'dispatch';
	@params = ($session,$RPCmethod);

	print "Parameters:\n";
	ReadMode(1);
	do {
		$line = ReadLine(0);
		chomp($line);
		$line = $safe->reval ($line) if $line;
		push (@params,$line) if $line;
	} while ($line);
	
	print "Calling $method (".join (', ',@params).")\n";
	$result = $soap
	  ->call($method => @params)
	  ->result();
	print "Got '$result'\n";
	print Dumper ($result) if ref ($result);
	print "\n\n";
}


$method = 'closeSession';
@params = ($session);
print "Calling $method (".join (', ',@params).")\n";
$result = $soap
  ->call($method => @params)
  ->result();

print "OME::Remote::Dispatcher::closeSession\nGot '$result'...\n\n";
