## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout::SetSockOpt;
## use critic

use POSIX qw(ETIMEDOUT ECONNRESET);
use Socket;
use IO::Select;
use Time::HiRes;
use Config;
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

with 'Riak::Light::Timeout';

# ABSTRACT: proxy to read/write using IO::Select as a timeout provider only for READ operations

has socket      => ( is => 'ro', required => 1 );
has in_timeout  => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );
has out_timeout => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );
has is_valid    => ( is => 'rw', isa => Bool, default  => sub {   1 } );

sub BUILD {
  my $self = shift;
  
  die "no supported yet" 
    if ( $Config{osname} eq 'netbsd' and $Config{osvers} >= 6.0 and $Config{longsize} == 4 );

  my $seconds  = int( $self->in_timeout );
  my $useconds = int( 1_000_000 * ( $self->in_timeout - $seconds ) );
  my $timeout  = pack('l!l!', $seconds, $useconds);

  $self->socket->setsockopt(SOL_SOCKET, SO_RCVTIMEO, $timeout) or die "setsockopt(SO_RCVTIMEO): $!";
  $self->socket->setsockopt(SOL_SOCKET, SO_SNDTIMEO, $timeout) or die "setsockopt(SO_SNDTIMEO): $!";
}

sub sysread {
  my $self = shift;
  
  if(! $self->is_valid()){
    $! = ECONNRESET;
    return
  }
    
  my $result = $self->socket->sysread(@_);
  
  unless($result){
    $self->socket->close();
    $self->is_valid(0);
    $! = ETIMEDOUT;
  };
  
  $result
}

sub syswrite {
  my $self = shift;
  
  if(! $self->is_valid()){
    $! = ECONNRESET;
    return
  }
  
  $self->socket->syswrite(@_) 
}

1;