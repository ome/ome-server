#!/usr/bin/perl -w
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

use strict;
use OMEpl;
use vars qw ($OME $CGI $DATASETCOUNT);
$OME = new OMEpl;
$CGI = $OME->cgi();



# If no path information is provided, then we create 
# a side-by-side frame set
if (!$CGI->path_info) {
	print STDERR "OMEselectDatasets:  Printing frameset.\n";
    print_frameset ();
	print $CGI->end_html;
	$OME->Finish;
	exit (0);
}


if ($CGI->param('preview'))
{
	preview_selection () if $CGI->path_info=~/response/;
	print $CGI->end_html;
}

elsif ($CGI->param('add'))
{
	add_selection ();
#	$OME->Return_to_referer();
}
elsif ($CGI->param('replace'))
{
	add_selection ();
#	$OME->Return_to_referer();
}
elsif ($CGI->param('cancel'))
{
	$OME->Return_to_referer();
}
else
{
	print STDERR "OMEselectDatasets:  Printing form and preview.\n";
	print_form() if $CGI->path_info=~/query/;
	preview_selection () if $CGI->path_info=~/response/;
	print $CGI->end_html;
}

	$OME->Finish();
undef $OME;
undef $CGI;




sub get_selected_dataset_ids
{
my @IDlist;
my @clauses;
my @tables;
my $clause;
my $modifier;
my $k;
my $cmd;
my $sth;
my $dbh = $OME->DBIhandle();
my $projectOnly=1;


	push (@tables,'datasets');

	if ($CGI->param('byDate'))
	{
		$projectOnly=0;
		my $dateStr=$CGI->param('months')." ".$CGI->param('day')." ".$CGI->param('year');
		if ($CGI->param('dateModifier') eq 'Before')
		{
			$modifier = '<';
		}
		elsif ($CGI->param('dateModifier') eq 'During')
		{
			$modifier = '=';
		}
		elsif ($CGI->param('dateModifier') eq 'After')
		{
			$modifier = '>';
		}
		$clause = "date_trunc('day',datasets.inserted) $modifier date_trunc('day','".$dateStr."'::datetime)";
		push (@clauses,$clause);
	}
	
	if ($CGI->param('byType'))
	{
		$projectOnly=0;
		$clause = "datasets.dataset_type = '".$CGI->param('datasetTypes')."'";
		push (@clauses,$clause);
	}
	
	if ($CGI->param('byProject'))
	{
		push (@clauses,(
			'datasets.dataset_id = datasets_projects.dataset_id',
			'datasets_projects.project_id = projects.project_id',
			"projects.name='".$CGI->param('projects')."'"
			));
		push (@tables,('datasets_projects','projects'));
	}



	if ($CGI->param('byName'))
	{
		$projectOnly=0;
		$clause = "datasets.name ";

		if ($CGI->param('nameModifier') eq 'is')
		{
			$clause = $clause." = '".$CGI->param('nameString')."'";
		}
		elsif ($CGI->param('nameModifier') eq 'begins with')
		{
			$clause = $clause."LIKE '".$CGI->param('nameString')."\%'";
		}
		elsif ($CGI->param('nameModifier') eq 'ends with')
		{
			$clause = $clause."LIKE '\%".$CGI->param('nameString')."'";
		}
		elsif ($CGI->param('nameModifier') eq 'contains')
		{
			$clause = $clause."LIKE '\%".$CGI->param('nameString')."\%'";
		}
		push (@clauses,$clause);
	}
	
	if ($CGI->param('byPath'))
	{
		$projectOnly=0;
		$clause = "datasets.path ";

		if ($CGI->param('pathModifier') eq 'is')
		{
			$clause = $clause." = '".$CGI->param('pathString')."'";
		}
		elsif ($CGI->param('pathModifier') eq 'begins with')
		{
			$clause = $clause."LIKE '".$CGI->param('pathString')."\%'";
		}
		elsif ($CGI->param('pathModifier') eq 'ends with')
		{
			$clause = $clause."LIKE '\%".$CGI->param('pathString')."'";
		}
		elsif ($CGI->param('pathModifier') eq 'contains')
		{
			$clause = $clause."LIKE '\%".$CGI->param('pathString')."\%'";
		}
		push (@clauses,$clause);
	}


	my $maxDatasets;
	if ($CGI->param('preview')) {
		$maxDatasets = sprintf ('%d',$CGI->param('maxDatasets'));
	}

	if (@clauses)
	{
	my $tuple;
	my $fromWhereClause = join (',',@tables)." WHERE ".join (" AND ",@clauses);
	$DATASETCOUNT = $dbh->selectrow_array("SELECT count(datasets.dataset_id) FROM $fromWhereClause");

		$cmd = "SELECT datasets.dataset_id FROM $fromWhereClause ORDER BY datasets.name";
		$cmd .= " LIMIT $maxDatasets" if (defined $maxDatasets and $maxDatasets) ;
		$sth = $dbh->prepare($cmd);
		$sth->execute();
		$sth->bind_columns(\$tuple);
		while ( $sth->fetch ) {
			push (@IDlist,$tuple);
		}		
	}
	return \@IDlist;
}




sub preview_selection
{
my $IDlist;
my $maxDatasets = $OME->DatasetsDisplayLimit;

	print_header();
	$IDlist = get_selected_dataset_ids ();
	print "<H2>Selection Preview</H2>";
	if (not $IDlist or not defined $IDlist->[0])
	{
		print "<H3>No Datasets in selection <H3><BR>";
		return;
	}
	
	if ($DATASETCOUNT > $maxDatasets and defined $maxDatasets and $maxDatasets) {
		print "<H4>Only first $maxDatasets of $DATASETCOUNT Datasets shown</H4>";
	} else {
		print "<H4>$DATASETCOUNT Datasets Selected</H4>";
	}

	print $OME->DatasetsTableHTML(DatasetIDs=>$IDlist);

	#print join ("<br>",@IDlist),"<br>";
}




sub add_selection
{
my $IDlist = get_selected_dataset_ids ();

	if (defined $IDlist and $IDlist->[0])
	{
		if ($CGI->param('add'))
		{
			push (@$IDlist,@{$OME->GetSelectedDatasetIDs()});
		}
		$OME->SetSelectedDatasets($IDlist);
	}
}




sub print_form {
my @tableRows;
my @tableColumns;
my $k;
my $script_name = $CGI->script_name;
my $cmd;
my $OME_SID = $OME->SID();
my $dbh = $OME->DBIhandle();
my $sth;


use POSIX qw(strftime);

	my $month = strftime "%b", localtime;
	my $day = strftime "%e", localtime;
	my $year = strftime "%Y", localtime;
	my @months=('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
	$tableColumns[0]=$CGI->th({-align=>'LEFT'},$CGI->checkbox (-name=>'byDate'));
	$tableColumns[1]=$CGI->popup_menu(-name=>'dateModifier',
                            	-values=>['Before','During','After'],-default=>'During');
	$tableColumns[2] = $CGI->popup_menu(-name=>'months',-values=>\@months,-default=>$month).
			$CGI->textfield(-name=>'day',-size=>2,-default=>$day).",".
			$CGI->textfield(-name=>'year',-size=>4,-default=>$year);
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);

	print STDERR "Getting the dataset selection.\n";
	my $datasetTypes = $dbh->selectcol_arrayref("SELECT DISTINCT DATASET_TYPE FROM datasets");

	$tableColumns[0]=$CGI->th({-align=>'LEFT'},$CGI->checkbox (-name=>'byType'));
	$tableColumns[1]=$CGI->popup_menu(-name=>'datasetTypes',
                            	-values=>$datasetTypes);
	$tableColumns[2] = "";
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);



	my $projectNames = $dbh->selectcol_arrayref("SELECT name FROM projects");

	$tableColumns[0]=$CGI->th({-align=>'LEFT'},$CGI->checkbox (-name=>'byProject'));
	$tableColumns[1]=$CGI->popup_menu(-name=>'projects',
                            	-values=>$projectNames);
	$tableColumns[2] = "";

	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);



	$tableColumns[0]=$CGI->th({-align=>'LEFT'},$CGI->checkbox (-name=>'byName'));
	$tableColumns[1]=$CGI->popup_menu(-name=>'nameModifier',
                            	-values=>['is','begins with','ends with','contains'],-default=>'contains');
	$tableColumns[2] = $CGI->textfield(-name=>'nameString',-size=>32);
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);


	$tableColumns[0]=$CGI->th({-align=>'LEFT'},$CGI->checkbox (-name=>'byPath'));
	$tableColumns[1]=$CGI->popup_menu(-name=>'pathModifier',
                            	-values=>['is','begins with','ends with','contains'],-default=>'contains');
	$tableColumns[2] = $CGI->textfield(-name=>'pathString',-size=>32);
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);




	print_header ();

	print $CGI->h3('Select Datasets:');
	print $CGI->startform(-action=>"$script_name/response",-target=>"response");
	print $CGI->table({-border=>1,-cellspacing=>2,-cellpadding=>2},
		$CGI->Tr(\@tableRows)
		);
	print  $CGI->submit(-name=>'preview',-value=>'Preview selection');
	print  "&nbsp&nbsp&nbsp Display first ".
		$CGI->textfield(-name=>'maxDatasets',-size=>4,
			-default=>$OME->DatasetsDisplayLimit)." Datasets (sorted by name).<BR>";
	print  $CGI->submit(-name=>'add',-value=>'Add to selection');
	print  $CGI->submit(-name=>'replace',-value=>'Replace selection');
	print  $CGI->submit(-name=>'cancel',-value=>"Cancel");
	print  "</CENTER>",$CGI->endform;


}


# Create the frameset
sub print_frameset {
my $script_name = $CGI->script_name;

    print $CGI->header;
    print <<EOF;
<html><head><title>Select Datasets</title></head>
<frameset cols="50,50">
<frame src="$script_name/query" name="query">
<frame src="$script_name/response" name="response">
</frameset>
EOF
	;
}

sub print_header {

print $OME->CGIheader (-type=>'text/html');
print $CGI->start_html(-title=>'Select Datasets');
}

