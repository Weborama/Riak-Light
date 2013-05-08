## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout::Alarm;
## use critic

use POSIX qw(ETIMEDOUT);
use Time::Out qw(timeout);
use Time::HiRes;
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

with 'Riak::Light::Timeout';

has socket => (is => 'ro', required => 1);
has in_timeout  => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );
has out_timeout => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );

sub perform_sysread {
  my $self    = shift;
  my $seconds = $self->in_timeout;
  my $result  = timeout $seconds, @_ => sub {
    $self->socket->sysread(@_) 
  };
  if($@){
    $! = ETIMEDOUT;
  }
  $result
}

sub perform_syswrite {
  my $self    = shift;
  my $seconds = $self->out_timeout;
  my $result  = timeout $seconds, @_ => sub {
    $self->socket->syswrite(@_) 
  };
  if($@){
    $! = ETIMEDOUT;
  }
  $result
}

1;