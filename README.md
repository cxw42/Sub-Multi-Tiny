# NAME

Sub::Multi::Tiny - Multisubs/multimethods (multiple dispatch) yet another way!

# SYNOPSIS

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

# DESCRIPTION

Sub::Multi::Tiny is a library for making multisubs, aka multimethods,
aka multiple-dispatch subroutines.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Multi::Tiny

You can also look for information at:

- GitHub: The project's main repository and issue tracker

    [https://github.com/cxw42/Sub-Multi-Tiny](https://github.com/cxw42/Sub-Multi-Tiny)

- MetaCPAN

    [Sub::Multi::Tiny](https://metacpan.org/pod/Sub::Multi::Tiny)

- This distribution

    See the tests in the `t/` directory distributed with this software
    for examples.

# BUGS

This isn't Damian code ;) .

# LICENSE

Copyright (C) 2019 Chris White <cxw@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Chris White <cxw@cpan.org>
