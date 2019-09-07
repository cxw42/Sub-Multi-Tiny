use 5.006;
use strict;
use warnings;

use Sub::Multi::Tiny::SigParse; # DUT

use Data::PowerSet 'powerset';
use Test::Fatal;
use Test::More;

# Reduce typing
sub _p {
    Sub::Multi::Tiny::SigParse::Parse(join ' ', @_)
}

# Line number as a string
sub _l {
    my (undef, undef, $line) = caller;
    return "line $line";
}

# Bit strings

# Note: for debugging:
#use Data::Dumper;
#diag 'AST: ' . join '', unpack('H*', $ast->{seen});
#diag 'Expected: ' . join '', unpack('H*', $WTP);

my %B;  # To hold all the bit strings in convenient form
{
    my $powerset = powerset(qw(NAMED POS TYPE WHERE));  # alphabetical order
    foreach my $p (@$powerset) {
        my $key = join '', map { substr $_, 0, 1 } @$p;
        $B{$key} = '';
        vec($B{$key}, eval("Sub::Multi::Tiny::SigParse::SEEN_$_"), 1) = 1
            foreach @$p;
    }
}

# Some success cases - positional parameters
my $ast;

$ast = _p '$foo';
is_deeply $ast, {parms=>[{name=>'$foo'}], seen=>$B{P}}, _l;

$ast = _p 'Int $foo';
is_deeply $ast, {parms=>[{type=>'Int', name=>'$foo'}], seen=>$B{PT}}, _l;

$ast = _p '$foo where { $_ > 0 }';
is_deeply $ast, {parms=>[{name=>'$foo', where=>'{ $_ > 0 }'}], seen=>$B{PW}}, _l;

$ast = _p 'Int $foo where { $_ > 0 }';
is_deeply $ast,
    {parms=>[{type=>'Int', name=>'$foo', where=>'{ $_ > 0 }'}], seen=>$B{PTW}},
    _l;

$ast = _p "  \n\t" . 'Int $foo where { $_ > 0 }' . "\t\t\t";
is_deeply $ast, {parms=>[{type=>'Int', name=>'$foo', where=>'{ $_ > 0 }'}], seen=>$B{PTW}}, _l;

# Some success cases - named parameters
$ast = _p ':$foo';
is_deeply $ast, {parms=>[{name=>'$foo', named=>1}], seen=>$B{N}}, _l;

$ast = _p 'Int :$foo';
is_deeply $ast, {parms=>[{type=>'Int', name=>'$foo', named=>1}], seen=>$B{NT}}, _l;

$ast = _p ':$foo where { $_ > 0 }';
is_deeply $ast, {parms=>[{name=>'$foo', where=>'{ $_ > 0 }', named=>1}], seen=>$B{NW}}, _l;

$ast = _p 'Int :$foo where { $_ > 0 }';
is_deeply $ast,
    {parms=>[{type=>'Int', name=>'$foo', where=>'{ $_ > 0 }', named=>1}], seen=>$B{NTW}},
    _l;

$ast = _p "  \n\t" . 'Int :$foo where { $_ > 0 }' . "\t\t\t";
is_deeply $ast, {parms=>[{type=>'Int', name=>'$foo', where=>'{ $_ > 0 }', named=>1}], seen=>$B{NTW}}, _l;

# Success with both
$ast = _p "  \n\t" . 'String $bar, Int :$foo where { $_ > 0 }' . "\t\t\t";
is_deeply $ast, {parms=>[{type=>'String', name=>'$bar'}, {type=>'Int', name=>'$foo', where=>'{ $_ > 0 }', named=>1}], seen=>$B{NPTW}}, _l;

# Some failure cases
like exception { _p '   {x} $foo,  @abar  , 42[bar] %something {long one}' },
    qr/could not understand TYPE/ , _l;

like exception { _p ' {x}' }, qr/end of input/, _l;

done_testing;
