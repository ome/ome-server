#!perl -w
use Term::ReadKey;
use SOAP::Lite 
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



my $host = $ARGV[0] || 'http://localhost/soap/SOAP.pl';
use SOAP::Lite;

my $soap = SOAP::Lite
    -> uri   ('OME/SessionManager')
    -> proxy ($host);

my $sessionMgr = $soap
	-> call (new => undef)
	-> result;

print "Got SessionManager.  isa ".ref ($sessionMgr)."\n";

my $session = $soap
	-> call (createSession => ($sessionMgr,$username,$password))
	-> result;

print "Got Session.  isa ".ref($session)."\n" if defined $session and $session;

$soap->uri ('OME/Session');
my $sessionKey = $soap
	-> call (SessionKey => ($session))
	-> result;
print "Session key: ",$sessionKey,"\n";

my $experimenter = $soap
	-> call (experimenter => ($session))
	-> result;
print "Got Experimenter.  isa ".ref($experimenter)."\n" if defined $experimenter and $experimenter;

$soap->uri ('OME/Experimenter');
print "First: ",$soap->call (firstname => ($experimenter))->result,"\n";
print "Last:  ",$soap->call (lastname => ($experimenter))->result,"\n";
print "email: ",$soap->call (email => ($experimenter))->result,"\n";



