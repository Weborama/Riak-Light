## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light;
## use critic
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;
use IO::Socket;
use Riak::Light::PBC;
use JSON;
require bytes;

# ABSTRACT: Fast and lightweight Perl client for Riak

has port    => (is => 'ro', isa => Int,  required => 1);
has host    => (is => 'ro', isa => Str,  required => 1);
has timeout => (is => 'ro', isa => Num,  default  => sub { 0.5 });
has autodie => (is => 'ro', isa => Bool, default  => sub { 0 });

has r       => ( is => 'ro', isa => Int, default => sub { 2 });
has w       => ( is => 'ro', isa => Int, default => sub { 2 });
has rw      => ( is => 'ro', isa => Int, default => sub { 2 });

has socket  => (
  is => 'lazy'
);

sub _build_socket {
  my $self = shift;
  my $host = $self->host;
  my $port = $self->port;
  
  my $socket = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Timeout  => $self->timeout,
    Proto    => 'tcp'
  );
  
  $self->_set_last_error("Error: $! for host $host, port $port") 
    unless defined $socket;
  
  $socket
}

has last_error => (
  is => 'rwp', 
  clearer => 1,
  predicate => 1,
  default => sub { undef }
);

sub get {
  my ($self, $bucket, $key) = @_;
  
  my $request = RpbGetReq->encode({ 
    r => $self->r,
    key => $key,
    bucket => $bucket
  });
  my $request_code = 9;
  
  my ($code, $decoded_message) = $self->_perform_request($request_code, $request);
  
  return decode_json($decoded_message->content->[0]->value) 
    if $code == 10 
    and defined $decoded_message
    and defined $decoded_message->content
    and defined $decoded_message->content->[0]
    and defined $decoded_message->content->[0]->value;
  
  $self->clear_last_error() if $code == 10;
    
  undef
}

sub put {
  my ($self, $bucket, $key, $value) = @_;
  
  my $request = RpbPutReq->encode({ 
    key => $key,
    bucket => $bucket,    
    content => {
      content_type => 'application/json',
      value => encode_json($value)
    },
  });
  
  my $request_code = 11; # request 11 => PUT, response 12 => PUT
  
  my ($code, undef) = $self->_perform_request($request_code, $request);
  
  $code == 12
}

sub del {
  my ($self, $bucket, $key) = @_;
  
  my $request = RpbDelReq->encode({ 
    key => $key,
    bucket => $bucket,
    dw => $self->rw
  });
  
  my $request_code = 13; # request 13 => DEL, response 14 => DEL

  my ($code, undef) = $self->_perform_request($request_code, $request);
  
  $code == 14
}

sub _perform_request {
  my ($self, $request_code, $request) = @_; 
  
  return (-1, undef) unless( $self->socket );
  
  my $message      = pack( 'c', $request_code ) . $request;
  my $len          = bytes::length($message);
  my $operation    = pack( 'N' , $len ) . $message;

  $self->socket->syswrite($operation);
  
  my $code;
  $self->socket->sysread( $len, 4 );
  $self->socket->sysread( $code, 1 );
  
  $len  = unpack( 'N', $len );
  $code = unpack( 'c', $code );
  
  my $encoded_message;
  $self->socket->sysread( $encoded_message, $len - 1 ) if $len > 1;
  
  my %decoder = (
    0 =>  'RpbErrorResp',
    10 => 'RpbGetResp',
  );
  
  my $decoded_message = (
    defined $encoded_message
    and exists $decoder{$code} 
    and $decoder{$code}->can('decode')
    )? $decoder{$code}->decode($encoded_message) : undef;
  
  $self->_set_last_error($decoded_message) if $code == 0;
  
  ($code, $decoded_message)
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

  # store hashref into bucket 'foo', key 'bar'
  $client->put( foo => bar => { baz => 1024 })
    or die "ops... " . $client->last_error;

  # fetch hashref from bucket 'foo', key 'bar'
  my $hash = $client->get( foo => 'bar');

  # delete hashref from bucket 'foo', key 'bar'
  $client->del(foo => 'bar');