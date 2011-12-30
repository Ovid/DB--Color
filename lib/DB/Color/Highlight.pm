package DB::Color::Highlight;

use strict;
use warnings;
use Term::ANSIColor;

use Syntax::Highlight::Engine::Kate::Perl;

sub highlighter {
    # Yeah, this sucks. Hard. Fix it!
    return Syntax::Highlight::Engine::Kate::Perl->new(
        format_table => {
            Alert        => [ color('bold white'), color('reset') ],
            BaseN        => [ color('bold white'), color('reset') ],
            BString      => [ color('bold white'), color('reset') ],
            Char         => [ color('bold white'), color('reset') ],
            Comment      => [ color('bold blue'), color('reset') ],
            DataType     => [ color('yellow'), color('reset') ], # variable names
            DecVal       => [ color('bold white'), color('reset') ],
            Error        => [ color('bold white'), color('reset') ],
            Float        => [ color('bold white'), color('reset') ],
            Function     => [ color('bold white'), color('reset') ],
            IString      => [ color('bold white'), color('reset') ],
            Keyword      => [ color('cyan'), color('reset') ],
            Normal       => [ color('bold white'), color('reset') ],
            Operator     => [ color('bold white'), color('reset') ],
            Others       => [ color('bold white'), color('reset') ],
            RegionMarker => [ color('bold white'), color('reset') ],
            Reserved     => [ color('bold white'), color('reset') ],
            String       => [ color('bold blue'),  color('reset') ],
            Variable     => [ color('red'),        color('reset') ],
            Warning      => [ color('bold white'), color('reset') ],
        },
    );
}

1;
