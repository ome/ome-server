# ======================================================================
# 
# This is an almost un- modified version of the SOAP::Lite (version 0.55)
# SOAP::Transport::HTTP::Apache module. It has been modified to fit into the
# OME remote framework OME::Remote::Apache* set of classes.
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

package OME::Remote::Apache::Transport;

use base qw(SOAP::Transport::HTTP::Server);

sub DESTROY { SOAP::Trace::objects('()') }

sub new { require Apache; require Apache::Constants;
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
  my $r = shift || Apache->request; 

  $self->request(HTTP::Request->new( 
    $r->method => $r->uri,
    HTTP::Headers->new($r->headers_in),
    do { my $buf; $r->read($buf, $r->header_in('Content-length')); $buf; } 
  ));
  $self->SUPER::handle;

  # we will specify status manually for Apache, because
  # if we do it as it has to be done, returning SERVER_ERROR,
  # Apache will modify our content_type to 'text/html; ....'
  # which is not what we want.
  # will emulate normal response, but with custom status code 
  # which could also be 500.
  $r->status($self->response->code);
  $self->response->headers->scan(sub { $r->header_out(@_) });
  $r->send_http_header(join '; ', $self->response->content_type);
  $r->print($self->response->content);
  &Apache::Constants::OK;
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
