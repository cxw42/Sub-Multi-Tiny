use 5.006;
use strict;
use warnings;
use Test::More;

#use Sub::Multi::Tiny::Util '*VERBOSE';
#BEGIN { $VERBOSE = 2; }

diag "Type::Tiny / Types::Standard";
{
    package main::my_multi;
    use Sub::Multi::Tiny qw($foo $bar);
    use Type::Tiny;
    use Types::Standard;

    sub first :M(Str $foo) {
        return "Hello, $foo!";
    }

    sub second :M(Int $foo) {
        return $foo + 42;
    }

}

ok do { no strict 'refs'; defined *{"main::my_multi"}{CODE} }, 'my_multi() exists';

TODO: {
    local $TODO = 'Not yet implemented';
    is my_multi("world"), 'Hello, world!', 'Str multi';
    cmp_ok my_multi(0), '==', 42, 'Int multi';
    cmp_ok my_multi(42), '==', 84, 'Int multi';
}

done_testing;
