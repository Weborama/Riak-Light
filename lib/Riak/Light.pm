## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light;
## use critic

use Riak::Light::PBC;
use Riak::Light::Driver;
use Params::Validate qw(validate_pos);
use Scalar::Util qw(blessed);
use IO::Socket;
#use IO::Socket::INET;
use JSON;
use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

# ABSTRACT: Fast and lightweight Perl client for Riak

has port        => ( is => 'ro', isa => Int,  required => 1 );
has host        => ( is => 'ro', isa => Str,  required => 1 );
has r           => ( is => 'ro', isa => Int,  default  => sub {   2 } );
has w           => ( is => 'ro', isa => Int,  default  => sub {   2 } );
has rw          => ( is => 'ro', isa => Int,  default  => sub {   2 } );
has autodie     => ( is => 'ro', isa => Bool, default  => sub {   1 } );
has timeout     => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );
has in_timeout  => ( is => 'ro', predicate => 1 );
has out_timeout => ( is => 'ro', predicate => 1 );

has timeout_provider => (is => 'ro', isa => Str, default => sub { 'IO::Socket::INET' });

has driver      => ( is => 'lazy' );

sub _build_driver {
  my $self = shift;
  
  Riak::Light::Driver->new(
    socket => $self->_build_socket()
  )
}

sub _build_socket {
  my $self= shift;
  
  my $host = $self->host;
  my $port = $self->port;
  
  my $socket = IO::Socket::INET->new(
    PeerHost => $host, 
    PeerPort => $port,
    Timeout  => $self->timeout,
  ); 

  croak "Error ($!), can't connect to $host:$port"
    unless defined $socket;

  return $socket 
    if $socket->isa($self->timeout_provider);

  use Module::Load;
  load $self->timeout_provider; 

  # TODO: add a easy way to inject this proxy
  $self->timeout_provider->new(
    socket      => $socket,
    in_timeout  => ( $self->has_in_timeout  )? $self->in_timeout  : $self->timeout, 
    out_timeout => ( $self->has_out_timeout )? $self->out_timeout : $self->timeout,
   )
}

sub BUILD {
  (shift)->driver
}

sub REQUEST_OPERATION {
  my $code = shift;
  {
     1 => "ping",
     9 => "get",
    11 => "put",
    13 => "del",
  }->{$code};
}

sub ERROR_RESPONSE_CODE {  0 }
sub PING_REQUEST_CODE   {  1 }
sub PING_RESPONSE_CODE  {  2 }
sub GET_REQUEST_CODE    {  9 }
sub GET_RESPONSE_CODE   { 10 }
sub PUT_REQUEST_CODE    { 11 }
sub PUT_RESPONSE_CODE   { 12 }
sub DEL_REQUEST_CODE    { 13 }
sub DEL_RESPONSE_CODE   { 14 }
 
before [ qw(ping get put del) ] => sub {
  undef $@ ## no critic (RequireLocalizedPunctuationVars)
};
 
sub ping {
  my $self = shift;
  $self->_parse_response(
    code => PING_REQUEST_CODE, 
    body => q(),
    expected_code => PING_RESPONSE_CODE,    
  )
}


sub get {
  my ($self, $bucket, $key) = validate_pos(@_,1,1,1);
  
  my $body = RpbGetReq->encode({ 
      r => $self->r,
      key => $key,
      bucket => $bucket
    });
  
  $self->_parse_response(
    key => $key,
    bucket => $bucket,
    code => GET_REQUEST_CODE, 
    body => $body,
    expected_code => GET_RESPONSE_CODE,    
  )
}

sub put {
  my ($self, $bucket, $key, $value, $content_type) = validate_pos(@_, 1,1,1,1, { default => 'application/json'});
 
  my $encoded_value = ($content_type eq 'application/json') 
    ? encode_json($value) 
    : $value;
  
  my $body = RpbPutReq->encode({ 
       key => $key,
       bucket => $bucket,    
       content => {
         value => $encoded_value,
         content_type => $content_type,
      },
    });
    
  $self->_parse_response(
    key => $key,
    bucket => $bucket,    
    code => PUT_REQUEST_CODE, 
    body => $body,
    expected_code => PUT_RESPONSE_CODE
  );
}

sub del {
  my ($self, $bucket, $key) = validate_pos(@_,1,1,1);
  
  my $body = RpbDelReq->encode({ 
    key => $key,
    bucket => $bucket,
    dw => $self->rw
  });

  $self->_parse_response(
    key => $key,
    bucket => $bucket,    
    code => DEL_REQUEST_CODE, 
    body => $body,
    expected_code => DEL_RESPONSE_CODE,
  );
}

sub _parse_response {
  my ($self, %args)  = @_;
  
  my $request_code   = $args{code};
  my $operation      = REQUEST_OPERATION($request_code);
  my $request_body   = $args{body};
  my $response       = $self->driver->perform_request(code => $request_code, body => $request_body);
  
  my $bucket         = $args{bucket};
  my $key            = $args{key};
  my $expected_code  = $args{expected_code};
    
  my $response_code  = $response->{code} //  -1;
  my $response_body  = $response->{body};
  my $response_error = $response->{error};  
  
  # return internal error message
  use Data::Dumper;
  return $self->_process_generic_error($response_error . Dumper($response), $operation, $bucket, $key) 
    if defined $response_error;
  
  # return default message
  return $self->_process_generic_error("Unexpected Response Code in (got: $response_code, expected: $expected_code)", $operation, $bucket, $key) 
    if $response_code != $expected_code and $response_code != ERROR_RESPONSE_CODE;
  
  # return the error msg
  return $self->_process_riak_error($response_body, $operation, $bucket, $key) 
    if $response_code == ERROR_RESPONSE_CODE;
    
  # return the result from fetch  
  return $self->_process_riak_fetch($response_body, $bucket, $key)
    if $response_code == GET_RESPONSE_CODE;
    
  1  # return true value, in case of a successful put/del 
}

sub _process_riak_fetch {
  my ($self, $encoded_message, $bucket, $key) = @_;
  
  $self->_process_generic_error("Undefined Message", 'get', $bucket, $key) 
    unless( defined $encoded_message );
    
  my $decoded_message = RpbGetResp->decode($encoded_message);
  
  my $content = $decoded_message->content;
  if (ref($content) eq 'ARRAY'){
    my $value        = $content->[0]->value;
    my $content_type = $content->[0]->content_type;

    return ($content_type eq 'application/json') ? decode_json($value) : $value
  }
  
  undef
}

sub _process_riak_error {
  my ($self, $encoded_message, $operation, $bucket, $key) = @_;
  
  my $decoded_message = RpbErrorResp->decode($encoded_message);
  
  my $errmsg  = $decoded_message->errmsg;
  my $errcode = $decoded_message->errcode;
  
  $self->_process_generic_error("Riak Error (code: $errcode) '$errmsg'", $operation, $bucket, $key);
}

sub _process_generic_error {
  my ($self, $error, $operation, $bucket, $key) = @_;
  
  my $extra = ($operation ne 'ping')
    ? "(bucket: $bucket, key: $key)" 
    : q(); 
    
  my $error_message = "Error in '$operation' $extra: $error";  
  confess $error_message if $self->autodie;
  
  $@ = $error_message; ## no critic (RequireLocalizedPunctuationVars)
  
  undef
}

1;

=head1 NAME

  Riak::Light - Fast and lightweight Perl client for Riak

=head1 SYNOPSIS

  # create a new instance - using pbc only
  my $client = Riak::Light->new(
    host => '127.0.0.1',
    port => 8087
  );

  $client->ping() or die "ops, riak is not alive";

  # store hashref into bucket 'foo', key 'bar'
  $client->put( foo => bar => { baz => 1024 }, content_type => 'application/json')

  # fetch hashref from bucket 'foo', key 'bar'
  my $hash = $client->get( foo => 'bar');

  # delete hashref from bucket 'foo', key 'bar'
  $client->del(foo => 'bar');