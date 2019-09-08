package Sub::Multi::Tiny::Dispatcher::TypeParams;

use 5.006;
use strict;
use warnings;

#use Data::Dumper;   # DEBUG

use Guard;
use Sub::Multi::Tiny::Util qw(_hlog _line_mark_string);
use Type::Params qw(multisig);

our $VERSION = '0.000005'; # TRIAL

# Documentation {{{1

=head1 NAME

Sub::Multi::Tiny::Dispatcher::TypeParams - Dispatcher-maker using Type::Params for Sub::Multi::Tiny

=head1 SYNOPSIS

    # In a multisub
    require Sub::Multi::Tiny qw($param D:TypeParams);   # in a multisub

    # Internals of Sub::Multi::Tiny
    use Type::Params;
    my $dispatcher_coderef =
        Sub::Multi::Tiny::Dispatcher::TypeParams::MakeDispatcher({impls=>[]...});

This module dispatches to any function that can be distinguished
by the C<multisig> function in L<Type::Params>.
See L<Type::Params/MULTIPLE SIGNATURES>.

See L<Sub::Multi::Tiny> for more about the usage of this module.
This module does not export any symbols.

=head1 FUNCTIONS

=cut

# }}}1

# Make a sub to copy from @_ into package variables.
sub _make_copier {
    my ($defined_in, $impl) = @_;
    _hlog { require Data::Dumper;
        Data::Dumper->Dump([\@_],['_make_copier']) } 2;

    my $code = _line_mark_string <<'EOT';
sub {
    (
EOT

    $code .=
        join ",\n",
            map {
                my ($sigil, $name) = $_->{name} =~ m/^(.)(.+)$/;
                _line_mark_string
                    "        ${sigil}$defined_in\::${name}"
            } #foreach arg
                @{$impl->{args}};

    $code .= _line_mark_string <<'EOT';
    ) = @_;
} #copier
EOT

    _hlog { "Copier for $impl->{candidate_name}\():\n", $code } 2;
    return eval $code;
} #_make_copier

=head2 MakeDispatcher

Make the default dispatcher for the given multi.  See L</SYNOPSIS>.

TODO RESUME HERE.

=cut

sub MakeDispatcher {
    my $hr = shift; # Has possible_params and impls arrayrefs
    my $code = '';
    _hlog { require Data::Dumper;
            "Making Type::Params dispatcher for: ",
                Data::Dumper->Dump([$hr], ['multisub']) };

    # TODO make a typecheck arrayref for multisig()
=for comment

    # Sort the candidates
    my (%candidates_by_arity, %copiers_by_arity);   # TODO make this cleaner
    foreach my $impl (@{$hr->{impls}}) {
        my $arity = @{$impl->{args}};
        die "I can't yet distinguish between candidates of the same arity"
            if exists $candidates_by_arity{$arity};
        $candidates_by_arity{$arity} = $impl->{code};
        $copiers_by_arity{$arity} =
            _make_copier($hr->{defined_in}, $impl);
    }

    # Make the dispatcher
    $code .= _line_mark_string <<EOT;
        sub {
            # Find the candidate
            my \$arity = scalar \@_;
            my \$candidate = \$candidates_by_arity{\$arity};
            die "No candidate found for $hr->{defined_in}\() with arity " .
                (scalar \@_) unless \$candidate;
            my \$copier = \$copiers_by_arity{\$arity};

            # Save the present values of the parameters
EOT

    my $restore = '';
    foreach(keys %{$hr->{possible_params}}) {
        my ($sigil, $name) = /^(.)(.+)$/;
        $code .= _line_mark_string
            "my ${sigil}saved_${name} = ${sigil}$hr->{defined_in}\::${name};\n";
        $restore .= _line_mark_string
            "${sigil}$hr->{defined_in}\::${name} = ${sigil}saved_${name};\n";
    }

    $code .= _line_mark_string <<EOT;
            # Create the guard
            my \$guard = Guard::guard {
$restore
            }; #End of guard
EOT

    $code .= _line_mark_string <<'EOT';

            # Copy the parameters into the variables the candidate
            # will access them from
            &$copier;   # $copier gets @_ automatically

            # Pass the guard so the parameters will be reset once \$candidate
            # finishes running.
            @_ = ($guard);

            # Invoke the selected candidate
            goto &$candidate;
        } #dispatcher
EOT

    _hlog { "\nDispatcher for $hr->{defined_in}\():\n$code\n" } 2;
    return eval $code;

=cut

    die 'Unimplemented';
} #MakeDispatcher

1;
__END__

# Rest of documentation {{{1

=head1 AUTHOR

Chris White E<lt>cxw@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) 2019 Chris White E<lt>cxw@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# }}}1
# vi: set fdm=marker: #
