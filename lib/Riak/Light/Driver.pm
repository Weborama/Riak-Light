## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Driver;
## use critic

use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;
use IO::Socket;

has port    => (is => 'ro', isa => Int,  required => 1);
has host    => (is => 'ro', isa => Str,  required => 1);
has timeout => (is => 'ro', isa => Num,  default  => sub { 0.5 });

has socket  => (
  is => 'lazy'
);

sub _build_socket {
  my $self = shift;
  
  IO::Socket::INET->new(
    PeerAddr => $self->host,
    PeerPort => $self->port,
    Timeout  => $self->timeout,
    Proto    => 'tcp'
  )
}

sub perform_request {
  my ($self, $request_code, $request, $bucket, $key) = @_; 
  
  return ( undef, undef, undef, "Error: $! for host @{[$self->host]}, port @{[$self->port]}") 
    unless( $self->socket );
  
  my $error;
  my $message      = pack( 'c', $request_code ) . $request;
  my $operation    = pack( 'N' , bytes::length($message) ) . $message;

  $self->socket->syswrite($operation);
  
  my $buffer;
  $self->socket->sysread($buffer, 1024);
  
  my ($len, $code, $encoded_message) = unpack('N c a*', $buffer);

  ($code, $request_code + 1, $encoded_message, $error)
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
  
  #$self->_set_last_error($error) ;
  
  undef
}

1;