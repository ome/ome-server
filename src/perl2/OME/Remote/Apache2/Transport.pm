# ======================================================================
# 
# This is a semi-heavily modified version of the SOAP::Lite (version 0.55)
# SOAP::Transport::HTTP::Apache module. It has been modified to fit into the
# OME remote framework OME::Remote::Apache* set of classes as well as to work
# with Apache2.
# 
# -Chris Allan <callan@blackcat.ca>
#
# ** Original Copyright **
#
# Copyright (C) 2000-2001 Paul Kulchenko (paulclinger@yahoo.com)
# SOAP::Lite is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# ======================================================================

package OME::Remote::Apache2::Transport;
 
use base qw(SOAP::Transport::HTTP::Server);
 
require Apache2;
require Apache::RequestRec;
require Apache::RequestIO;
require Apache::Const;
require APR::Table;

Apache::Const->import(-compile => 'OK');

sub DESTROY { SOAP::Trace::objects('()') }
                                                                                
sub new {
  my $self = shift;

  unless (ref $self) {
    my $class = ref($self) || $self;
    $self = $class->SUPER::new(@_);
	SOAP::Trace::objects('()');
  }
  return $self;
}

sub handler {
  my $self = shift->new;
  my $r = shift;

  $self->request(HTTP::Request->new(
    $r->method() => $r->uri,
    HTTP::Headers->new($r->headers_in),
        do {
			my ($content, $buf);
			while ($r->read($buf, $r->headers_in->{'Content-length'}))
			{
				$content .= $buf;
			}
			$content;
		}
	));
  $self->SUPER::handle;

  # we will specify status manually for Apache, because
  # if we do it as it has to be done, returning SERVER_ERROR,
  # Apache will modify our content_type to 'text/html; ....'
  # which is not what we want.
  # will emulate normal response, but with custom status code
  # which could also be 500.
  $r->status($self->response->code);
  $self->response->headers->scan(sub { $r->headers_out->set(@_) });
  $r->content_type($self->response->content_type);
  $r->print($self->response->content);

  return Apache::OK;
}

sub configure {
  my $self = shift->new;
  my $config = shift->dir_config;
  foreach (%$config) {
	$config->{$_} =~ /=>/
      ? $self->$_({split /\s*(?:=>|,)\s*/, $config->{$_}})
      : ref $self->$_() ? () # hm, nothing can be done here
                        : $self->$_(split /\s+|\s*,\s*/, $config->{$_})
      if $self->can($_);
  }
  $self;
}
                                                                                
{ sub handle; *handle = \&handler } # just create alias
