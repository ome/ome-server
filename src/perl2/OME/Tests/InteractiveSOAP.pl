#!perl -w
# OME/Tests/ImportTest.pl

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


use Term::ReadKey;
use SOAP::Lite
  on_fault => sub {
      my($soap, $res) = @_; 
      die ref $res ? $res->faultstring : $soap->transport->status;
  };
use XMLRPC::Lite;
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

my $soap = XMLRPC::Lite
  -> uri   ('OME/Remote/Dispatcher')
  -> proxy ($host);

$soap->on_debug(sub { print @_ })
  if $ARGV[1];

my $session = $soap
  -> call (createSession => $username, $password)
  -> result;

print "OME::Remote::Facade::createSession\nGot '$session'...\n\n";

sub __getInput {
    print shift," ";
    my $value = <STDIN>;
    chomp($value);
    return $value;
}

while (1) {
    my $method = __getInput("Method?");
    last if uc($method) eq '\Q';
    my @params;
    my $cont2 = 1;
    my $paramCount = 1;
    my @paramStack;
    my $currentParam = \@params;
    while (1) {
        my $param = __getInput("Param $paramCount?");
        $paramCount++;
        last if $param eq "";

        if ($param eq '[') {
            push @paramStack, $currentParam;
            $currentParam = [];
        } elsif ($param eq ']') {
            my $closed = $currentParam;
            $currentParam = pop @paramStack;
            push @$currentParam, $closed;
        } else {
            $param = undef if uc($param) eq "UNDEF";
            push @$currentParam, $param;
        }
    }

    eval {
        my @result = $soap->
          call('dispatch',$session,$method,@params)->
          paramsall();

        map { $_ = '<undef>' unless defined $_; } @result;

        if (scalar(@result) == 0) {
            print "  Got void...\n\n";
        } elsif (scalar(@result) == 1) {
            print "  Got '$result[0]'...\n\n";
        } else {
            print "  Got [",join(',',@result),"]...\n\n";
        }
    };

    print "  Error: $@\n\n" if ($@);
}



$result = $soap
  ->call(closeSession => $session)
  ->result();

print "OME::Remote::Dispatcher::closeSession\nGot '$result'...\n\n";
