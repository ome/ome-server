package OME::Web;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::SessionManager;
use Apache::Session::File;
use Apache;

# The OME::Web class serves as the ancestor of all webpages accessed
# through the OME system.  Functionaly common to all pages of the site
# are defined here.  Each webpage is defined by a subclass (ideally
# with a name prefixed with OME::Web::) which overrides the following
# methods:
#
#    getPageTitle
#    getPageBody


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
	border      => 0
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

    bless($self,$class);
    return $self;
}


# Accessors
# ---------

sub CGI { my $self = shift; return $self->{CGI}; }
sub DBH { my $self = shift; return $self->{manager}->DBH(); }
sub Manager { my $self = shift; return $self->{manager}; }
sub Session { my $self = shift; return $self->{session}; }
sub Factory { my $self = shift; return $self->{session}->Factory(); }
sub ApacheSession { my $self = shift; return $self->{apacheSession}; }
sub User { my $self = shift; return $self->{user}; }


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
    my $dbh = $self->DBH();

    # look for an existing session
    my $r = Apache->request;
    my $cookie = $r->header_in('Cookie');
    $cookie =~ s/SESSION_ID=(\w*)/$1/ if $cookie;
    
    #or a new session if we got no cookie my %session;
    my %apacheSession;
    tie %apacheSession, 'Apache::Session::File', $cookie, {
	Directory     => '/var/tmp/OME/sessions',
	LockDirectory => '/var/tmp/OME/lock'
	};

    my $session_cookie = "SESSION_ID=$apacheSession{_session_id};";
    $r->header_out("Set-Cookie" => $session_cookie);
    
    $self->{apacheSession} = \%apacheSession;
    my $session = undef;
    if (exists $apacheSession{username}) {
	$session = $manager->createSession($apacheSession{username},$apacheSession{password});
    }
    $self->{session} = $session;

    if (defined $session) {
	my $factory = $session->Factory();
	my $sql = "select experimenter_id from experimenters where ome_name = ?";
	my $userid = $dbh->selectrow_array($sql,{},$session->Username());
	my $user = $factory->loadObject('OME::Experimenter',$userid);

	$self->{user} = $user;
    }

    return defined $session;
}


# getLogin()
# ----------

sub getLogin {
    my $self = shift;
    $self->CGI()->redirect($self->pageURL($loginPage));
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
    my ($result,$content) = $self->createOMEPage();

    if ($result eq 'HTML' && defined $content) {
		print $self->CGI()->header('text/html');
		print $content;
    } elsif ($result eq 'IMAGE' && defined $content) {
		print $self->CGI()->header($self->contentType());
		print $content;
    } elsif ($result eq 'REDIRECT' && defined $content) {
		$self->CGI()->redirect($content);
    } else {
		my $class = ref($self);
		print $self->CGI()->header(-type => 'text/html');
		print "You shouldn't be accessing the $class page.";
    }
}


# getTopNavbar
# ------------

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

sub getSidebar {
    my $self    = shift;
    my $CGI     = $self->CGI();
    my $session = $self->Session();

    my $loginMessage = "";
    
    if (defined $session) {
	my $user = $self->User();
	my $firstName = $user->Field("firstName");
	my $lastName = $user->Field("lastName");
	$loginMessage = "<hr>$firstName $lastName";
	my $url = $self->pageURL('OME::Web::Logout');
	$loginMessage .= "<br><small><a href=\"$url\">LOGOUT</a></small>";
    }

    return  $CGI->td("Sidebar${loginMessage}<hr>Dataset info?<hr>Previously run<br>analyses?");
}

# createOMEPage
# -------------

sub createOMEPage {
    my $self  = shift;
    my $CGI   = $self->CGI();
    my $title = $self->getPageTitle();
    my ($result,$body)  = $self->getPageBody();

    return ('ERROR',undef) if (!defined $title || !defined $body);
    return ($result,$body) if ($result eq 'REDIRECT');

    my ($left,$center,$right,$html);

    $html = "";

    $left = $CGI->td($CGI->img({src    => '/images/AnimalCell.aa.jpg.png',
				width  => 105,
				height => 77,
				border => 0,
				alt    => 'Cell in mitosis'}));
    $center = $self->getTopNavbar();

    $html .= $CGI->Tr({align  => 'CENTER',
		       valign => 'MIDDLE'},
		      $left,
		      $center);

    my $bodyCell;
    
    # add some padding
    $bodyCell = $CGI->table({cellspacing => 8, cellpadding => 0, border => 0, width => '100%'},
			    $CGI->Tr($CGI->td($body)));
    $bodyCell = $CGI->td({width => '100%',
			  align => 'LEFT'},
			 $bodyCell);

    $left = $self->getSidebar();

    $html .= $CGI->Tr({align  => 'CENTER',
		       valign => 'TOP'},
		      $left,
		      $bodyCell);

    $html = $CGI->table({cellspacing => 0,
			 cellpadding => 0,
			 border      => 0,
			 width       => '100%'},
			$html);

    my $head = $CGI->start_html({title => $title,
				 bgcolor => $self->{OMEbgcolor},
				 text => 'BLACK'});
    my $tail = $CGI->end_html;

    #print STDERR $head . $html . $tail;
    return ('HTML', $head . $html . $tail);
}


# getPageTitle()
# --------------
# This should be overriden in descendant classes to return the title
# of the page.

sub getPageTitle {
    return undef;
}

# getPageBody()
# -------------
# This should be overridden in descendant classes to return the body
# of the page.  It should be returned as a tuple in the following
# form:

#
#   ('ERROR',<error message>)
#      - something unexpectedly bad happened
#
#   ('HTML',<page body>)
#      - everything worked well, returns an HTML fragment for the body
#        of the page
#
#   ('REDIRECT',<URL>)
#      - everything worked well, but instead of a page body, the user
#        should be redirected (usually in the case of processing form
#        input)


sub getPageBody {
    return ('ERROR',undef);
}


# lookup(customTable, defaultTable, key)
# --------------------------------------

sub lookup {
    my $custom  = shift;
    my $default = shift;
    my $key     = shift;

    if (defined $custom->{$key}) {
	return $custom->{$key};
    } else {
	return $default->{$key};
    }
}


# combine(default, custom, ...)
# ----------------------------------

sub combine {
    #my $custom  = shift;
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
    my $self    = shift;
    my $CGI     = $self->{CGI};
    my $params  = shift;
    my @content = @_;

    return $CGI->font(combine($self->{fontDefaults},$params),@content);
}


# contentType
# -----------------
sub contentType {
	return 'text/html';
}


# table(params, ...)
# ------------------

sub table {
    my $self    = shift;
    my $CGI     = $self->{CGI};
    my $params  = shift;
    my @content = @_;

    return $CGI->table(combine($self->{tableDefaults},$params),@content) . "\n";
}


# tableHeaders(rowParams, columnParams, ...)
# ------------------------------------------

sub tableHeaders {
    my $self      = shift;
    my $CGI       = $self->{CGI};
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
    my $self    = shift;
    my $CGI     = $self->{CGI};
    my $params  = shift;

    my $rowColor = $self->{tableRowColors}->[$self->{nextRowColor}];
    $self->{nextRowColor} = 1 - $self->{nextRowColor};

    return $CGI->Tr(combine($self->{tableRowDefaults},{bgcolor => $rowColor},$params),@_) . "\n";
}


sub tableRow {
    my $self    = shift;
    my $CGI     = $self->{CGI};
    my $params  = shift;

    return $CGI->Tr(combine($self->{tableRowDefaults},$params),@_) . "\n";
}


# tableCell(params, ...)
# ----------------------

sub tableCell {
    my $self    = shift;
    my $CGI     = $self->{CGI};
    my $params  = shift;

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
    my $CGI    = $self->{CGI};
    my $width  = shift;
    my $height = shift;

    return $CGI->img({src => "/perl/spacer.gif", width => $width, height => $height});
}


# tableLine(width)
# ----------------

sub tableLine {
    my $self  = shift;
    my $CGI   = $self->{CGI};
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
