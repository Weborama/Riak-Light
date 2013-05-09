## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout::SelectOnRead;
## use critic

use POSIX qw(ETIMEDOUT ECONNRESET);
use IO::Select;
use Time::HiRes;
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

with 'Riak::Light::Timeout';

# ABSTRACT: proxy to read/write using IO::Select as a timeout provider only for READ operations

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
    $! = ETIMEDOUT;    ## no critic (RequireLocalizedPunctuationVars)
}

sub is_valid {
    my $self = shift;
    scalar $self->select->handles;
}

around [qw(sysread syswrite)] => sub {
    my $orig = shift;
    my $self = shift;

    if ( !$self->is_valid ) {
        $! = ECONNRESET;    ## no critic (RequireLocalizedPunctuationVars)
        return;
    }

    $self->$orig(@_);
};

sub sysread {
    my $self = shift;

    return $self->socket->sysread(@_)
      if $self->select->can_read( $self->in_timeout );

    $self->clean();

    undef;
}

sub syswrite {
    my $self = shift;

    $self->socket->syswrite(@_);
}

1;
