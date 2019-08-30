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

Sub::Multi::Tiny - Multisubs/multimethods (multiple dispatch) yet another way!

=head1 SYNOPSIS

    {
        package main::my_multi;     # We're making main::my_multi()
        use Sub::Multi::Tiny qw($foo, $bar, @quux);     # All possible params

        sub first :M($foo, @quux) { # sub's name will be ignored
            print "first\n";
        }

        sub second :M($foo) {
            print "second\n";
        }

    }

    # Back in package main, my_multi() is created just before the run phase.
    my_multi("just a scalar");              # -> second
    my_multi("a scalar", "and some more");  # -> first

=head1 DESCRIPTION

Sub::Multi::Tiny is a library for making multisubs, aka multimethods,
aka multiple-dispatch subroutines.

=cut

# }}}1

# Lazy-load Carp
sub _croak {
    require Carp;
    goto &Carp::croak;
}

# Information about the multisubs so we can create the dispatchers at
# CHECK time.
my %_multisubs;

# Sanity check: any :M will die after the CHECK block below runs.
my $_did_check_run;

# CHECK: Fill in the dispatchers for any multisubs we've created.
# Note: attributes are applied at CHECK time.  TODO see if this happens
# late enough to work.

CHECK {
    say "In CHECK block";
    $_did_check_run = 1;
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
    say "Target $multi_package package $my_package";
    my ($target_package, $subname) = ($multi_package =~ m{^(.+?)::([^:]+)$});
        # $target_package is the package that will be able to call the multisub
    _croak "Can't parse package name ${multi_package} into <target>::<name>"
        unless $target_package && $subname;

    _croak "Can't redefine multi sub $multi_package\()"
        if exists $_multisubs{$multi_package};

    # Make a stub that we will redefine later
    say "Making $multi_package\()";
    subs->import::into($target_package, $subname);
    # TODO add stub for callsame/nextwith/...

    # Add in the vars - they will be accessed as package parameters
    _croak "Please list the sub parameters" unless @_;
    my @possible_params = @_;
    vars->import::into($multi_package, @possible_params);

    # Save the patch
    $_multisubs{$multi_package} = {
        used_by => $target_package,
        defined_in => $multi_package,
        subname => $subname,
        possible_params => [@possible_params],
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

#=head2 _line_mark_string
#
#Add a C<#line> directive to a string.  Usage:
#
#    my $str = _line_mark_string <<EOT ;
#    $contents
#    EOT
#
#or
#
#    my $str = _line_mark_string __FILE__, __LINE__, <<EOT ;
#    $contents
#    EOT
#
#In the first form, information from C<caller> will be used for the filename
#and line number.
#
#The C<#line> directive will point to the line after the C<_line_mark_string>
#invocation, i.e., the first line of <C$contents>.  Generally, C<$contents> will
#be source code, although this is not required.
#
#C<$contents> must be defined, but can be empty.
#
#=cut

sub _line_mark_string {
    my ($contents, $filename, $line);
    if(@_ == 1) {
        $contents = $_[0];
        (undef, $filename, $line) = caller;
    } elsif(@_ == 3) {
        ($filename, $line, $contents) = @_;
    } else {
        _croak "Invalid invocation";
    }

    _croak "Need text" unless defined $contents;
    die "Couldn't get location information" unless $filename && $line;

    $filename =~ s/"/-/g;
    ++$line;

    return <<EOT;
#line $line "$filename"
$contents
EOT
} #_line_mark_string()

# Parse the argument list to the attribute handler
sub _parse_arglist {
    my ($spec, $funcname) = @_;
    _croak "Need a parameter spec for $funcname" unless $spec;
    say "Parsing args for $funcname: $spec";

    # TODO RESUME HERE - parse the parameter specification and return it
} #_parse_arglist

# Create the source for the M attribute handler for a given package
sub _make_M {
    my $multi_package = shift;
    my $code = "package $multi_package;\n";
    $code .= _line_mark_string <<'EOT';
use Attribute::Handlers;
use Data::Dumper;

sub M :ATTR(CODE,RAWDATA) {
    print "In ", __PACKAGE__, "::M: \n", Dumper(\@_);
    my ($package, $symbol, $referent, $attr, $data, $phase,
        $filename, $linenum) = @_;
    my $funcname = "$package\::" . *{$symbol}{NAME};
    print STDERR
        ref($referent), " ",
        $funcname, " ",
        "($referent) ", "was just declared ",
        "and ascribed the ${attr} attribute ",
        "with data ($data)\n",
        "in phase $phase\n",
        "in file $filename at line $linenum\n";

    die "CHECK already ran - please file a bug report" if $_did_check_run;
EOT

    # Parse and validate the args
    $code .= _line_mark_string <<EOT;
    my \$args = @{[__PACKAGE__]}\::_parse_arglist(\$data, \$funcname);
    # TODO add code to validate the args against {possible_params}
EOT

    # Save the implementation's coderef and the parsed args
    # for use when making the dispatcher.
    $code .= _line_mark_string <<EOT;
    push \@{\$_multisubs{'$multi_package'}->{impls}}, [\$referent, \$args];
EOT

    $code .= _line_mark_string <<'EOT';
} #M
EOT

    #print STDERR "M code:\n$code\n";
    return $code;
} #_make_M

# Create a dispatcher
sub _make_dispatcher {
    my $hr = shift;
    use Data::Dumper;
    say "Making dispatcher for: ", Dumper($hr);
    die "No implementations given for $hr->{defined_in}"
        unless @{$hr->{impls}};
} #_make_dispatcher

1;
# Rest of the documentation {{{1
__END__

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

=head1 LICENSE

Copyright (C) 2019 Chris White E<lt>cxw@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Chris White E<lt>cxw@cpan.orgE<gt>

=cut

# }}}1
# vi: set fdm=marker: #
