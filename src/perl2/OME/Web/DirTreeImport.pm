# OME/Web/DirImport.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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
# Written by:  
#
#-------------------------------------------------------------------------------


package OME::Web::DirTreeImport;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::DBObject;
use base qw{ OME::Web };

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %params = @_;
	my $self = $class->SUPER::new(@_);
	bless $self,$class;

	$self->{selectURL} = "'/perl2/serve.pl?Page=OME::Web::DirTreeImportSelect'";
	$self->{readDirURL} ="'/perl2/serve.pl?Page=OME::Web::DirTreeImport'";


	return $self;
}

sub getPageTitle {
	my $self = shift;
	return "Hidden Dir Tree page. Made by ".(ref $self);
}


sub getPageBody {
	my $self = shift;
	# The paths requested by the menu JS all begin with $rootJSpath, which is equivalent to $rootDir on the server's filesystem.
	my $rootJSpath = '';
	my $cgi = $self->CGI();
	my $body = "";

	my $rootDir = $self->User()->DataDirectory();
print STDERR "rootDir===".$rootDir."\n";
	my $rootName = "Home ($rootDir)";

	my $action = $cgi->url_param('action');
	$action = 'readDir' unless defined $action;

	if ($action eq 'readDir') {
		my $dir = $cgi->url_param('fullPath');
		my $dirID = $cgi->url_param('entryID');
		my @entries = ("theMenu = parent.theMenu;");

		if (not defined $dirID or not defined $dir) {
			push (@entries,qq/rootID = theMenu.addEntry(-1, "Folder", "$rootName", "", "");/);
			push (@entries,qq/theMenu.entry[rootID].FirstChild = -2/);
    		push (@entries,qq/theMenu.entry[rootID].onToggle="loadOnToggle(me, $self->{readDirURL})";/);
    		push (@entries,qq/theMenu.entry[rootID].fullPath='$rootJSpath';/);
    		push (@entries,qq/theMenu.entry[rootID].onClick="selectOnClick(me,$self->{selectURL})";/);
    		push (@entries,qq/theMenu.entry[rootID].isMultiSelected=false;/);
			
		}
		elsif (defined $dir and defined $dirID) {
		#	print STDERR "Reading directory $dir, ID $dirID.\n";
			push (@entries,$self->ReadDirectory ($rootDir,$dir,$dirID));
		}

		push (@entries,"theMenu.reload();");

		my $JSCRIPT = join ("\n",@entries);
		$body .= $cgi->start_html (-script => $JSCRIPT);
	} else {
		$body .= $cgi->h3 ('Select Files and Folders in the menu tree on the left.');
	}
	return ('HTML', $body);
}


sub ReadDirectory {
my $self = shift;
my ($rootDir,$dirJS,$directoryID) = @_;
my ($fullPath,$file,@fileList,@menuEntries,@dirList);
my $cgi = $self->CGI();
my $first=0;
my $string;
my $JSpath;
my $fileCount=0;
my $maxFiles=50;

# FIXME:  SECURITY:  Strip out all '..' out of the path!
	my $directory = $rootDir.$dirJS;
	print STDERR "Trying to open <$directory>\n";
	opendir (DIR,$directory) or $self->JSdie ("can't open $directory: $!");
	while (defined ($file = readdir (DIR)))
	{
		next if $file =~ /^\..*/; # No files begining with '.'
		if (-f $directory.'/'.$file) {
			$fileCount++;
			push (@fileList,$file);
		} else {
			push (@dirList,$file);
		}
		last if ($fileCount > $maxFiles);
	}
	closedir (DIR);

	@fileList = sort {uc($a) cmp uc($b)} @fileList;
	@dirList = sort {uc($a) cmp uc($b)} @dirList;

	foreach $file ( @dirList)
	{
		$fullPath = $directory."/".$file;
		$JSpath = $dirJS."/".$file;
	# For whatever reason, '+' isn't escaped by some JavaScript implementations (notably Netscape 4.7x), so we use Perl CGI's escape.
		$JSpath = $cgi->escape($JSpath);
		push (@menuEntries,qq/childID = theMenu.addChild($directoryID, "Folder", "$file", "", "");/);
		push (@menuEntries,qq/theMenu.entry[childID].FirstChild = -2;/);
		push (@menuEntries,qq/theMenu.entry[childID].onToggle="loadOnToggle(me, $self->{readDirURL})";/);
		push (@menuEntries,qq/theMenu.entry[childID].fullPath="$JSpath";/);
		push (@menuEntries,qq/theMenu.entry[childID].onClick="selectOnClick(me,$self->{selectURL})";/);
		push (@menuEntries,qq/theMenu.entry[childID].isMultiSelected=false;/);
	}

	foreach $file ( @fileList)
	{
		$fullPath = $directory."/".$file;
		$JSpath = $dirJS."/".$file;
	# For whatever reason, '+' isn't escaped by some JavaScript implementations (notably Netscape 4.7x), so we use Perl CGI's escape.
		$JSpath = $cgi->escape($JSpath);
		push (@menuEntries,qq/childID = theMenu.addChild($directoryID, "Document", "$file", "", "");/);
		push (@menuEntries,qq/theMenu.entry[childID].fullPath="$JSpath";/);
		push (@menuEntries,qq/theMenu.entry[childID].onClick="selectOnClick(me,$self->{selectURL})";/);
		push (@menuEntries,qq/theMenu.entry[childID].isMultiSelected=false;/);
	}
	
	if ($fileCount > $maxFiles) {
		push (@menuEntries,qq/childID = theMenu.addChild($directoryID, "Document", "(Only $maxFiles files listed)", "", "");/);
		push (@menuEntries,qq/theMenu.entry[childID].onClick="";/);
		push (@menuEntries,qq/theMenu.entry[childID].isMultiSelected=false;/);
	}

    return @menuEntries;
}

sub JSdie {
my $self = shift;
my $message = shift;
my $cgi = $self->CGI();

		print $cgi->header (-type   => 'text/html',
                    		-expires => '-1d');
		print $cgi->start_html (-script => qq/alert('Error:  '+"$message");/);
		print $cgi->end_html();
		die;
}

1;
