package Sub::Multi::Tiny::Util;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT;
BEGIN { @EXPORT = qw(_croak _carp _line_mark_string) }

# Documentation {{{1

=head1 NAME

Sub::Multi::Tiny::Util - Internal utilities for Sub::Multi::Tiny

=head1 SYNOPSIS

No user-serviceable parts inside.  See L<Sub::Multi::Tiny>.

=head1 FUNCTIONS

=cut

# }}}1

=head2 _croak

As L<Carp/croak>, but lazily loads L<Carp>.

=cut

sub _croak {
    require Carp;
    goto &Carp::croak;
}

=head2 _carp

As L<Carp/carp>, but lazily loads L<Carp>.

=cut

sub _carp {
    require Carp;
    goto &Carp::carp;
}

=head2 _line_mark_string

Add a C<#line> directive to a string.  Usage:

    my $str = _line_mark_string <<EOT ;
    $contents
    EOT

or

    my $str = _line_mark_string __FILE__, __LINE__, <<EOT ;
    $contents
    EOT

In the first form, information from C<caller> will be used for the filename
and line number.

The C<#line> directive will point to the line after the C<_line_mark_string>
invocation, i.e., the first line of <C$contents>.  Generally, C<$contents> will
be source code, although this is not required.

C<$contents> must be defined, but can be empty.

=cut

sub _line_mark_string {
    my ($contents, $filename, $line);
    if(@_ == 1) {
        $contents = $_[0];
        (undef, $filename, $line) = caller;
    } elsif(@_ == 3) {
        ($filename, $line, $contents) = @_;
    } else {
        _croak "Invalid invocation";
    }

    _croak "Need text" unless defined $contents;
    die "Couldn't get location information" unless $filename && $line;

    $filename =~ s/"/-/g;
    ++$line;

    return <<EOT;
#line $line "$filename"
$contents
EOT
} #_line_mark_string()

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
