use 5.010001;
use strict;
use warnings;
use Test::More;

{
    package main::my_multi;     # We're making main::my_multi()
    use Sub::Multi::Tiny qw($foo $bar);    # All possible params

    sub first :M($foo, $bar) { # sub's name will be ignored
        return "first";
    }

    sub second :M($foo) {
        return "second";
    }

}

#use Data::Dumper;
#diag Dumper(\%main::);

ok eval { \&main::my_multi }, 'my_multi() exists';

is my_multi("a scalar", "and some more"), 'first', 'two-parameter';
is my_multi("just a scalar"), 'second', 'one-parameter';

done_testing;
