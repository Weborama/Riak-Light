## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Driver;
## use critic

use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;
use IO::Socket;

has port    => (is => 'ro', isa => Int,  required => 1);
has host    => (is => 'ro', isa => Str,  required => 1);
has timeout => (is => 'ro', isa => Num,  default  => sub { 0.5 });

has last_error => (
  is => 'rwp', 
  clearer => 1,
  predicate => 1,
  default => sub { undef }
);

has socket  => (
  is => 'lazy'
);

sub _build_socket {
  my $self = shift;
  
  my $x = IO::Socket::INET->new(
    PeerAddr => $self->host,
    PeerPort => $self->port,
    Timeout  => $self->timeout,
    Proto    => 'tcp'
  );
  
  $self->_set_last_error("Error: $! for host @{[$self->host]}, port @{[$self->port]}") unless defined $x;
  
  $x
}

my %decoder = (
  0 =>  'RpbErrorResp',
  10 => 'RpbGetResp',
);

sub perform_request {
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

sub perform_request_get {
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