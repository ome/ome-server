


#!/usr/bin/perl -w

# $Id: ApachePg.pl,v 1.1.1.1 2001/01/17 21:07:30 root Exp $

# demo script, tested with:
#  - PostgreSQL-6.4
#  - apache_1.3.1
#  - mod_perl-1.15
#  - perl5.005_02
use CGI;
use Pg;
use strict;

my $query = new CGI;
print $query->header (-type=>'text/html'),
       $query->start_html(-title=>'OME Login'),
       $query->startform,
       "<CENTER><H3>Login to OME</H3></CENTER>",
       "<P><CENTER><TABLE CELLPADDING=4 CELLSPACING=2 BORDER=1>",
       "<TR><TD>Enter user name: </TD>",
           "<TD>", $query->textfield(-name=>'user', -size=>40, ), "</TD>",
       "</TR>",
       "<TR><TD>Enter password: </TD>",
           "<TD>", $query->password_field(-name=>'pass', -size=>20), "</TD>",
       "</TR>",
       "</TABLE></CENTER><P>",
       "<CENTER>", $query->submit(-value=>'Submit'), "</CENTER>",
       $query->endform;

if ($query->param) {
    my $user = $query->param ('user');
    my $pass = $query->param ('pass');
    my $conninfo = "dbname=ome user=$user password=$pass";
    my $conn = Pg::connectdb($conninfo);
    my $cmd = "select * from analyses";
    if (PGRES_CONNECTION_OK == $conn->status) {
	print "<CENTER><H2> Connected to OME as $user</H2></CENTER>";
        my $result = $conn->exec($cmd);
        if (PGRES_TUPLES_OK == $result->resultStatus) {
	    my $k;
            print "<P><CENTER><TABLE CELLPADDING=4 CELLSPACING=2 BORDER=1>\n";
	    print "<TR>";
	    for ($k = 0; $k < $result->nfields; $k++)
	    	{
		print "<TD>",$result->fname($k),"</TD>";
		}
	    print "</TR>";
            my @row;
            while (@row = $result->fetchrow) {
                print "<TR><TD>", join("</TD><TD>", @row), "</TD></TR>";
            }
            print "</TABLE></CENTER><P>\n";
        } else {
            print "<CENTER><H2>", $conn->errorMessage, "</H2></CENTER>\n";
        }
    } else {
        print "<CENTER><H2>", $conn->errorMessage, "</H2></CENTER>\n";
    }
}
print $query->end_html;


