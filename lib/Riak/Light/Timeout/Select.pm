## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout::Select;
## use critic

use POSIX qw(ETIMEDOUT ECONNRESET);
use IO::Select;
use Time::HiRes;
use Config;
use Moo;
use Types::Standard -types;

with 'Riak::Light::Timeout';

# ABSTRACT: proxy to read/write using IO::Select as a timeout provider

has socket      => ( is => 'ro', required => 1 );
has in_timeout  => ( is => 'ro', isa      => Num, default => sub {0.5} );
has out_timeout => ( is => 'ro', isa      => Num, default => sub {0.5} );
has select => ( is => 'ro', default => sub { IO::Select->new } );

sub BUILD {
    my $self = shift;
    $self->select->add( $self->socket );
}

sub DEMOLISH {
    my $self = shift;
    $self->clean();
}

sub clean {
    my $self = shift;
    $self->select->remove( $self->socket );
    $self->socket->close;
}

sub is_valid {
    my $self = shift;
    scalar $self->select->handles;
}

sub sysread {
    my $self = shift;

    $self->is_valid or $! = ECONNRESET, return;    ## no critic (RequireLocalizedPunctuationVars)

    return $self->socket->sysread(@_)
      if $self->select->can_read( $self->in_timeout );

    $self->clean();
    $! = ETIMEDOUT;    ## no critic (RequireLocalizedPunctuationVars)

    undef;
}

sub syswrite {
    my $self = shift;

    $self->is_valid or $! = ECONNRESET, return;    ## no critic (RequireLocalizedPunctuationVars)

    return $self->socket->syswrite(@_)
      if $self->select->can_write( $self->out_timeout );

    $self->clean();
    $! = ETIMEDOUT;    ## no critic (RequireLocalizedPunctuationVars)

    undef;
}

1;
__END__

=head1 DESCRIPTION
  
  Internal class
