#!/usr/bin/env perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::UseAllModules;

BEGIN { all_uses_ok; }

diag( "Testing Sub::Multi::Tiny $Sub::Multi::Tiny::VERSION, Perl $], $^X" );

done_testing;
