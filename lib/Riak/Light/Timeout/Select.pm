## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout::Select;
## use critic

use POSIX qw(ETIMEDOUT);
use IO::Select;
use Time::HiRes;
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

with 'Riak::Light::Timeout';

has socket => (is => 'ro', required => 1);
has in_timeout  => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );
has out_timeout => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );
has select      => ( is => 'ro', default => sub { IO::Select->new });

sub BUILD {
  my $self = shift;
  $self->select->add($self->socket);
}

sub DEMOLISH {
  my $self = shift;
  $self->select->remove($self->socket);
}

sub perform_sysread {
  my $self = shift;
  $self->socket->sysread(@_) if $self->select->can_read($self->in_timeout);
  
  $! = ETIMEDOUT;
  
  undef
}

sub perform_syswrite {
  my $self = shift;
  $self->socket->syswrite(@_) if $self->select->can_write($self->out_timeout);
  
  $! = ETIMEDOUT;
  
  undef
}

1;