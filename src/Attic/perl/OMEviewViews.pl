#!/usr/bin/perl
# Author:  Ilya G. Goldberg (igg@mit.edu)
# Copyright 1999-2001 Ilya G. Goldberg
# This file is part of OME.
# 
#     OME is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     OME is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with OME; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# 
#

use OMEpl;
use strict;
use vars qw ($OME $cgi);
$OME = new OMEpl;
$cgi = $OME->cgi;

if ($cgi->param)
{
	process_request();
}
else
{
	print $OME->CGIheader ();
	print $cgi->start_html(-title=>'Database Views');
	print_form();
	print $cgi->end_html;
}
$OME->Finish;
undef $OME;


# If this script was called without parameters, then
# Present a form that has a drop-down containing all views in the database.
# If the user presses the 'Display' button, display an HTML table containing the view.
sub print_form {
my @tableRows;
my @tableColumns;



	$tableColumns[0]=$cgi->th ('View:');
	$tableColumns[1]='<CENTER>';
	$tableColumns[1].= $cgi->popup_menu(-name=>'viewName', -values=>$OME->GetUserViews, -default=>$OME->GetProjectName);
	$tableColumns[1].='</CENTER>';
	$tableColumns[1] = $cgi->td ($tableColumns[1]);
	push (@tableRows,join ('',@tableColumns));


	$tableColumns[0]=$cgi->th ('Action:');
	$tableColumns[1]=$cgi->submit(-name=>'htmlView',-value=>'View in Browser').
			$cgi->submit(-name=>'getText',-value=>"Download Excel 'csv' file").
			$cgi->submit(-name=>'dropView',-value=>'Delete View');
	$tableColumns[1] = $cgi->td ($tableColumns[1]);
	push (@tableRows,join ('',@tableColumns));


	print $cgi->startform();
	print $cgi->h3('Database Views');
	print $cgi->table({-border=>0,-cellspacing=>2,-cellpadding=>2},
		$cgi->Tr(\@tableRows)
		);
	print $cgi->endform;

}




# If the user presses the download textfile button, transmit the textfile in the proper format.
sub process_request {
my $viewName = $cgi->param ('viewName');
my $cmd = qq/SELECT * from "$viewName"/;

	if ($cgi->param('htmlView')) {
		my $sth = $OME->DBIhandle->prepare($cmd);
		$sth->execute();
		my @tableRows = $cgi->th ($sth->{NAME});
		my $tuple;
		while ( $tuple = $sth->fetchrow_arrayref() ) {
			push (@tableRows,$cgi->td($tuple));
		}


		print $OME->CGIheader (-type=>'text/html');
		print $cgi->start_html(-title=>$viewName);
		print "<CENTER>";
		print $cgi->table({-border=>1,-cellspacing=>1,-cellpadding=>1},
			$cgi->Tr(\@tableRows));
		print " </CENTER>";
		print $cgi->end_html;
	}
	
	elsif ($cgi->param ('getText')) {
		my $separator = ",";

		print $OME->CGIheader (-type=>'application/vnd.ms-excel',-attachment=>$viewName.".csv",-name=>$viewName.".csv");
		my $sth = $OME->DBIhandle->prepare($cmd);
		$sth->execute();
		print join ($separator,@{$sth->{NAME}}),"\n";
		my $tuple;
		while ( $tuple = $sth->fetchrow_arrayref() ) {
			print join ($separator,@$tuple),"\n";
		print $cgi->end_html;
		}
	}
	elsif ($cgi->param ('dropView')) {
		print $OME->CGIheader (-type=>'text/html');
		print $cgi->start_html(-title=>'Database Views');
		print $cgi->startform();
		print $cgi->h3(qq/Are you sure you want to delete the view<BR>'$viewName'?/);
		print $cgi->hidden(-name=>'viewName',-default=>$viewName);
		print $cgi->submit(-name=>'confirmDropView',-value=>"Yes");
		print $cgi->submit(-name=>'cancelDropView',-value=>"No");
		print $cgi->endform();
		print $cgi->end_html;
	}
	elsif ($cgi->param ('confirmDropView')) {
		$OME->DropView($viewName);
		print $OME->CGIheader (-type=>'text/html');
		print $cgi->start_html(-title=>'Database Views');
		print_form();
		print $cgi->h3(qq/'$viewName' Deleted./);
		print $cgi->end_html;
	}
	elsif ($cgi->param ('cancelDropView')) {
		print $OME->CGIheader (-type=>'text/html');
		print $cgi->start_html(-title=>'Database Views');
		print_form();
		print $cgi->h3(qq/Deletion of '$viewName' canceled./);
		print $cgi->end_html;
	}
}
