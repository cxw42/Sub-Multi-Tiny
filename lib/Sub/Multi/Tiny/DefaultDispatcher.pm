package Sub::Multi::Tiny::DefaultDispatcher;

use 5.010001;
use strict;
use warnings;

#use Data::Dumper;   # DEBUG

use Guard;
use Sub::Multi::Tiny::Util qw(_hlog _line_mark_string);

our $VERSION = '0.000002'; # TRIAL

# Documentation {{{1

=head1 NAME

Sub::Multi::Tiny::DefaultDispatcher - Default dispatcher-maker for Sub::Multi::Tiny

=head1 SYNOPSIS

    require Sub::Multi::Tiny::DefaultDispatcher;
    my $dispatcher_coderef =
        Sub::Multi::Tiny::DefaultDispatcher::MakeDispatcher({impls=>[]...});

See L<Sub::Multi::Tiny> for more.  This module does not export any symbols
(or even have the capability to do so!).

=head1 FUNCTIONS

=cut

# }}}1

=head2 MakeDispatcher

Make the default dispatcher for the given multi.  See L</SYNOPSIS>.

TODO expand.  For now, only dispatches based on arity.

=cut

sub MakeDispatcher {
    my $hr = shift; # Has possible_params and impls arrayrefs
    my $code = '';
    _hlog { require Data::Dumper;
            "Making default dispatcher for: ", Data::Dumper->Dump([$hr], ['multisub']) };

    # Sort the candidates
    my %candidates_by_arity;
    foreach(@{$hr->{impls}}) {
        my $arity = @{$_->{args}};
        die "I can't yet distinguish between candidates of the same arity"
            if exists $candidates_by_arity{$arity};
        $candidates_by_arity{$arity} = $_->{code};
    }

    # Make the dispatcher
    $code .= _line_mark_string <<EOT;
        sub {
            # Find the candidate
            my \$candidate = \$candidates_by_arity{scalar \@_};
            die "No candidate found for $hr->{defined_in}\() with arity " .
                (scalar \@_) unless \$candidate;

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

            \@_ = (\$guard);    # Pass the guard so the parameters will be
                                # reset once \$candidate finishes running.
            # Invoke the selected candidate
            goto &\$candidate;
        }
EOT

    _hlog { "Dispatcher:\n$code\n" } 2;
    return eval $code;
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
