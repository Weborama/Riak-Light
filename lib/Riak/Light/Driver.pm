## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Driver;
## use critic

use English qw( −no_match_vars );
use Riak::Light::Connector;
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

# ABSTRACT: Riak Driver, deal with the binary protocol

has port        => ( is => 'ro', isa => Int,  required => 1 );
has host        => ( is => 'ro', isa => Str,  required => 1 );
has timeout     => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );
has in_timeout  => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );
has out_timeout => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );
has connector   => ( is => 'lazy' );

sub _build_connector {
  my $self= shift;
  Riak::Light::Connector->new(
    host        => $self->host,
    port        => $self->port,
    timeout     => $self->timeout,
    in_timeout  => $self->in_timeout,
    out_timeout => $self->out_timeout,    
  )
}

sub BUILD {
  (shift)->connector
}

sub perform_request {
  my ($self, %request) = @_; 
  
  my $request_body = $request{body};
  my $request_code = $request{code};
  
  my $message  = pack( 'c a*', $request_code, $request_body);
  
  my $response = $self->connector->perform_request($message); 
  
  return $self->_parse_error() unless defined $response;
  
  $self->_parse_response($response)
}

sub _parse_response {
  my ($self, $response) = @_;
  my ($code, $body) = unpack('c a*', $response);

  { 
    code => $code, body => $body, error => undef 
  }
}

sub _parse_error {  
  {
    code => undef, body => undef, error => $ERRNO # $EVAL_ERROR
  }
}

1;