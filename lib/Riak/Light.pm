## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light;
## use critic
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;
use IO::Socket;
use Riak::Light::PBC;
use JSON;
use Scalar::Util qw(blessed);
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
  
  my $decoded_message = $self->_perform_request_get($request_code, $request, 10);
  
  return decode_json($decoded_message->content->[0]->value) 
    if  $decoded_message 
    and blessed $decoded_message
    and defined $decoded_message->content
    and defined $decoded_message->content->[0]
    and defined $decoded_message->content->[0]->value;
  
#  $self->clear_last_error() if $code == 10;
    
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
  
  $self->_perform_request($request_code, $request, 12);
}

sub del {
  my ($self, $bucket, $key) = @_;
  
  my $request = RpbDelReq->encode({ 
    key => $key,
    bucket => $bucket,
    dw => $self->rw
  });
  
  my $request_code = 13; # request 13 => DEL, response 14 => DEL

  $self->_perform_request($request_code, $request, 14);
}

my %decoder = (
  0 =>  'RpbErrorResp',
  10 => 'RpbGetResp',
);

sub _perform_request {
  my ($self, $request_code, $request, $expected_code) = @_; 

  my $error;
  
  return 0 unless( $self->socket );
  
  my $message      = pack( 'c', $request_code ) . $request;
  my $operation    = pack( 'N' , bytes::length($message) ) . $message;

  $self->socket->syswrite($operation);
  
  my $len = $self->_read_all(4);

  return 0 unless( defined $len );

  $len  = unpack( 'N', $len );

  my $code = $self->_read_all(1);

  return 0 unless(defined $code);

  $code = unpack( 'c', $code  );

  my $encoded_message = $self->_read_all($len - 1);

  my $ok = $code == $expected_code;
  
  $self->clear_last_error if $ok;
  
  $ok
}

sub _perform_request_get {
  my ($self, $request_code, $request, $expected_code) = @_; 

  my $error;
  
  return 0 unless( $self->socket );
  
  my $message      = pack( 'c', $request_code ) . $request;
  my $operation    = pack( 'N' , bytes::length($message) ) . $message;

  $self->socket->syswrite($operation);
  
  my $len = $self->_read_all(4);
  
  return 0 unless( defined $len );
    
  $len  = unpack( 'N', $len );
  
  my $code = $self->_read_all(1);
  
  return 0 unless (defined $code);
    
  $code = unpack( 'c', $code  );
  
  my $encoded_message = $self->_read_all($len - 1);
  
  return 0 unless(defined $encoded_message);
  
  return 0 unless (exists $decoder{$code});
  
  my $decoded_message;
  if( exists $decoder{$code} ){
      $decoded_message = $decoder{$code}->decode($encoded_message);
      $self->_set_last_error($decoded_message) if $code == 0;
  } 

  return 0 unless $code == $expected_code;

  $decoded_message
}

sub _read_all {
  my ($self, $len) = @_;
  
  return undef if $len <= 0; ## no critic (ProhibitExplicitReturnUndef)
  
  my $bytes_readed = 0;
  my $encoded_message;
  my $buffer;
  my $error;
  while ($len > $bytes_readed) {
    my $readed = $self->socket->sysread( $buffer, $len - $bytes_readed);

    if(! defined $readed ){
      $error = "sysread returns Error - $!"; last
    } elsif($readed == 0){
      $error = "sysread returns EOF - probably lost connection"; last 
    }
    
    $bytes_readed += $readed;
    $encoded_message .= $buffer;
  }
  
  return $encoded_message unless  defined $error;
  
  $self->_set_last_error($error) ;
  
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

  # store hashref into bucket 'foo', key 'bar'
  $client->put( foo => bar => { baz => 1024 })
    or die "ops... " . $client->last_error;

  # fetch hashref from bucket 'foo', key 'bar'
  my $hash = $client->get( foo => 'bar');

  # delete hashref from bucket 'foo', key 'bar'
  $client->del(foo => 'bar');