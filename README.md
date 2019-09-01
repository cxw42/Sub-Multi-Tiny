# NAME

Sub::Multi::Tiny - Multisubs/multimethods (multiple dispatch) yet another way!

# SYNOPSIS

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

**Limitation:** At present, dispatch is solely by arity, and only one
candidate can have each arity.  This limitation will be removed in the future.

# DESCRIPTION

Sub::Multi::Tiny is a library for making multisubs, aka multimethods,
aka multiple-dispatch subroutines.

TODO explain: if sub `MakeDispatcher()` exists in the package, it will
be called to create the dispatcher.

# RATIONALE / SEE ALSO

TODO explain why yet another module!

- [Class::Multimethods](https://metacpan.org/pod/Class::Multimethods)
- [Class::Multimethods::Pure](https://metacpan.org/pod/Class::Multimethods::Pure)
- [Dios](https://metacpan.org/pod/Dios)
- [Logic](https://metacpan.org/pod/Logic)

    This one is fairly clean, but uses a source filter.  I have not had much
    experience with source filters, so am reluctant.

- [Kavorka::Manual::MultiSubs](https://metacpan.org/pod/Kavorka::Manual::MultiSubs) (and [Moops](https://metacpan.org/pod/Moops))
- [MooseX::MultiMethods](https://metacpan.org/pod/MooseX::MultiMethods)

    I am not ready to move to full [Moose](https://metacpan.org/pod/Moose)!

- [MooseX::Params](https://metacpan.org/pod/MooseX::Params)

    As above.

- [Sub::Multi](https://metacpan.org/pod/Sub::Multi)
- [Sub::SmartMatch](https://metacpan.org/pod/Sub::SmartMatch)

    This one looks very interesting, but I haven't used smartmatch enough
    to be fully comfortable with it.

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

# AUTHOR

Chris White <cxw@cpan.org>

# LICENSE

Copyright (C) 2019 Chris White <cxw@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
