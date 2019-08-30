package Sub::Multi::Tiny;

# Test string:
# perl -Ilib -E '{package main::my_multi; use Sub::Multi::Tiny; sub foo { say -foo }; sub bar { say -bar } }'

# Test string for attributes:
# $ perl -MData::Dumper -Mstrict -Mwarnings -E 'use Attribute::Handlers; sub Foo::Loud :ATTR { say "Foo::Loud ATTR called"; say Dumper(\@_); } package Foo; sub bar :Loud {say "Foo::bar" } package main; say -before; Foo::bar; say -after;'

# Test string for this module:
# perl -Ilib -Mstrict -Mwarnings -MCarp::Always -E 'package main::multi; use Sub::Multi::Tiny qw($foo); sub try :M($foo, @bar) { ... }'

use 5.010001;
use strict;
use subs ();
use vars ();
use warnings;

use Import::Into;

our $VERSION = "0.000001";

# Documentation {{{1

=encoding utf-8

=head1 NAME

Sub::Multi::Tiny - Multisub/multimethod (multiple dispatch) - Yet Another!

=head1 SYNOPSIS

    {
        package main::my_multi;     # We're making main::my_multi()
        use Sub::Multi::Tiny qw($foo, $bar, @quux);     # All possible params

        sub first :M($foo, @quux) { # Name will be ignored
            print "first\n";
        }

        sub second :M($foo) {
            print "second\n";
        }

    }

    my_multi("just a scalar");              # -> second
    my_multi("a scalar", "and some more");  # -> first

=head1 DESCRIPTION

Sub::Multi::Tiny is ...

Implementations must start with C<[a-z]> - any other names (e.g., C<__ANON__>,
C<BEGIN>) will be ignored.

=cut

# }}}1

# Lazy-load Carp
sub _croak {
    require Carp;
    goto &Carp::croak;
}

# Subs we need to patch up at CHECK time
my %_patches;

sub import {
    my $multi_package = caller;     # The package that defines the multisub
    my $my_package = shift;         # The package we are
    say "Target $multi_package package $my_package";
    my ($target_package, $subname) = ($multi_package =~ m{^(.+?)::([^:]+)$});
        # $target_package is the package that will be able to call the multisub
    _croak "Can't parse package name ${multi_package} into <target>::<name>"
        unless $target_package && $subname;

    _croak "Can't redefine multi sub $multi_package\()"
        if exists $_patches{$multi_package};

    # Make a stub that we will redefine later
    say "Making $multi_package\()";
    subs->import::into($target_package, $subname);
    # TODO add stub for callsame/nextwith/...

    # Add in the vars - they will be accessed as package parameters
    _croak "Please list the sub parameters" unless @_;
    vars->import::into($multi_package, @_);

    # Save the patch
    $_patches{$multi_package} = {
        used_by => $target_package,
        defined_in => $multi_package,
        subname => $subname,
    };

    # Set up the :M attribute in $multi_package if it doesn't
    # exist yet.
    unless(eval { no strict 'refs'; defined &{$multi_package . '::M'} }) {
        say "Making $multi_package attr M";
        eval(_make_M($multi_package));
        die $@ if $@;
    }
} #import()

# Create the source for the M attribute handler for a given package
sub _make_M {
    my $multi_package = shift;
    my $code = "package $multi_package;\n#line " . (__LINE__+1) . ' ' . __FILE__ . "\n" . <<'EOT';
use Attribute::Handlers;
use Data::Dumper;

sub M :ATTR(CODE,RAWDATA) {
    print "In ", __PACKAGE__, "::M: \n", Dumper(\@_);
    my ($package, $symbol, $referent, $attr, $data, $phase,
        $filename, $linenum) = @_;
    print STDERR
        ref($referent), " ",
        *{$symbol}{NAME}, " ",
        "($referent) ", "was just declared ",
        "and ascribed the ${attr} attribute ",
        "with data ($data)\n",
        "in phase $phase\n",
        "in file $filename at line $linenum\n";
} #M
EOT

} #_make_M

# INIT: Fill in the dispatchers for any multisubs we've created.
# In INIT because attributes are applied at CHECK time.

INIT {
    while(my ($multi_package, $hr) = each(%_patches)) {
        say "Patching $hr->{subname} (not really)";
        my $multi_package = $hr->{defined_in} . '::';
        my $stash = do { no strict 'refs'; \%{$multi_package} };
        _croak "Could not load stash for $multi_package" unless $stash;

        foreach my $varname (keys %$stash) {
            say "Checking key $varname";
            next unless $varname =~ /^[a-z]/;
            next unless do { no strict 'refs';
                                defined &{$multi_package . $varname} };
                # Thanks to zentara,
                # https://www.perlmonks.org/?node_id=697760

            say "Found implementation $varname";
        }
    }
}

1;
# Rest of the documentation {{{1
__END__

=head1 LICENSE

Copyright (C) Chris White.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Chris White E<lt>cxwembedded@gmail.comE<gt>

=cut

# }}}1
# vi: set fdm=marker: #
