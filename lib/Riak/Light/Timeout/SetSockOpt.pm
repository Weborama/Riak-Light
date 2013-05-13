## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout::SetSockOpt;
## use critic

use POSIX qw(ETIMEDOUT ECONNRESET);
use Socket;
use IO::Select;
use Time::HiRes;
use Config;
use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

with 'Riak::Light::Timeout';

# ABSTRACT: proxy to read/write using IO::Select as a timeout provider only for READ operations. EXPERIMENTAL!

has socket      => ( is => 'ro', required => 1 );
has in_timeout  => ( is => 'ro', isa      => Num, default => sub {0.5} );
has out_timeout => ( is => 'ro', isa      => Num, default => sub {0.5} );
has is_valid    => ( is => 'rw', isa      => Bool, default => sub {1} );

sub BUILD {
    my $self = shift;

    carp "This Timeout Provider is EXPERIMENTAL!";

    croak "no supported yet"
      if (  $Config{osname} eq 'netbsd'
        and $Config{osvers} >= 6.0
        and $Config{longsize} == 4 );
    ## TODO: see https://metacpan.org/source/ZWON/RedisDB-2.12/lib/RedisDB.pm#L235

    my $seconds  = int( $self->in_timeout );
    my $useconds = int( 1_000_000 * ( $self->in_timeout - $seconds ) );
    my $timeout  = pack( 'l!l!', $seconds, $useconds );

    $self->socket->setsockopt( SOL_SOCKET, SO_RCVTIMEO, $timeout )
      or croak "setsockopt(SO_RCVTIMEO): $!";
    $self->socket->setsockopt( SOL_SOCKET, SO_SNDTIMEO, $timeout )
      or croak "setsockopt(SO_SNDTIMEO): $!";
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

sub clean {
    my $self = shift;
    $self->socket->close();
    $self->is_valid(0);
    $! = ETIMEDOUT;         ## no critic (RequireLocalizedPunctuationVars)
}

sub sysread {
    my $self = shift;

    my $result = $self->socket->sysread(@_);

    $self->clean() unless ($result);

    $result;
}

sub syswrite {
    my $self = shift;

    my $result = $self->socket->syswrite(@_);

    $self->clean() unless ($result);

    $result;
}

1;

__END__

=head1 NAME

  Riak::Light::Timeout::SetSockOpt -IO Timeout based on setsockopt (Experimental) for Riak::Light

=head1 VERSION

  version 0.001

=head1 DESCRIPTION
  
  Internal class