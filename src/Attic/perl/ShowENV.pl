#!/usr/bin/perl -w
use strict;

use vars qw ($key $value);

print <<EOF
<!doctype html public "-//w3c//dtd html 4.0 transitional//en">
<html>
<head>
   <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
   <meta name="GENERATOR" content="Mozilla/4.7 [en] (X11; I; Linux 2.2.17pre20-ben3 ppc) [Netscape]">
</head>
<body>
<PRE>



EOF
;

print "Variable\t=\tValue\n";
print "-------------------------------------------------------\n";

while ( ($key, $value) = each %ENV)
{
	print "$key\t=\t$value\n";
}

print <<EOF



</PRE>
</body>
</html>
EOF
;
