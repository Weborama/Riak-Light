## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Socket;
## use critic

use Riak::Light::Timeout;
use Riak::Light::Timeout::Select;
use Riak::Light::Timeout::NoTimeout;
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

has port        => ( is => 'ro', isa => Int,  required => 1 );
has host        => ( is => 'ro', isa => Str,  required => 1 );
has timeout     => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );
has in_timeout  => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );
has out_timeout => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );

has socket  => ( is => 'lazy');

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

has timeout_provider => ( is => 'lazy');

sub _build_timeout_provider { 
  my $self = shift;
  
  Riak::Light::Timeout::NoTimeout->new(
    socket      => $self->socket,
    in_timeout  => $self->in_timeout, 
    out_timeout => $self->out_timeout
  ); 
}

sub BUILD {
  my $self = shift;
  $self->socket;
  $self->timeout_provider();
}

sub send_all {
  my ($self, $bytes) = @_;
  
  my $length = bytes::length($bytes);
  my $offset = 0;
  my $sended = 0;
  do {
    $sended = $self->timeout_provider->perform_syswrite($bytes, $length, $offset);
    
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
    $readed = $self->timeout_provider->perform_sysread($buffer, $bufsiz, $offset);
    # error in $!
    return unless defined $readed;
    
    # test if $sended == 0 and $! EAGAIN, EWOULDBLOCK, ETC...
    return unless $readed;

    $offset += $readed;
  } while($offset < $bufsiz);
  
  $buffer
}

1;