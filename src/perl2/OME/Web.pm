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
# IGG 1/19/06: Emiting xhtml confuses things - we're not compliant with xhtml transitional 1.0
use CGI qw/-no_xhtml/;
use Carp;
use Carp 'cluck';
use OME::SessionManager;
use OME::Web::DefaultHeaderBuilder;
use OME::Web::DefaultMenuBuilder;
use OME::Web::DBObjRender;
use OME::Web::Util::Category;
use OME::Web::Util::Dataset;
use OME::Web::Search;
use OME::Web::AccessManager;
use OME::Web::TemplateManager;

use base qw(Class::Data::Inheritable);

# The OME::Web class serves as the ancestor of all webpages accessed
# through the OME system.  Functionaly common to all pages of the site
# are defined here.	 Each webpage is defined by a subclass (ideally
# with a name prefixed with OME::Web::) which overrides the following
# methods:
#
#	 getPageTitle
#	 getPageBody
#	 getTemplate (optional)

# IGG 9/18/03:
# contentType no longer defined as a method in this package
# to make it easier to modify in subclasses.
__PACKAGE__->mk_classdata('contentType');
__PACKAGE__->contentType('text/html');
# IGG: lots and lots of problems to fix before we can do this:
# If we ever do, we would want to turn off the -no_xhtml pragma above
#__PACKAGE__->contentType('application/xhtml+xml');

# Default timeout for packages is none
__PACKAGE__->mk_classdata('timeout');
__PACKAGE__->timeout(0);

# Default timeout for packages is none
__PACKAGE__->mk_classdata('invisibleObjects');
__PACKAGE__->invisibleObjects({
	'OME::SemanticType::BootstrapExperimenter' => undef,
	'OME::SemanticType::BootstrapGroup' => undef,
	'OME::UserState' => undef,
});
__PACKAGE__->mk_classdata('adminObjects');
__PACKAGE__->adminObjects({
	'@Experimenter' => undef,
	'@Group' => undef,
	'@ExperiementerGroup' => undef,
});

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

	# Popup info
	$self->{_popup} = 1 if ( $CGI->param('Popup') or $CGI->url_param('Popup') );
	$self->{_nomenu} = 1 if ( $CGI->param('NoMenu') or $CGI->url_param('Popup') );
	$self->{_noheader} = 1 if ( $CGI->param('NoHeader') or $CGI->url_param('Popup') );

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
sub Manager { my $self = shift; return $self->{manager}; }
sub ApacheSession { my $self = shift; return $self->Session()->{ApacheSession}; }
sub User { my $self = shift; return $self->Session()->User(); }
sub Renderer { 
	my $self = shift; 
	return $self->{renderer} if $self->{renderer};
	return ( $self->{renderer} = OME::Web::DBObjRender->new( CGI => $self->CGI() ) );
}
sub SearchUtil { 
	my $self = shift; 
	return $self->{search_util} if $self->{search_util};
	return ( $self->{search_util} = OME::Web::Search->new( CGI => $self->CGI() ) );
}
sub Tablemaker { 
	my $self = shift; 
	return $self->{ table_maker } if $self->{ table_maker };
	return ( $self->{ table_maker } = OME::Web::DBObjTable->new( CGI => $self->CGI() ) );
}
sub CategoryUtil {
	my $self = shift; 
	return $self->{ category_util } if $self->{ category_util };
	return ( $self->{ category_util } = OME::Web::Util::Category->new( CGI => $self->CGI() ) );
}
sub DatasetUtil {
	my $self = shift; 
	return $self->{ dataset_util } if $self->{ dataset_util };
	return ( $self->{ dataset_util } = OME::Web::Util::Dataset->new( CGI => $self->CGI() ) );
}

# Because we no longer need any sort of Session reference store this is just a macro now
sub Session { OME::Session->instance() };

# redirectURL
# -----------

sub pageURL {
	my ($self, $page, $param) = @_;

	# Absolute urls are needed for links to be valid in external documents (e.g. downloaded spreadsheets)
	# $self->CGI is not always available, because this method is sometimes called on a class,
	# rather than the instance. this is really a hack-around.
	my $base_url;
	if( ref( $self ) ) {
		$base_url = $self->CGI()->url();
	} else {
		$base_url = 'serve.pl'
	}
	my $url = $base_url."?Page=$page".
		( $param ?
		  '&'.join( '&', map( $_."=".$param->{$_}, keys %$param ) ) :
		  ''
		);
	# do url-escaping of most meta characters.
	# The code snippet was obtained from http://glennf.com/writing/hexadecimal.url.encoding.html
	my $MetaChars = quotemeta( ';,\|+)(*^%$#@!~`');
	$url =~ s/([$MetaChars\"\'\x80-\xFF])/"%" . uc(sprintf("%2.2x", ord($1)))/eg;
	$url =~ s/ /\+/g;
	return $url;
}


# ensureLogin
# -----------

sub ensureLogin {
    
	my $self = shift;
	my $manager = $self->Manager();


	#or a new session if we got no cookie my %session;
	my $sessionKey = $self->getSessionKey();
	if (defined $sessionKey) {
		my $session = $manager->createSession($sessionKey);
		if ($session) {
			$self->setSessionCookie($self->Session()->SessionKey());
		} else {
			$self->{ _login_timeout } = 1;
			$self->setSessionCookie();
		}
		return defined $session;
	}
	else {
	    # try to login in as guest. note that session manager will
	    # not  allow this if the configuration has not enabled
	    # guest logins.
	    
	    # note that we don't set the session key here. 
	    # eventually, we might want to distinguish between
	    # multiple guest sessions, but we're not going to worry
	    # about that just yet.
	    
	    my $session = $self->Manager()->createSession( 'guest', 'abc123' );
	    return defined $session;
	}
	
	return;
}


#
# setSessionCookie
# ----------------

sub setSessionCookie {
my $self = shift;
my $sessionKey = shift;
my $cgi = $self->CGI();

	if (defined $sessionKey) {
#print STDERR "\nSetting cookie: $sessionKey\n";
		$self->{_cookies}->{'SESSION_KEY'} =
			$cgi->cookie( -name	   => 'SESSION_KEY',
						  -value   => $sessionKey,
						  -path    => '/',
						  -expires => '+30m'
						  );
	} else {
#print STDERR "\nLogging out - resetting cookie\n";
		$self->{_cookies}->{'SESSION_KEY'} =
			$cgi->cookie( -name	   => 'SESSION_KEY',
						  -value   => '',
						  -path    => '/',
						  -expires => '-1d'
						  );
	}
}


#
# getSessionKey
# ----------------

sub getSessionKey {
	my $self = shift;
	my $cgi = $self->CGI();
	my $key = $cgi->cookie('SESSION_KEY');
	return $key if $key;
	$key = $cgi->url_param('SessionKey');
	return $key if $key;
	$key = $cgi->param('SessionKey');
	return $key;
}


# getLogin()
# ----------

sub getLogin {
	my $self = shift;
	my $q = $self->CGI();

	# this will record state information
	my $target_url = $q->self_url();
	# CGI's self_url() does not contain url_params if a form was just submitted.
	# Page (e.g. 'OME::Web::Home') is always a url_param. AFAIK, it is the only
	# URL param that regularly gets mixed with POST params. For more info, see
	# CGI's documentation "MIXING POST AND URL PARAMETERS"
	unless( $target_url =~ m/Page=/ ) {
		my $page = $q->url_param("Page");
		$target_url .= "&Page=$page";
	}

	print $q->header (-type=>'text/html', -cookie => [values %{$self->{_cookies}}]);
	print $q->start_html( -onLoad => 'document.forms[\'primary\'].submit();'	);
	print $q->start_form( -action => $self->pageURL($loginPage), -name => 'primary' );
	unless( $target_url =~ m/$loginPage/ ) {
		print $q->hidden( target_url => $target_url );
	}
	# ensureLogin sets $self->{ _login_timeout } for us.
	if( exists $self->{ _login_timeout } && $self->{ _login_timeout }) {
		print $q->hidden( login_timeout => 1 );
	}
	print $q->endform();
	print $q->end_html;

}


# getTemplate ()
# 
# manage the template by class possibilities. getTemplate calls
# "getAuthenticatedTemplate" to find the template appropriate for an
# authenticated user.
#
# return the HTML::Template used to instantiate the page in question.
# three possibilities;
#   NULL means that the template in question could not be accessed. 
#     display an error page in this case.
# NO_TEMPLATE  means that no template is needed for this page.
#   an HTML::Template option will be passed to getPageBody() and used
#  to populate the page.
# 
#  The default is to return 'NO_TEMPlATE', indicating that no
# template is needed. Subclasses will over-ride as necessary.
#
# subclasses will override getTemplate to (where necessary) provide
# access controls and branching and getAuthenticatedTemplate to 
# provide the template for authenticated users.
# -----------

sub getTemplate {
    my $self =shift;
    return $self->getAuthenticatedTemplate();
}

sub getAuthenticatedTemplate {
    my $self= shift;
    return $OME::Web::TemplateManager::NO_TEMPLATE;
}

# serve()
# -------
sub serve {
	my $self = shift;

	# XXX This is our *only* form of access control to the session object
	if ($self->{RequireLogin}) {
		if (!$self->ensureLogin()) {
			$self->getLogin();
			return;
		}
	}

	my $template = $self->getTemplate();
	my ($result,$content,$jnpl_filename) = $self->createOMEPage($template);
	
	my $cookies = [values %{$self->{_cookies}}];
	my $headers = $self->headers();
	$headers->{'-cookie'} = $cookies if scalar @$cookies;
	$headers->{'-expires'} = '-1d';
	$headers->{'-type'} = $self->contentType();



	# This would be a place to put browser-specific handling if necessary
	if ($result eq 'HTML' && defined $content) {
		print $self->CGI()->header(%{$headers});
		print $content;
	} elsif ($result eq 'TXT' && defined $content) {
		$self->contentType('text/plain');
		$headers->{-type} = $self->contentType();
		print $self->CGI()->header(%{$headers});
		print $content;
	} elsif ($result eq 'XML' && defined $content) {
	        $self->contentType('application/xml');
		$headers->{-type} = $self->contentType();
		print $self->CGI()->header(%{$headers});
		$content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" 
		    . $content."\n";
		print $content;
	} elsif ($result eq 'IMAGE' && defined $content) {
		print $self->CGI()->header(%{$headers});
		print $content;
	} elsif ($result eq 'SVG' && defined $content) {
		print $self->CGI()->header(%{$headers});
		print $content;
	} elsif ($result eq 'JNLP' && defined $content) {
		$headers->{'-attachment'} = $jnpl_filename;
		print $self->CGI()->header(%{$headers});
		print $content;
	} elsif ($result eq 'FILE' && defined $content && ref($content) eq 'HASH') {
		$self->sendFile ($content);
	} elsif ($result eq 'REDIRECT' && defined $content) {
		# Added here to propagate headers to redirects [Bug #174]
		print $self->CGI()->header(%{$headers});
		$self->redirect($content);
	} else {
		my $class = ref($self);
		print $self->CGI()->header(-type => 'text/html', -status => '500',%{$headers});
		print "You shouldn't be accessing the $class page.";
		print "<br>Here's the error message:<br>$content" unless !(defined $content);
	}
}

sub headers {
	my $self = shift;
	return $self->{_headers};
}

sub sendFile {
	my $self = shift;
	my $params = shift;
	my $downloadFilename;
	
	die "Call to OME::Web::sendFile() without specifying a filename or content!"
		unless exists $params->{filename} or exists $params->{content};	

	$downloadFilename = $params->{downloadFilename}
		if exists $params->{downloadFilename};

	my $headers;
	$headers->{'-attachment'} = $downloadFilename
		if defined $downloadFilename;
	$headers->{'-type'} = $self->contentType();
	print $self->CGI()->header(%$headers);
	
	if (exists $params->{filename}) {
		my $filename = $params->{filename};
		open (INFILE,$filename)
			or die "OME::Web::sendFile() could not open $filename for reading: $!\n";
		my $buffer;
		while (read (INFILE,$buffer,32768)) {
			print $buffer;
		}
		close (INFILE);
		unlink $filename if exists $params->{temp} and $params->{temp};
	} else {
		print $params->{content};
	}
	
}

sub redirect {
	my $self = shift;
	my $URL = shift;

	print $self->CGI()->header (-type=>'text/html', -cookie => [values %{$self->{_cookies}}]);
	print qq {
		<script language="JavaScript"> 	 
			<!-- 	 
				window.location = "$URL"; 	 
			//--> 	 
		</script> 	 
	};
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
	my $template = shift;
	my $CGI	  = $self->CGI();
	my $title = $self->getPageTitle();
	my ($result,$body);
	if (!$template) {
	    ($result,$body) = $self->getAccessNotAllowedPage();
	}
	else {
	    ($result,$body) = $self->getPageBody($template);
	}
	return ('ERROR',undef) if (!defined $title || !defined $body);
	return ('HTML',$body) if ($result eq 'HTML-complete' );
	return ($result,$body) if ($result ne 'HTML');

	my $head = $CGI->start_html(
		-title => $title,
		-style => {'src' => '/html/ome2.css'},
		-script => {-language => 'JAVASCRIPT', -src => '/JavaScript/ome2.js'},
		-onLoad => $self->getOnLoadJS() || '',
		-onClick => $self->getOnClickJS() || '',
		-onKeyPress => $self->getOnKeyPressJS() || '',
	);
	
	my $body_td = $CGI->td({valign => 'top', width => '100%'}, $body);

	my $header = $self->getHeader();
	my $header_td;
	if($header){	#no header no td
		$header_td = $CGI->td({colspan => '2', class => "ome_header_td"},$header);
	}

	my $menu = $self->getMenu();
	my $menu_td;
	if($menu){	#no menu no td
		$menu_td = $CGI->td({valign => 'top', class => "ome_main_menu_td"}, $menu);
	}

	# Main TR for the menu and body
	my $main_tr = $CGI->Tr($menu_td . $body_td);

	# Packing table for the entire page
	$body = $CGI->table( {
			class       => 'ome_page_table',
			cellspacing => '0',
			cellpadding => '3',
		},
		$header_td || '',
		$main_tr,
	);
		 		 
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

Accepted status strings are C<HTML>, C<IMAGE>, C<SVG>, C<JNLP>,
    C<FILE>, C<REDIRECT>, C<XML>,  and C<ERROR>,
If the returned status is C<HTML>, then the page is appropriately decorated to match the other pages in OME.
No special processing is currently done for C<IMAGE>, C<SVG>, and C<JNLP>. For C<JNLP> the filename that should
be used on the client must also be returned e.g. 
  
  return ('JNLP', $JNLP, $filename);

A C<FILE> status is used for downloading files to the browser.  In this case, the second scalar is a hash reference
containing information to control the download process.  The hash may contain the following:

 filename         - a path to the file on the server to be downloaded.
 downloadFilename - The name of the file that should be used on the client (the browser).
 temp             - A flag that if true, will cause the downloaded file to be deleted on the server.

 return ('FILE',{filename => $myFile, downloadFilename => 'foo.txt', temp => 1});

A C<REDIRECT> status is used to get the browser to go to a different URL specified by the second scalar:

  return ('REDIRECT','http://ome.org/somewhere/else.html');

A C<XML> status indicates that the results being returned should be
    labelled with content-type "application/xml". The contents will
    also be wrapped in <OME>..</OME> tags to insure well-formedness.

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


# getAccessNotAllowedPage()
# -------------------------
# a page to be returned if getTemplate() indicates that the page
# cannot be used.
#
sub getAccessNotAllowedPage() {
    my $self = shift;
    my $cgi = $self->CGI();

    my $tmpl = OME::Web::TemplateManager->getAccessDeniedTemplate();
    my $referer = $cgi->referer();
    $tmpl->param(previousPage => $cgi->referer()) if ($referer);
    
    return ('HTML',$tmpl->output());
}


sub getOnLoadJS { return undef };  # Default
sub getOnClickJS { return undef };  # Default
sub getOnKeyPressJS { return undef };  # Default

=head2 getMenu
=cut
sub getMenu {
	my $self = shift;
	my $menu;	

	unless ($self->{_popup} or $self->{_nomenu}) {
		my $menu_template;
		$menu_template = OME::Web::TemplateManager->getActionTemplate("Menu.tmpl");
		$menu_template->param(guest => ($self->Session()->isGuestSession()));
		$menu = $menu_template->output();
	}
	return $menu;
}
=head2 getHeader
=cut
sub getHeader{
	my $self = shift;
	my $header;
        my $CGI = $self->{CGI};
	
	my $session = OME::Session->instance();
	
	unless ($self->{_popup} or $self->{_nomenu}) {
		my ($project_links,$dataset_links);
		my $full_name = $session->User->FirstName . ' ' . $session->User->LastName;
		if (my $obj = $session->project()) { $project_links = $CGI->a({href => OME::Web->getObjDetailURL( $obj ), class => 'ome_quiet'}, $obj->name()); } # Recent Project
		if (my $obj = $session->dataset()) { $dataset_links = $CGI->a({href => OME::Web->getObjDetailURL( $obj ), class => 'ome_quiet'}, $obj->name()); } # Recent dataset
		
		my $header_template;
		$header_template = OME::Web::TemplateManager->getActionTemplate("Header.tmpl");
		$header_template->param(guest => $session->isGuestSession());
		$header_template->param(user => $full_name);
		$header_template->param(project => $project_links);
		$header_template->param(dataset => $dataset_links);
		$header = $header_template->output();
	}
	return $header;
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

=head2 _loadTypeAndGetInfo

	my ($package_name, $common_name, $formal_name, $ST) = 
		$self->_loadTypeAndGetInfo( $type );

$type can be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either

Loads the package appropriately and returns descriptive information.

$package_name is the name of the DBObject package
$common_name is a name suitable for display
$formal_name is the name suitable for passing as a parameter or to functions
	(package name for standard DBObjects, @AttrName for Attributes)
$ST is the Semantic Type if $type is a ST or attribute. Otherwise it's undef.

=cut

sub _loadTypeAndGetInfo {
	my ($proto, $type) = @_;
	confess "type is undefined!" unless defined $type;
	confess "type is blank!" if $type eq '';

	my ($package_name, $common_name, $formal_name, $ST);
	
	# Set formal_name
	if( ref($type) ) {
		$formal_name = ref( $type );
	} else {
		$formal_name = $type;
	}
	$formal_name =~ s/^OME::SemanticType::__/@/;
	
	# Attribute: load Info and package
	if( $formal_name =~ /^@/ ) {
		my $session = OME::Session->instance();
		$common_name = substr( $formal_name, 1 );
		$ST = $session->Factory->findObject("OME::SemanticType", name => $common_name)
			or confess "Could not find a Semantic type with name '$common_name'";
		$ST->requireAttributeTypePackage()
			unless ref($type); # unless type is already loaded
		$package_name = $ST->getAttributeTypePackage();

	# DBObject: load info and package
	} else {
		$package_name = $formal_name;
		$package_name->require()
			or confess "Error loading package $package_name.";
		$common_name = $package_name;
		$common_name =~ s/OME:://;
		$common_name =~ s/::/ /g;
	}
	
	return ($package_name, $common_name, $formal_name, $ST);	
}


=head2 getObjDetailURL

	my $url_to_obj_detail = $self->getObjDetailURL( $obj, %url_params );

$obj should be a DBObject instance. Attributes are fine.
%url_params is optional. If specified, it should contain a list of URL
parameters such as ( Popup => 1 ).

returns a url to a detailed view of the object

=cut

sub getObjDetailURL {
	my ($self, $obj, %url_params) = @_;
	my $formal_name = $obj->getFormalName();

	return $self->pageURL( 'OME::Web::DBObjDetail', { 
		Type => $formal_name,
		ID   => $obj->id(),
		( (ref( $self ) )&& ( exists $self->{_popup} ) && ( $self->{_popup} ) ?
			( Popup => 1 ) :
			()
		),
		%url_params
	} );
}

=head2 getSearchAccessorURL

	my $search_url = $self->getSearchAccessorURL( $obj, $method );

$obj should be a DBObject instance. Attributes are fine.
$method should be a 'has-many' or 'many-to-many' method of $obj

returns a url to a search page for whatever is returned from $obj's $method

=cut

sub getSearchAccessorURL {
	my ($self, $obj, $method) = @_;
	my $type = $obj->getColumnType( $method ); # This has a side effect of loading the possibly inferred method
	my $searchTypeFormalName = $obj->getAccessorReferenceType( $method )->getFormalName();

	if( $type eq "has-many" ) {
		# An example of the parameters resulting here is:
		#	$obj == 'CategoryGroup'
		#	$method == 'CategoryList'
		# We need to know the formal name of the type returned by CategoryList()
		# and need to get the foreign key in Category that refers to CategoryGroup
		my ( $foreign_key_class, $foreign_key_alias ) = 
			@{ $obj->__hasManys()->{$method} };
		return $self->pageURL( 'OME::Web::Search', {
			SearchType         => $searchTypeFormalName,
			$foreign_key_alias => $obj->id()
		} );
	} elsif( $type eq "many-to-many" ) {
		# Derive the path that connects $obj->method to what it returns
		my $path = $obj->getManyToManyAliasSearchPath( $method );
		return $self->pageURL("OME::Web::Search", {
			SearchType      => $searchTypeFormalName,
			search_names    => $path,
			$path           => $obj->id
		} );
	}
}

=head2 getSearchURL

	my $search_url = $self->getSearchURL( $obj_type, @search_params );

same input parameters as $factory->findObjects()

returns a url to a search page that corresponds to that kind of DB search

=cut

sub getSearchURL {
	my ($self, $obj_type, %search_params) = @_;
	my ($package_name, $common_name, $formal_name, $ST) = 
		$self->_loadTypeAndGetInfo( $obj_type );
	my @url_params;
	# Parse search_params into something that is url-friendly
	foreach my $search_field ( keys %search_params ) {
		my $search_value = $search_params{ $search_field };
		push( @url_params, $search_field );
		# If the search value is an array, then they specified an 
		# operation and we need to do special parsing.
		# ex: owner => [ 'in', [ 1, 5, 889 ] ],
		# ex: Max   => [ '>', 582 ], ...
		if( ref( $search_value ) && ( ref( $search_value ) eq 'ARRAY' ) ) {
			my $operation = $search_value->[0];
			my $operand;
			# Deal with an operand specification, where the value is an array
			# ex: owner => [ 'in', [ 1, 5, 889 ] ], ...
			if( ref( $search_value->[1] ) && 
			    ( ref( $search_value->[1] ) eq 'ARRAY' ) ) {
			    my @safe_search_vals = map( 
					( UNIVERSAL::isa( $_, "OME::DBObject" ) ?
					  $_->id :
					  $_
					), @{ $search_value->[1] } );
				$operand = join( ',', @safe_search_vals );
			# Deal with a simple operand specification, where the value is a 
			# simple scalar
			# ex: Max => [ '>', 582 ], ...
			} else {
				$operand = $search_value->[1];
				$operand = $operand->id 
					if( UNIVERSAL::isa( $operand, "OME::DBObject" ) );
			}
			push( @url_params, $operation." ".$operand );
		# It's easier if the search value is a simple scalar
		} else {
			$search_value = $search_value->id
				if( UNIVERSAL::isa( $search_value, "OME::DBObject" ) );
			push( @url_params, $search_value );
		}
	}
	return $self->pageURL( 'OME::Web::Search', {
		SearchType      => $formal_name, 
		@url_params
	} );
}

=head2 getTableURL

	my $table_url = $self->getTableURL( $obj_type, @search_params );

same input parameters as $factory->findObjects()

returns a url to a tab delimited table page that contains the search results.

=cut

sub getTableURL {
	my ($self, $obj_type, %search_params) = @_;
	my ($package_name, $common_name, $formal_name, $ST) = 
		$self->_loadTypeAndGetInfo( $obj_type );
	my %reformattedSearchParams;
	foreach my $param ( keys %search_params ) {
		if( ref( $search_params{ $param } ) eq 'ARRAY' ) {
			if( $search_params{ $param }->[0] =~ m/^(like|ilike)$/ ) {
				$reformattedSearchParams{ $formal_name.".".$param } = 
					$search_params{ $param }->[1];
			} elsif( $search_params{ $param }->[0] eq 'in' ) {
				$reformattedSearchParams{ $formal_name.".".$param } = 
					join( ',', @{ $search_params{ $param }->[1] } )
			}
		} else {
			$reformattedSearchParams{ $formal_name.".".$param } = 
				$search_params{ $param };
		}
	}
	return $self->pageURL( 'OME::Web::DBObjTable', {
		Type      => $formal_name, 
		Format    => 'txt', 
		%reformattedSearchParams
	} );
}

=head2 getTemplateName 

for some pages that need Template parameters in the URL but may only
have them in the referer, we grab the parameter out of the referer and
redirect to new url including this parameter.

=cut 

sub getTemplateName {
    my ($self,$page,$extraParams) = @_;

    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();

    # Load the correct template and make sure the URL still carries the template
    # name.
    my $which_tmpl = $q->url_param( 'Template' );
    my $referer = $q->referer();
    my $url = $self->pageURL($page);
    if ($referer && $referer =~ m/Template=(.+)$/ && !($which_tmpl)) {
	$which_tmpl = $1;
	$which_tmpl =~ s/%20/ /;
	return ('REDIRECT',
		$self->redirect($url.'&Template='.$which_tmpl.$extraParams));
    }
    $which_tmpl =~ s/%20/ /;
    return $which_tmpl;
}

=head2

getExternalLinkText - get the appropriate url for an object of a given type
=cut

sub getExternalLinkText {
    my $self=shift;
    my ($q,$type,$obj) = @_;


    my @maps;
    
    my $mapType = $type."ExternalLinkList";
    my $text ="";
    eval { @maps = $obj->$mapType()}; 
    if (@maps && scalar(@maps) > 0 && !$@) {
	foreach my $map (@maps) {
	    my $link = $map->ExternalLink();
	    next unless $link;
	    my $desc = $link->Description();
	    my $url = $self->getExternalLinkURL($link);
	
	    if ($url ne "") {
		$text .= "<span class=\"ome_ext_link_text\">" .    
		    $q->a({href=>$url,class=>"ome_ext_link_text"},$desc) .
		    "</span>";
	    }
	}
    }

    # if no maps exist to build up links, return nothing
    return $text;
}

=head2 

    $self->getExternalLinkURL($externalLink);

    return the url associated with an external link. 3 possibilities
    1) if the link has a url, return it.
    2) if the link has a template, use that template and the link id
    to construct a url
    3) else return null.

=cut
sub getExternalLinkURL { 

    my $self = shift;
    my $externalLink = shift;
    
    my $id = $externalLink->ExternalId;
    my $url = $externalLink->URL();
	    
    # if we don't have a url, build one 
    # up with the template
    if (!(defined $url)) {
	my $templateObj =  $externalLink->Template();
	if ($templateObj) {
	    my $template = $templateObj->Template();
	    $template =~ s/~ID~/$id/;
	    $url = $template;
	}
    }
    return $url;
}
1;

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Josiah Johnston <siah@nih.gov>,
Ilya Goldberg <igg@nih.gov>,
Open Microscopy Environment

=cut
