# OME/Web.pm

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

=head1 NAME

OME::Web - The parent class of OME web pages

=head1 SYNOPSIS

	package OME::Web::Home;
	use strict;
	use OME;
	use CGI;
	use base qw/OME::Web/;

	our $VERSION;
	$VERSION = $OME::VERSION;
	
	sub getPageTitle {
		return "Open Microscopy Environment";
	}
	
	sub getPageBody {
		$self->contentType('text/html');
		$HTML = <<ENDHTML;
			<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
			<HTML><HEAD>
			<TITLE>Open Microscopy Environment</TITLE>
			<META NAME="ROBOTS" CONTENT="NOINDEX">
			</HEAD>
	ENDHTML	
		return ('HTML', $HTML);
	}
	1;


=head1 DESCRIPTION

This class is meant to be sub-classed by web pages in OME.  This class is only meant to provide common functionality.

=head1 METHODS

=cut


package OME::Web;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::SessionManager;
use Apache::Session::File;

use base qw(Class::Data::Inheritable);
__PACKAGE__->mk_classdata('__Session');
# The OME::Web class serves as the ancestor of all webpages accessed
# through the OME system.  Functionaly common to all pages of the site
# are defined here.	 Each webpage is defined by a subclass (ideally
# with a name prefixed with OME::Web::) which overrides the following
# methods:
#
#	 getPageTitle
#	 getPageBody
#	 

# IGG 9/18/03:
# contentType no longer defined as a method in this package
# to make it easier to modify in subclasses.
__PACKAGE__->mk_classdata('contentType');
__PACKAGE__->contentType('text/html');

my $loginPage = 'OME::Web::Login';

# new()
# -----

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %params = @_;

	my $CGI;
	if (exists $params{CGI}) {
	$CGI = $params{CGI};
	} else {
	$CGI = new CGI;
	}
	
	my $self = {
	CGI => $CGI
	};

	$self->{fontDefaults} = {
	face => 'Verdana,Arial,Helvetica'
	};

	$self->{tableDefaults} = {
	cellspacing => 1,
	cellpadding => 2,
	border		=> 0
	};

	$self->{tableHeaderRowDefaults} = {
	bgcolor => '#000000'
	};

	$self->{tableHeaderDefaults} = {
	align => 'CENTER',
	bgcolor => '#000000'
	};

	$self->{tableFormRowDefaults} = {
	bgcolor => '#e0e0e0'
	};

	$self->{tableRowColors} = ['#ffffd0','#d0d0d0'];
	$self->{nextRowColor} = 0;

	$self->{tableRowDefaults} = {
	};

	$self->{tableCellDefaults} = {
	align => 'LEFT'
	};

	$self->{OMEbgcolor} = '#CCCC99';

	$self->{RequireLogin} = 1;

	$self->{manager} = OME::SessionManager->new();
	
	$self->{_cookies} = undef;
	$self->{_headers} = undef;

	bless($self,$class);
	return $self;
}


# Accessors
# ---------

sub CGI { my $self = shift; return $self->{CGI}; }
sub DBH { my $self = shift; return $self->Session()->DBH(); }
sub Manager { my $self = shift; return $self->{manager}; }
sub ApacheSession { my $self = shift; return $self->Session()->{ApacheSession}; }
sub User { my $self = shift; return $self->{user}; }
# __Session accessor works fine from subclasses using $self.
# __Session mutator doesn't alter OME::Web's data unless accessed via OME::Web
# So we have this Session accessor/mutator method that can be used from anywhere to read
# 	and write OME::Web's __Session data.
sub Session { my $self = shift; if( scalar (@_) > 0 ) { return OME::Web->__Session( shift ); } return $self->__Session(); }
#sub contentType { my $self = shift; if( scalar (@_) > 0 ) { return OME::Web->__contentType( shift ); } return $self->__contentType(); }

# redirectURL
# -----------

sub pageURL {
	my ($self, $page) = @_;
	return "serve.pl?Page=$page";
	#return $self->CGI()->escape("serve.pl?Page=$page");
}


# ensureLogin
# -----------

sub ensureLogin {
	my $self = shift;
	my $manager = $self->Manager();

	#or a new session if we got no cookie my %session;
	my $sessionKey = $self->getSessionKey();

	if (defined $sessionKey) {
#		$self->setSession($manager->createSession($sessionKey));
		$self->Session($manager->createSession($sessionKey));
		$self->setSessionCookie();
	}

	if (defined $self->Session()) {
		$self->{user} = $self->Session()->User();
	}
	
	return defined $self->Session();
}


#
# setSessionCookie
# ----------------

sub setSessionCookie {
my $self = shift;
my $cgi = $self->CGI();
my %params = @_;
my $sessionKey;

	$sessionKey = $self->Session()->SessionKey() if defined $self->Session();
	if (defined $sessionKey) {
print STDERR "\nSetting cookie: $sessionKey\n";
		$self->{_cookies}->{'SESSION_KEY'} =
			$cgi->cookie( -name	   => 'SESSION_KEY',
						  -value   => $sessionKey,
						  -path    => '/',
						  -expires => '30m'
						  );
	} else {
print STDERR "\nLogging out - resetting cookie\n";
		$self->{_cookies}->{'SESSION_KEY'} =
			$cgi->cookie( -name	   => 'SESSION_KEY',
						  -value   => '',
						  -path    => '/',
						  -expires => '-1d');
	}
}


#
# getSessionKey
# ----------------

sub getSessionKey {
my $self = shift;
my $cgi = $self->CGI();
return $cgi->cookie('SESSION_KEY');
}


# getLogin()
# ----------

sub getLogin {
	my $self = shift;
	$self->redirect($self->pageURL($loginPage));
}

# serve()
# -------
sub serve {
	my $self = shift;
	if ($self->{RequireLogin}) {
		if (!$self->ensureLogin()) {
			$self->getLogin();
			return;
		}
	}
	#
	my ($result,$content) = $self->createOMEPage();
	
	my $cookies = [values %{$self->{_cookies}}];
	my $headers = $self->headers();
	$headers->{'-cookie'} = $cookies if scalar @$cookies;
	$headers->{'-expires'} = '-1d';
	$headers->{-type} = $self->contentType();



	# This would be a place to put browser-specific handling if necessary
	if ($result eq 'HTML' && defined $content) {
		print $self->CGI()->header(%{$headers});
		print $content;
	} elsif ($result eq 'IMAGE' && defined $content) {
		print $self->CGI()->header(%{$headers});
		print $content;
	} elsif ($result eq 'SVG' && defined $content) {
		print $self->CGI()->header(%{$headers});
		print $content;
	} elsif ($result eq 'FILE' && defined $content && ref($content) eq 'HASH') {
		$self->sendFile ($content);
	} elsif ($result eq 'REDIRECT' && defined $content) {
		$self->redirect($content);
	} else {
		my $class = ref($self);
		print $self->CGI()->header(-type => 'text/html', -status => '500',%{$headers});
		print "You shouldn't be accessing the $class page.";
		print "<br>Here's the error message:<br>$content" unless !(defined $content);
	}
	
	$self->Session()->closeSession()
		if defined $self->Session();
}

sub headers {
	my $self = shift;
	return $self->{_headers};
}

sub sendFile {
	my $self = shift;
	my $params = shift;
	my $headers = $self->headers();
	my $filename = $params->{filename};
	my $downloadFilename;
	
	die "Call to OME::Web::sendFile() without specifying a filename!"
		unless defined $filename;	
	open (INFILE,$filename)
		or die "OME::Web::sendFile() could not open $filename for reading: $!\n";
		

	$downloadFilename = $params->{downloadFilename}
		if exists $params->{downloadFilename};
	$downloadFilename = $filename
		unless defined $downloadFilename;
	
	$headers->{'Content-Disposition'} = qq{attachment; filename="$downloadFilename"}; 

	$headers->{-type} = $self->contentType();
	print $self->CGI()->header(%{$headers});
	
	my $buffer;
	while (read (INFILE,$buffer,32768)) {
		print $buffer;
	}
	
	close (INFILE);
	unlink $filename if exists $params->{temp} and $params->{temp};
	
}

sub redirect {
my $self = shift;
my $URL = shift;

	print $self->CGI()->header (-type=>'text/html', -cookie => [values %{$self->{_cookies}}]);
	print qq {
		<script language="JavaScript">
			<!--
				location = "$URL";
			//-->
		</script>
		};
	#exit (0);

}


# getTopNavbar
# ------------
# this is depricated

sub getTopNavbar {
	my $self = shift;
	my $CGI = $self->CGI();
	
	return $CGI->td($CGI->font(combine($self->{fontDefaults},
					   {size => '+2'}),
				   $CGI->b('OME')).
			"<br>Top navbar");
}

# getSidebar
# ----------
# this is depricated

sub getSidebar {
	my $self	= shift;
	my $CGI		= $self->CGI();
	my $session = $self->Session();

	my $loginMessage = "";
	
	if (defined $session) {
	my $user = $self->User();
	my $firstName = $user->FirstName();
	my $lastName = $user->LastName();
	$loginMessage = "<hr>$firstName $lastName";
	my $url = $self->pageURL('OME::Web::Logout');
	$loginMessage .= "<br><small><a href=\"$url\">LOGOUT</a></small>";
	}

	return	$CGI->td("Sidebar${loginMessage}<hr>Dataset info?<hr>Previously run<br>analyses?");
}

# createOMEPage
# -------------

sub createOMEPage {
	my $self  = shift;
	my $CGI	  = $self->CGI();
	my $title = $self->getPageTitle();
	my ($result,$body)	= $self->getPageBody();
	return ('ERROR',undef) if (!defined $title || !defined $body);
	return ($result,$body) if ($result ne 'HTML');

	my $head = $CGI->start_html({title => $title,
				 bgcolor => $self->{OMEbgcolor},
				 text => 'BLACK'});
	my $tail = $CGI->end_html;

	return ('HTML', $head . $body . $tail);
}


=head2 getPageTitle

This method should be over-ridden in a sub-class and return a text string with the page title,
which will normally appear in the window's title bar.

=cut

# getPageTitle()
# --------------
# This should be overriden in descendant classes to return the title
# of the page.

sub getPageTitle {
	return undef;
}


=head2 getPageBody

This method must be over-ridden in a sub-class and return two scalars.
The first scalar is treated as a status message to determine what to do with the second scalar.  For example,

  return ('HTML',$HTML);

Accepted status strings are C<HTML>, C<IMAGE>, C<SVG>, C<FILE>, C<REDIRECT> and C<ERROR>.
If the returned status is C<HTML>, then the page is appropriately decorated to match the other pages in OME.
No special processing is currently done for C<IMAGE> and C<SVG>.

A C<FILE> status is used for downloading files to the browser.  In this case, the second scalar is a hash reference
containing information to control the download process.  The hash may contain the following:

 filename         - a path to the file on the server to be downloaded.
 downloadFilename - The name of the file that should be used on the client (the browser).
 temp             - A flag that if true, will cause the downloaded file to be deleted on the server.
 
 return ('FILE',{filename => $myFile, downloadFilename => 'foo.txt', temp => 1});

A C<REDIRECT> status is used to get the browser to go to a different URL specified by the second scalar:

  return ('REDIRECT','http://ome.org/somewhere/else.html');

A C<ERROR> status means an error has occurred.  The error message should be sent as the second scalar.

  return ('ERROR','Something really bad happened');

The script can generate the same effect by calling

  die ('Something really bad happened');

=cut

# getPageBody()
# -------------
# This should be overridden in descendant classes to return the body
# of the page.	It should be returned as a tuple in the following
# form:

#
#	('ERROR',<error message>)
#	   - something unexpectedly bad happened
#
#	('HTML',<page body>)
#	   - everything worked well, returns an HTML fragment for the body
#		 of the page
#
#	('REDIRECT',<URL>)
#	   - everything worked well, but instead of a page body, the user
#		 should be redirected (usually in the case of processing form
#		 input)
#
#	'IMAGE' and 'SVG' are also valid results. 


sub getPageBody {
	return ('ERROR',undef);
}


# lookup(customTable, defaultTable, key)
# --------------------------------------

sub lookup {
	my $custom	= shift;
	my $default = shift;
	my $key		= shift;

	if (defined $custom->{$key}) {
	return $custom->{$key};
	} else {
	return $default->{$key};
	}
}


# combine(default, custom, ...)
# ----------------------------------

sub combine {
	#my $custom	 = shift;
	my $table;
	my %result;
	my ($key,$value);

	foreach $table (@_) {
	while (($key,$value) = each %$table)
	{
		$result{$key} = $value;
	}
	}

	return \%result;
}


# space(n)
# --------
sub space {
	my $n = shift;
	my $result = '';
	my $i;

	for ($i = 0; $i < $n; $i++)
	{
	$result .= '&nbsp;';
	}

	return $result;
}


# font(params, ...)
# -----------------
sub font {
	my $self	= shift;
	my $CGI		= $self->{CGI};
	my $params	= shift;
	my @content = @_;

	return $CGI->font(combine($self->{fontDefaults},$params),@content);
}


# contentType
# -----------------
# Implemented the same way as Session - acessor for __contentType


# table(params, ...)
# ------------------

sub table {
	my $self	= shift;
	my $CGI		= $self->{CGI};
	my $params	= shift;
	my @content = @_;

	return $CGI->table(combine($self->{tableDefaults},$params),@content) . "\n";
}


# tableHeaders(rowParams, columnParams, ...)
# ------------------------------------------

sub tableHeaders {
	my $self	  = shift;
	my $CGI		  = $self->{CGI};
	my $rowParams = shift;
	my $colParams = shift;
	#my @content   = @_;
	my ($h,$hs);

	$hs = "";
	foreach $h (@_) {
	$hs .= $CGI->td(combine($self->{tableHeaderDefaults},$colParams),
			$self->font({color => 'WHITE'},
					$CGI->small($CGI->b(space(2).$h.space(2)))));
	$hs .= "\n";
	}
		   
	my $x = $CGI->Tr(combine($self->{tableHeaderRowDefaults},$rowParams),$hs);

	return $x . "\n";
}


# tableRow(params, ...)
# ---------------------

sub tableColoredRow {
	my $self	= shift;
	my $CGI		= $self->{CGI};
	my $params	= shift;

	my $rowColor = $self->{tableRowColors}->[$self->{nextRowColor}];
	$self->{nextRowColor} = 1 - $self->{nextRowColor};

	return $CGI->Tr(combine($self->{tableRowDefaults},{bgcolor => $rowColor},$params),@_) . "\n";
}


sub tableRow {
	my $self	= shift;
	my $CGI		= $self->{CGI};
	my $params	= shift;

	return $CGI->Tr(combine($self->{tableRowDefaults},$params),@_) . "\n";
}


# tableCell(params, ...)
# ----------------------

sub tableCell {
	my $self	= shift;
	my $CGI		= $self->{CGI};
	my $params	= shift;

	my $thisRowColor = $self->{nextRowColor};
	my $rowColor = $self->{tableRowColors}->[$thisRowColor];
	
	return $CGI->td(combine($self->{tableCellDefaults},{bgcolor => $rowColor},$params),
			$self->font({},
				space(1),
				@_,
				space(1))) . "\n";
}


# spacer(width,height)
# --------------------

sub spacer {
	my $self   = shift;
	my $CGI	   = $self->{CGI};
	my $width  = shift;
	my $height = shift;

	return $CGI->img({src => "/perl/spacer.gif", width => $width, height => $height});
}


# tableLine(width)
# ----------------

sub tableLine {
	my $self  = shift;
	my $CGI	  = $self->{CGI};
	my $width = shift;
	my $height = shift;

	my $params = {colspan => $width};
	if (defined $height) {
	$params->{height} = $height;
	}

	return $CGI->Tr($self->{tableHeaderRowDefaults},
			$CGI->td(combine($self->{tableHeaderDefaults},$params),
				 $self->spacer(1,1))) . "\n";
}

1;

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Josiah Johnston <siah@nih.gov>,
Ilya Goldberg <igg@nih.gov>,
Open Microscopy Environment

=cut
