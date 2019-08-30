####################################################################
#
#    This file was generated using Parse::Yapp version 1.21.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Sub::Multi::Tiny::SigParse;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 6 "/cygdrive/c/Users/cxw/proj/Sub-Multi-Tiny/support/SigParse.yp"


# Imports {{{1

use 5.010001;
use strict;
use warnings;

# }}}1
# Documentation {{{1

=head1 NAME

Sub::Multi::Tiny::SigParse - Parse::Yapp input to parse signatures in Sub::Multi::Tiny

=head1 SYNOPSIS

Generate the .pm file:

    yapp -m Sub::Multi::Tiny::SigParse -o lib/Sub/Multi/Tiny/SigParse.pm support/SigParse.yp

And then:

    use Sub::Multi::Tiny::SigParse;
    my $ast = Sub::Multi::Tiny::SigParse::Parse($signature);

=head1 FUNCTIONS

=cut

# }}}1



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.21',
                                  yystates =>
[
	{#State 0
		DEFAULT => -1,
		GOTOS => {
			'signature' => 1
		}
	},
	{#State 1
		ACTIONS => {
			'' => 2
		}
	},
	{#State 2
		DEFAULT => 0
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'signature', 0,
sub
#line 54 "/cygdrive/c/Users/cxw/proj/Sub-Multi-Tiny/support/SigParse.yp"
{ +{} }
	]
],
                                  @_);
    bless($self,$class);
}

#line 58 "/cygdrive/c/Users/cxw/proj/Sub-Multi-Tiny/support/SigParse.yp"


#############################################################################
# Footer

# Tokenizer and error-reporting routine for Parse::Yapp {{{1

# The lexer
sub _next_token {
    my $parser = shift;
    my $text = $parser->YYData->{TEXT};
    return ('', undef) unless $text;    # EOF

    ...
} #_next_token()

# Report an error
sub _report_error {
    my $parser = shift;
    my $got = $parser->YYCurtok || '<end of input>';
    my $val='';
    $val = ' (' . $parser->YYCurval . ')' if $parser->YYCurval;
    die 'Syntax error: could not understand ', $got, $val, "\n";
    if(ref($parser->YYExpect) eq 'ARRAY') {
        print 'Expected one of: ', join(',', @{$parser->YYExpect}), "\n";
    }
    return;
} #_report_error()

# }}}1
# Top-level parse function {{{1

=head2 Parse

Parse arguments.  Usage:

    my $ast = Sub::Multi::Tiny::SigParse::Parse($signature);

=cut

sub Parse {
    my $text = shift or
        (require Carp, Carp::croak 'Parse: Need a signature to parse');

    my $parser = __PACKAGE__->new;
    my $hrData = $parser->YYData;

    # Data we use while parsing
    $hrData->{TEXT} = $text;

    my $hrRetval = $parser->YYParse(yylex => \&_next_token,
        yyerror => \&_report_error,
        (@_ ? (yydebug => $_[0]) : ()),
    );

    return $hrRetval;
} #Parse()

# }}}1
# Rest of the docs {{{1

=head1 AUTHOR

Chris White E<lt>cxw@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) 2019 Chris White E<lt>cxw@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# }}}1

# vi: set fdm=marker: #

1;
