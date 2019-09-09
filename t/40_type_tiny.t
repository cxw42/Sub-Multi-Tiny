use 5.006;
use strict;
use warnings;
use Test::More;

#use Sub::Multi::Tiny::Util '*VERBOSE';
#BEGIN { $VERBOSE = 2; }

diag "Type::Tiny / Types::Standard";

#---------------------------------------------------------------
# Type constraints

{
    package main::my_multi;
    use Sub::Multi::Tiny qw(D:TypeParams $foo);
        # D:TypeParams -> use that dispatcher, which pulls in Type::Tiny
    use Types::Standard qw(Str Int);

    sub second :M(Int $foo) {
        return $foo + 42;
    }

    sub first :M(Str $foo) {
        return "Hello, $foo!";
    }

}

ok do { no strict 'refs'; defined *{"main::my_multi"}{CODE} }, 'my_multi() exists';

is my_multi("world"), 'Hello, world!', 'Str multi';
cmp_ok my_multi(0), '==', 42, 'Int multi';
cmp_ok my_multi(42), '==', 84, 'Int multi';

#---------------------------------------------------------------
# Where clauses

{
    package main::check_int;
    use Sub::Multi::Tiny qw(D:TypeParams $num);
    use Types::Standard qw(Str Int);

    sub small :M($num where { $_ < 10}) {
        return $num * 2;
    }

    sub large :M($num where { $_ >= 10}) {
        return "Howdy, $num!";
    }

}

ok do { no strict 'refs'; defined *{"main::check_int"}{CODE} }, 'check_int() exists';

cmp_ok check_int($_), '==', ($_ * 2), "small $_" foreach -10..9;
is check_int($_), "Howdy, $_!", "large $_" foreach 10..15;

done_testing;
