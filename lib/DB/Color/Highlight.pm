package DB::Color::Highlight;

use strict;
use warnings;
use Term::ANSIColor ':constants';
use Digest::MD5 'md5_base64';
use File::Spec::Functions qw(catfile catdir);
use File::Path 'make_path';

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
    my ( $class, $args ) = @_;
    my $self = bless {} => $class;
    $self->_initialize($args);
    return $self;
}

sub _initialize {
    my ( $self, $args ) = @_;

    my $cache_dir = $args->{cache_dir};
    $self->{cache_dir} = $cache_dir;
    unless ( -d $cache_dir ) {
        mkdir $cache_dir or die "Cannot mkdir ($cache_dir): $!";
    }

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
sub _cache_dir   { $_[0]->{cache_dir} }

sub highlight_text {
    my ( $self, $code ) = @_;
    my ( $path, $file ) = $self->_get_path_and_file($code);

    unless ( -d $path ) {
        make_path($path);
    }
    $file = catfile( $path, $file );

    if ( -e $file ) {
        open my $fh, '<', $file or die "Cannot open '$file' for reading: $!";
        return do { local $/; <$fh> };
    }
    else {
        my $highlighted = $self->_highlighter->highlightText($code);
        open my $fh, '>', $file or die "Cannot open '$file' for writing: $!";
        print $fh $highlighted;
        return $highlighted;
    }
}

sub _get_path_and_file {
    my ( $self, $code ) = @_;
    my $md5_base64 = md5_base64($code);
    my $dir        = substr $md5_base64, 0, 2, '';
    my $file       = $md5_base64;
    return catdir( $self->_cache_dir, $dir ), $file;
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
