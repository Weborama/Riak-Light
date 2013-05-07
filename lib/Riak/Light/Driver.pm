## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Driver;
## use critic

use English qw( −no_match_vars );
use Riak::Light::Connector;
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

has port     => (is => 'ro', isa => Int,  required => 1);
has host     => (is => 'ro', isa => Str,  required => 1);
has timeout  => (is => 'ro', isa => Num,  default  => sub { 0.5 });
has connector => ( is => 'lazy' );

sub _build_connector {
  my $self= shift;
  Riak::Light::Connector->new(
    host => $self->host,
    port => $self->port,
    timeout => $self->timeout
  )
}

sub BUILD {
  (shift)->connector
}

sub perform_request {
  my ($self, $request) = @_; 
  
  my $request_body = $request->{body};
  my $request_code = $request->{code};
  
  my $message = pack( 'c a*', $request_code, $request_body);
  my $response;
  
  $response = $self->connector->perform_request($message)
    and $self->parse_response($response)
    or  $self->parse_error()
}

sub parse_response {
  my ($self, $response) = @_;
  my ($code, $body) = unpack('c a*', $response);

  { 
    code => $code, body => $body, error => undef 
  }
}

sub parse_error {  
  {
    code => undef, body => undef, error => "LOL $ERRNO '$EVAL_ERROR'"  # $EVAL_ERROR
  }
}

1;