## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Socket;
## use critic

use IO::Socket;
use Carp;
use Socket;
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;
require bytes;

{
  bytes::length();
}
# ABSTRACT: socket abstraction to read/write all message

has port    => (is => 'ro', isa => Int,  required => 1);
has host    => (is => 'ro', isa => Str,  required => 1);
has timeout => (is => 'ro', isa => Num,  default  => sub { 0.5 });
has socket  => (is => 'lazy');

sub _build_socket {
  my $self= shift;
  my $host = $self->host;
  my $port = $self->port;
  IO::Socket::INET->new(
    PeerHost => $host, 
    PeerPort => $port,
    Timeout  => $self->timeout,
  ) or croak "Error ($!), can't connect to $host:$port"
}

sub BUILD {
  (shift)->socket();
}

sub send_all {
  my ($self, $bytes) = @_;
  
  my $length = bytes::length($bytes);
  my $offset = 0;
  my $sended = 0;
  do {
    $sended = $self->socket->syswrite($bytes, $length, $offset);
    
    # error in $!
    return unless defined $sended;
    
    # test if $sended == 0 and $! EAGAIN, EWOULDBLOCK, ETC...
    return unless $sended;
      
    $offset += $sended;
  } while($offset < $length);
  
  $offset
}

sub read_all {
  my ($self, $bufsiz) = @_;
  
  my $buffer;
  my $offset = 0;
  my $readed = 0;
  do {
    $readed = $self->socket->sysread($buffer, $bufsiz, $offset);
    # error in $!
    return unless defined $readed;
    
    # test if $sended == 0 and $! EAGAIN, EWOULDBLOCK, ETC...
    return unless $readed;

    $offset += $readed;
  } while($offset < $bufsiz);
  
  $buffer
}

1;