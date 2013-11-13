use strict;
use warnings;
package Riak::Light::TraceIt;

# ABSTRACT: add traceability

use Attribute::Handlers;
use Time::HiRes qw ( time );
use Class::Method::Modifiers;
use Data::Dumper;
use Try::Tiny;
use Scalar::Util qw(looks_like_number);
use Carp qw( croak );
use Env qw(RIAK_TRACE);

sub look_at(&@) {
    my $block = shift;

    return sub { $block->(@_); @_; }->(@_);
}

sub UNIVERSAL::TraceIt : ATTR(CODE) {
	my ($pkg, $symbol, undef, undef, $args) = @_;

	my ($level, %flags) = @{$args // []};

    $level //= 0;

    my $now           = $flags{now}            // sub { sprintf '%.5f', time };
    my $dumper        = $flags{dumper}         // \&Dumper;
    my $omit_return   = $flags{omit_return}    // 0;
    my $omit_throw    = $flags{omit_throw}     // 0;
    my $dumper_indent = $flags{dumper_indent}  // 0; 
    my $dumper_terse  = $flags{dumper_terse}   // 1;
    my $show_file_line= $flags{show_file_line} // 1;
	my $should_trace  = $flags{__should_trace} // sub { 
        return ($RIAK_TRACE // -1) >= $level;
    };

    return unless $should_trace->();

	my $in  = '>' x $level;
	my $out = '<' x $level;
    my $err = '!' x $level;

    my $sub = $pkg . '::' . *{$symbol}{NAME};

    after $sub => sub {
        # magic
        # for some reason, without this, I can't inspect 
        # the return value in the look_at block
    };

    around $sub => sub {
        my $orig = shift;
        my $self = shift;
        my @args = @_;
        
        local $Data::Dumper::Indent = $dumper_indent;
        local $Data::Dumper::Terse  = $dumper_terse;

        my $file_line = "";
        if ($show_file_line){
            my ($file, $line) = (caller(1))[1,2];
            $file_line = "at $file line $line";
        }
        
        my $args = $dumper->(\@_);
        print STDERR "@{[ $now->() ]} $in\t $sub\t with args $args $file_line.\n";

        try {
            look_at { 
                my $ret = $omit_return ? '...' : $dumper->(\@_);
                print STDERR "@{[ $now->() ]} $out\t $sub\t returns $ret $file_line.\n";
            } 
            $self->$orig(@args);
        
        } catch {
            my $exception = $omit_throw ? '...': $dumper->($_);
            print STDERR "@{[  $now->() ]} $err\t $sub\t throws exception => $exception\n";
            
            die $_;
        }
    };

    1;
}

1;