package DB::Color::Highlight;

use strict;
use warnings;
use Term::ANSIColor ':constants';

use Syntax::Highlight::Engine::Kate::Perl;

BEGIN {
    no warnings 'redefine';
    *Syntax::Highlight::Engine::Kate::Template::logwarning = sub { };
}

sub highlighter {

    # Yeah, this sucks. Hard. Fix it!
    return Syntax::Highlight::Engine::Kate::Perl->new(
        format_table => {
            'Keyword'      => [ GREEN,   RESET ],
            'Comment'      => [ BLUE,    RESET ],
            'Decimal'      => [ YELLOW,  RESET ],
            'Float'        => [ YELLOW,  RESET ],
            'Function'     => [ CYAN,    RESET ],
            'Identifier'   => [ RED,     RESET ],
            'Normal'       => [ MAGENTA, RESET ],
            'Operator'     => [ CYAN,    RESET ],
            'Preprocessor' => [ RED,     RESET ],
            'String'       => [ RED,     RESET ],
            'String Char'  => [ RED,     RESET ],
            'Symbol'       => [ CYAN,    RESET ],
            'DataType'     => [ YELLOW,  RESET ],    # variable names
        }
    );
}

1;
