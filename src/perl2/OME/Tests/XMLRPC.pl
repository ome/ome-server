#!perl -w
use Term::ReadKey;
use XMLRPC::Lite 
on_fault => sub { my($soap, $res) = @_; 
      die ref $res ? $res->faultstring : $soap->transport->status, "\n";
    };
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


my $host = $ARGV[0] || 'http://localhost:8002/';
use SOAP::Lite;

my $soap = XMLRPC::Lite
  -> proxy ($host);

$soap->on_debug(sub { print @_ })
  if $ARGV[1];

#print $soap
#  ->call('whichToolkit')
#  ->result();

#exit;

my $session = $soap
  -> call ("createSession" => $username, $password)
  -> result;

print "OME::Remote::Dispatcher::createSession\nGot '$session'...\n\n";

my ($result);

$result = $soap
  ->call(dispatch => $session, $session, "Factory")
  ->result();

print "session->Factory\nGot '$result'...\n\n";
my $factory = $result;


$result = $soap
  ->call(dispatch => $session, $factory, "loadObject", "OME::Program", 1)
  ->result();

print "factory->loadObject\nGot '$result'...\n\n";
my $program = $result;


$result = $soap
  ->call(closeSession => $session)
  ->result();

print "OME::Remote::Dispatcher::closeSession\nGot '$result'...\n\n";
