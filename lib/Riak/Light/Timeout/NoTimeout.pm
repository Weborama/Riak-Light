## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout::NoTimeout;
## use critic

use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

with 'Riak::Light::Timeout';

has socket => (is => 'ro', required => 1);
has in_timeout  => ( is => 'ro', isa => Num,  default  => sub { 0.5 } ); # ignored
has out_timeout => ( is => 'ro', isa => Num,  default  => sub { 0.5 } ); # ignored

sub perform_sysread {
  my $self = shift;
  $self->socket->sysread(@_)
}

sub perform_syswrite {
  my $self = shift;
  $self->socket->syswrite(@_)  
}

1;