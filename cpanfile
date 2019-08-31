requires 'perl', '5.010001';

requires 'attributes';
requires 'Carp';
requires 'Guard', '1.023';
requires 'Import::Into', '1.002005';
requires 'Text::Balanced', '2.01';
requires 'strict';
requires 'subs';
requires 'vars';
requires 'warnings';

on 'build' => sub {
    requires 'Parse::Yapp';
};

on 'test' => sub {
    requires 'Test::Fatal', '0.014';
    requires 'Test::More', '0.98';
};

# vi: set ft=perl: #
