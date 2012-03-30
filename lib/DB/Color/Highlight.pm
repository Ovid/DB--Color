package DB::Color::Highlight;

use strict;
use warnings;
use Term::ANSIColor ':constants';

use Syntax::Highlight::Engine::Kate::Perl;

=head1 NAME

DB::Color::Highlight - Provides highlighting for DB::Color

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

BEGIN {
    no warnings 'redefine';
    *Syntax::Highlight::Engine::Kate::Template::logwarning = sub { };
}

sub new {
    my $class = shift;
    my $self = bless {} => $class;
    $self->_initialize;
    return $self;
}

sub _initialize {
    my $self = shift;

    my $highlighter = Syntax::Highlight::Engine::Kate::Perl->new(
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
    $self->{highlighter} = $highlighter;
}

sub _highlighter { $_[0]->{highlighter} }

sub highlight_text {
    my ( $self, $code ) = @_;
    return $self->_highlighter->highlightText($code);
}

1;
__END__

=head1 SYNOPSIS

 use DB::Color::Highlight;
 my $highlighter = DB::Color::Highlight::highlighter();
 my $highlighted = $highlighter->highlightText($code);

=head1 INTERNAL USE ONLY

Don't touch this. It's subject to change at any time.

=head1 EXPORT

Nothing.

=head1 SUBROUTINES

=head2 C<highlighter>

Returns a L<Syntax::Highlight::Engine::Kate::Perl> object.

=cut
