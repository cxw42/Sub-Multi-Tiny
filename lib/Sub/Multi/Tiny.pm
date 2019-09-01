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

#use Data::Dumper;   #DEBUG

use Import::Into;
use Sub::Multi::Tiny::SigParse;
use Sub::Multi::Tiny::Util;

our $VERSION = "0.000001";

# Documentation {{{1

=encoding utf-8

=head1 NAME

Sub::Multi::Tiny - Multisubs/multimethods (multiple dispatch) yet another way!

=head1 SYNOPSIS

    {
        package main::my_multi;     # We're making main::my_multi()
        use Sub::Multi::Tiny qw($foo $bar);     # All possible params

        sub first :M($foo, $bar) { # sub's name will be ignored
            return "first";
        }

        sub second :M($foo) {
            return "second";
        }

    }

    # Back in package main, my_multi() is created just before the run phase.
    say my_multi("a scalar", "and some more");  # -> "first"
    say my_multi("just a scalar");              # -> "second"

B<Limitation:> At present, dispatch is solely by arity, and only one
candidate can have each arity.  This limitation will be removed in the future.

=head1 DESCRIPTION

Sub::Multi::Tiny is a library for making multisubs, aka multimethods,
aka multiple-dispatch subroutines.

TODO explain: if sub C<MakeDispatcher()> exists in the package, it will
be called to create the dispatcher.

=cut

# }}}1

# Information about the multisubs so we can create the dispatchers at
# INIT time.
my %_multisubs;

# Sanity check: any :M will die after the INIT block below runs.
my $_dispatchers_created;

# Accessor
sub _dispatchers_created { !!$_dispatchers_created; }

# INIT Fill in the dispatchers for any multisubs we've created.
# Note: attributes are applied at CHECK time.  We use INIT since that
# way compilation failures prevent this code from running.

INIT {
    say "In INIT block";
    $_dispatchers_created = 1;
    #say STDERR Dumper(\%_multisubs);
    while(my ($multisub_fullname, $hr) = each(%_multisubs)) {
        my $dispatcher = _make_dispatcher($hr)
            or die "Could not create dispatcher for $multisub_fullname\()";

        eval { no strict 'refs'; *{$multisub_fullname} = $dispatcher };
        die "Could not assign dispatcher for $multisub_fullname\:\n$@" if $@;
    } #foreach multisub
} #CHECK

sub import {
    my $multi_package = caller;     # The package that defines the multisub
    my $my_package = shift;         # The package we are
    if(@_ && $_[0] eq ':nop') {
        say STDERR '# ' . __PACKAGE__ . ':nop => Taking no action';
        return;
    }

    say "Target $multi_package package $my_package";
    my ($target_package, $subname) = ($multi_package =~ m{^(.+?)::([^:]+)$});
        # $target_package is the package that will be able to call the multisub
    _croak "Can't parse package name ${multi_package} into <target>::<name>"
        unless $target_package && $subname;

    _croak "Can't redefine multi sub $multi_package\()"
        if exists $_multisubs{$multi_package};

    # Create the vars - they will be accessed as package variables
    my @possible_params = @_;
    _croak "Please list the sub parameters" unless @possible_params;
    vars->import::into($multi_package, @possible_params);

    # Make a stub that we will redefine later
    say "Making $multi_package\()";
    subs->import::into($target_package, $subname);
    # TODO add stub for callsame/nextwith/...

    # Save the patch
    $_multisubs{$multi_package} = {
        used_by => $target_package,
        defined_in => $multi_package,
        subname => $subname,
        possible_params => +{ map { ($_ => 1) } @possible_params },
        impls => [],    # Implementations - subs tagged :M
    };

    # Set up the :M attribute in $multi_package if it doesn't
    # exist yet.
    unless(eval { no strict 'refs'; defined &{$multi_package . '::M'} }) {
        say "Making $multi_package attr M";
        eval(_make_M($multi_package));
        die $@ if $@;
    }
} #import()

# Parse the argument list to the attribute handler
sub _parse_arglist {
    my ($spec, $funcname) = @_;
    _croak "Need a parameter spec for $funcname" unless $spec;
    say "Parsing args for $funcname: $spec";

    # TODO RESUME HERE - parse the parameter specification and return it
    my $parsed = Sub::Multi::Tiny::SigParse::Parse($spec);
} #_parse_arglist

# Create the source for the M attribute handler for a given package
sub _make_M {
    my $multi_package = shift;
    my $code = _line_mark_string
        "package $multi_package;\n";

    # TODO See if making M an :ATTR(..., BEGIN) permits us to remove the
    # requirement to list all the parameters in the `use S::M::T` line

    $code .= _line_mark_string <<'EOT';
use Attribute::Handlers;
##use Data::Dumper;

sub M :ATTR(CODE,RAWDATA) {
    ## print "In ", __PACKAGE__, "::M: \n", Dumper(\@_);
    my ($package, $symbol, $referent, $attr, $data, $phase,
        $filename, $linenum) = @_;
    my $funcname = "$package\::" . *{$symbol}{NAME};
    ## print STDERR
    ##     ref($referent), " ",
    ##     $funcname, " ",
    ##     "($referent) ", "was just declared ",
    ##     "and ascribed the ${attr} attribute ",
    ##     "with data ($data)\n",
    ##     "in phase $phase\n",
    ##     "in file $filename at line $linenum\n";
EOT

    # Trap out-of-sequence calls.  Currently you can't create a new multisub
    # via eval at runtime.  TODO use UNITCHECK instead to permit doing so?
    $code .= _line_mark_string <<EOT;
    die 'Dispatchers already created - please file a bug report'
        if @{[__PACKAGE__]}\::_dispatchers_created();

    my \$multi_def = \$_multisubs{'$multi_package'};
EOT

    # Parse and validate the args
    $code .= _line_mark_string <<EOT;
    my \$args = @{[__PACKAGE__]}\::_parse_arglist(\$data, \$funcname);
EOT

    $code .= _line_mark_string <<'EOT';
    foreach (@$args) {
        my $name = $_->{name};
        unless($multi_def->{possible_params}->{$name}) {
            die "Argument $name is not listed on the 'use Sub::Multi::Tiny' line";
        }
    }
EOT

    # Save the implementation's info for use when making the dispatcher.
    $code .= _line_mark_string <<'EOT';
    my $info = {
        code => $referent,
        args => $args,

        # For error messages
        filename => $filename,
        linenum => $linenum,
        candidate_name => $funcname
    };
    push @{$multi_def->{impls}}, $info;

} #M
EOT

    #print STDERR "M code:\n$code\n";
    return $code;
} #_make_M

# Create a dispatcher
sub _make_dispatcher {
    my $hr = shift;
    die "No implementations given for $hr->{defined_in}"
        unless @{$hr->{impls}};

    my $custom_dispatcher = do {
        no strict 'refs';
        *{ $hr->{defined_in} . '::MakeDispatcher' }{CODE}
    };

    return $custom_dispatcher->($hr) if defined $custom_dispatcher;

    # Default dispatcher
    require Sub::Multi::Tiny::DefaultDispatcher;
    return Sub::Multi::Tiny::DefaultDispatcher::MakeDispatcher($hr);
} #_make_dispatcher

1;
# Rest of the documentation {{{1
__END__

=head1 RATIONALE / SEE ALSO

TODO explain why yet another module!

=over

=item L<Class::Multimethods>

=item L<Class::Multimethods::Pure>

=item L<Dios>

=item L<Logic>

This one is fairly clean, but uses a source filter.  I have not had much
experience with source filters, so am reluctant.

=item L<Kavorka::Manual::MultiSubs> (and L<Moops>)

=item L<MooseX::MultiMethods>

I am not ready to move to full L<Moose>!

=item L<MooseX::Params>

As above.

=item L<Sub::Multi>

=item L<Sub::SmartMatch>

This one looks very interesting, but I haven't used smartmatch enough
to be fully comfortable with it.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Multi::Tiny

You can also look for information at:

=over

=item * GitHub: The project's main repository and issue tracker

L<https://github.com/cxw42/Sub-Multi-Tiny>

=item * MetaCPAN

L<Sub::Multi::Tiny>

=item * This distribution

See the tests in the C<t/> directory distributed with this software
for examples.

=back

=head1 BUGS

This isn't Damian code ;) .

=head1 AUTHOR

Chris White E<lt>cxw@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) 2019 Chris White E<lt>cxw@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# }}}1
# vi: set fdm=marker: #
