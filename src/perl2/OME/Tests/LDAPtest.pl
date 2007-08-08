#!/usr/bin/perl
use strict;
use warnings;

use Net::LDAP;
use Net::LDAP::Constant qw(LDAP_EXTENSION_START_TLS);
use Net::LDAP::LDIF;
use Data::Dumper;
use Carp;
use Term::ReadKey;
use Term::ANSIColor qw(:constants);


my $ldap_conf = {
	hosts       => [
		'ldaps://lincon.grc.nia.nih.gov:636',
		'ldaps://lincon2.grc.nia.nih.gov:636',
		'ldap://lincon.grc.nia.nih.gov:389',
	],
# 	hosts       => guess_URIs(),
	options  => {
		debug   => undef,
		version => 3,
		timeout => 10,
		onerror => 'die', # Not user changeable at this time
		async     => 0, # Not user configurable
	},
	use_tls  => 1,
	ssl_opts => {
			sslversion => undef, # 'sslv2' | 'sslv3' | 'sslv2/3' | 'tlsv1', not user configurable
			capath     => undef,
			cafile     => '/etc/nialdap/cacerts/niairpCAcert.crt',
			ciphers    => 'ALL',
			verify     => 'require',
			clientcert => undef,
			clientkey  => undef,
	},
	DN       => guess_DN(),
# 	DN       => 'ou=people,ou=nia,o=nih,c=us',
	
};

print "Hosts:\n";
print "$_\n" foreach (@{$ldap_conf->{hosts}});

my $ldap = Net::LDAP->new ( $ldap_conf->{hosts},
	%{$ldap_conf->{options}},%{$ldap_conf->{ssl_opts}})
		or die "Could not connect to any ldap hosts.";
print "cypher is: ",$ldap->cipher ( ) ? $ldap->cipher ( ) : 'NONE',"\n";

print "\nTLS is supported\n"
	if $ldap->root_dse()->supported_extension (LDAP_EXTENSION_START_TLS);
if (not $ldap->cipher()
	and $ldap->root_dse()->supported_extension (LDAP_EXTENSION_START_TLS)
	and $ldap_conf->{use_tls}) {
		print "Trying TLS...";
		$ldap->start_tls(%{$ldap_conf->{ssl_opts}});
		print "cypher is: ",$ldap->cipher ( ) ? $ldap->cipher ( ) : 'NONE',"\n";
}

my $socket = $ldap->socket();
print "sockport is: ".$socket->sockport()."\n";
print "sockhost is: ".$socket->sockhost()."\n";
print "peerport is: ".$socket->peerport()."\n";
print "peerhost is: ".$socket->peerhost()."\n";

my $LOGFILE = \*STDOUT;
    eval "use OME::Install::Terminal";
    croak "Errors loading module: $@\n" if $@;
# OK, now bind	    		                  

	print $LOGFILE "Attempting to bind to LDAP server ... \n";
	my $username = confirm_default("\tGive me an LDAP-backed username to test: ");
	print "\tPassword? ";
	ReadMode(2);
	my $passwd = ReadLine(0);
	chomp($passwd);
	print "\n";
	ReadMode(1);
	print "\\_ Binding to LDAP server ... ";
	my $DN = "uid=$username";
	$DN .= ",$ldap_conf->{DN}" if $ldap_conf->{DN};
	my $mesg;
	eval{$mesg = $ldap->bind ($DN, password => $passwd );};
	# Note that $mesg is undef if the above results in a "die" call ($ldap->{options}->{onerror})
	if ($@ or not $mesg or $mesg->code != 0) {
		print BOLD, "[FAILURE]", RESET, ".\n";
        print "This is most likely either a bad username/password, or a bad OU/DC specification\n";
        print "The DN used to bind was '$DN'\n";
        exit;
	}

	print BOLD, "[SUCCESS]", RESET, ".\n";

# Print out what we found
 	$mesg = $ldap->search (
 		base   => $DN,
 		filter => '(objectclass=*)',
 	);
	my ($entry,$firstName,$lastName,$cn,$sn,$email,$uid,$home);
	foreach $entry ($mesg->all_entries) {
		$entry->dump;
		foreach my $attr ($entry->attributes()) {
			$firstName = $entry->get_value ($attr) if $attr eq 'givenName';
			$lastName = $entry->get_value ($attr) if $attr eq 'sn';
			$cn = $entry->get_value($attr) if $attr eq 'cn';
			$email = $entry->get_value($attr) if $attr eq 'mail';
			$uid = $entry->get_value($attr) if $attr eq 'uid';
			$home = $entry->get_value($attr) if $attr eq 'homeDirectory';
		}
	}

	print "\n";
	if (not (defined $firstName and defined $lastName) and defined $cn and defined $sn) {
	# Get it from the cn/sn
		$firstName = $1 if $cn =~ /(.+)\w$sn/;
	}
	if (not (defined $firstName and defined $lastName) and defined $cn) {
	# Get it from the cn (no sn)
		($firstName,$lastName) = split (' ',$cn,2);
	}
	if (defined $firstName and defined $lastName and defined $email and defined $uid) {
		print "OME Experimenter:\n";
		print "\tOMEName: $uid\n";
		print "\tFirstName: $firstName\n";
		print "\tLastName: $lastName\n";
		print "\tEmail: $email\n";
		print "\tDataDirectory: $home\n";
	} else {
		print "Not enough metadata for user creation\n";
	}

	# An OME Group ID to put LDAP users in
	# $ldap_conf->{autocreate}->{group}
 

    $ldap->unbind ( );

sub guess_DN {
	my $DN = `grep -i base /etc/ldap.conf 2>/dev/null`;
	$DN = undef if $DN =~ /^\s*#/;
	$DN = `grep -i base /etc/openldap/ldap.conf 2>/dev/null` unless $DN;
	return undef unless $DN;
	return undef if $DN =~ /^\s*#/;

	$DN = $1 if $DN =~ /base\s+(.*)$/i;
	$DN =~ s/\s+$// if $DN;
	$DN = "ou=people,$DN" if $DN and not $DN =~ /^ou=people/;

	return $DN
}

sub guess_URIs {
	my @grepURIs = `grep -i uri /etc/ldap.conf 2>/dev/null`;
	my @grep2URIs = `grep -i uri /etc/openldap/ldap.conf 2>/dev/null`;
	push (@grepURIs,@grep2URIs);
	my @URIs;
	foreach my $URI (@grepURIs) {
		next if $URI =~ /^\s*#/;
		$URI = $1 if $URI =~ /uri\s+(.*)$/i;
		$URI =~ s/\s+$// if $URI;
		push (@URIs,split (/\s+/,$URI)) if $URI;
	}

	return \@URIs;
}