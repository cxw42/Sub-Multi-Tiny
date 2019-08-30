# NAME

Sub::Multi::Tiny - Multisub/multimethod (multiple dispatch) - Yet Another!

# SYNOPSIS

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

# DESCRIPTION

Sub::Multi::Tiny is ...

Implementations must start with `[a-z]` - any other names (e.g., `__ANON__`,
`BEGIN`) will be ignored.

# LICENSE

Copyright (C) Chris White.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Chris White <cxwembedded@gmail.com>
