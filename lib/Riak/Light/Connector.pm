## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Connector;
## use critic

use Riak::Light::Socket;

use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

# ABSTRACT: Riak Connector, abstraction to deal with binary messages

has port    => (is => 'ro', isa => Int,  required => 1);
has host    => (is => 'ro', isa => Str,  required => 1);
has timeout => (is => 'ro', isa => Num,  default  => sub { 0.5 });

has socket  => (is => 'lazy');

sub _build_socket {
  my $self= shift;
  Riak::Light::Socket->new(
    host => $self->host, 
    port => $self->port,
    timeout => $self->timeout
  );
}

sub BUILD {
  (shift)->socket
}

sub perform_request {
  my ($self, $message) = @_; 
  
  my $bytes = pack( 'N a*' , bytes::length($message), $message);
  
  my $lenght;
    
  $self->socket->send_all($bytes)           # send request
    and $lenght = $self->read_lenght()      # read first four bytes
    and $self->socket->read_all($lenght)    # read the message
}

sub read_lenght {
  my $self = shift;
  
  my $first_four_bytes = $self->socket->read_all(4);
  
  return unpack('N', $first_four_bytes) if defined $first_four_bytes;
  
  undef
}


1;