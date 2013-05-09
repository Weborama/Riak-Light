## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout::Alarm;
## use critic

use POSIX qw(ETIMEDOUT ECONNRESET);
use Time::Out qw(timeout);
use Time::HiRes;
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

with 'Riak::Light::Timeout';

# ABSTRACT: proxy to read/write using Time::Out as a timeout provider

has socket => (is => 'ro', required => 1);
has in_timeout  => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );
has out_timeout => ( is => 'ro', isa => Num,  default  => sub { 0.5 } );
has is_valid    => ( is => 'rw', isa => Bool, default  => sub {   1 } );

sub clean {
  my $self= shift;
  $self->socket->close;
  $self->is_valid(0);
}

around [ qw(sysread syswrite) ] => sub {
  my $orig = shift;
  my $self = shift;
  
  if (! $self->is_valid) {
    $! = ECONNRESET; ## no critic (RequireLocalizedPunctuationVars)
    return
  }
  
  $self->$orig(@_)
};

sub sysread {
  my $self    = shift;

  my $buffer;
  my $seconds = $self->in_timeout;
  my $result  = timeout $seconds, @_ => sub {
    my $readed = $self->socket->sysread(@_);
    $buffer = $_[0]; # NECESSARY, timeout does not map the alias @_ !!
    $readed
  };
  if($@){
    $self->clean(); 
    $! = ETIMEDOUT; ## no critic (RequireLocalizedPunctuationVars)
  } else {
    $_[0] = $buffer;
  }
 
  $result
}

sub syswrite {
  my $self    = shift;

  my $seconds = $self->out_timeout;
  my $result  = timeout $seconds, @_ => sub {
    $self->socket->syswrite(@_) 
  };
  if($@){
    $self->clean();
    $! = ETIMEDOUT; ## no critic (RequireLocalizedPunctuationVars)
  }

  $result
}

1;