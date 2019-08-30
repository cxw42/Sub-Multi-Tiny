requires 'perl', '5.010001';

requires 'attributes';
requires 'Carp';
requires 'Guard', '1.023';
requires 'Import::Into', '1.002005';
requires 'strict';
requires 'subs';
requires 'vars';
requires 'warnings';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::UseAllModules', '0.15';
};

