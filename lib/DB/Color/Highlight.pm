package DB::Color::Highlight;

use strict;
use warnings;
use Term::ANSIColor ':constants';
use Digest::MD5 'md5_hex';
use File::Spec::Functions qw(catfile catdir);
use File::Path 'make_path';

use Syntax::Highlight::Engine::Kate::Perl;

=head1 NAME

DB::Color::Highlight - Provides highlighting for DB::Color

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

# increase this number by one to force the cache to generate new md5 numbers
my $FORMAT_NUMBER = 1;

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
    $self->{debug_fh}  = $args->{debug_fh};
    $self->{cache_dir} = $cache_dir;

    if ( defined $cache_dir and not -d $cache_dir ) {
        mkdir $cache_dir or die "Cannot mkdir ($cache_dir): $!";
    }

#      CLEAR           RESET             BOLD            DARK
#      FAINT           ITALIC            UNDERLINE       UNDERSCORE
#      BLINK           REVERSE           CONCEALED
#
#      BLACK           RED               GREEN           YELLOW
#      BLUE            MAGENTA           CYAN            WHITE
#      BRIGHT_BLACK    BRIGHT_RED        BRIGHT_GREEN    BRIGHT_YELLOW
#      BRIGHT_BLUE     BRIGHT_MAGENTA    BRIGHT_CYAN     BRIGHT_WHITE
#
#      ON_BLACK        ON_RED            ON_GREEN        ON_YELLOW
#      ON_BLUE         ON_MAGENTA        ON_CYAN         ON_WHITE
#      ON_BRIGHT_BLACK ON_BRIGHT_RED     ON_BRIGHT_GREEN ON_BRIGHT_YELLOW
#      ON_BRIGHT_BLUE  ON_BRIGHT_MAGENTA ON_BRIGHT_CYAN  ON_BRIGHT_WHITE

    my $highlighter = Syntax::Highlight::Engine::Kate::Perl->new(
        format_table => {
            'Keyword'      => [ YELLOW,      RESET ],
            'Comment'      => [ BRIGHT_BLUE, RESET ],
            'Decimal'      => [ YELLOW,      RESET ],
            'Float'        => [ YELLOW,      RESET ],
            'Function'     => [ CYAN,        RESET ],
            'Identifier'   => [ RED,         RESET ],
            'Normal'       => [ WHITE,       RESET ],
            'Operator'     => [ CYAN,        RESET ],
            'Preprocessor' => [ RED,         RESET ],
            'String'       => [ MAGENTA,     RESET ],
            'String Char'  => [ RED,         RESET ],
            'Symbol'       => [ CYAN,        RESET ],
            'DataType'     => [ CYAN,        RESET ],    # variable names
        }
    );
    $self->{highlighter} = $highlighter;
}

sub _highlighter  { $_[0]->{highlighter} }
sub _cache_dir    { $_[0]->{cache_dir} }
sub _should_cache { defined $_[0]->_cache_dir }

sub _debug {
    my ( $self, $message ) = @_;
    return unless my $debug = $self->{debug_fh};
    print $debug "$message\n";
}

sub highlight_text {
    my ( $self, $code ) = @_;

    if ( $self->_should_cache ) {
        my ( $path, $file ) = $self->_get_path_and_file($code);
        unless ( -d $path ) {
            make_path($path);
        }
        $file = catfile( $path, $file );

        if ( -e $file ) {
            $self->_debug("Cache hit on '$file'");

            # update the atime, mtime to ensure that our naive cache recognizes
            # this as a "recent" file
            utime time, time, $file or die "Cannot 'utime atime, mtime $file: $!";
            open my $fh, '<', $file or die "Cannot open '$file' for reading: $!";
            return do { local $/; <$fh> };
        }
        else {
            $self->_debug("Cache miss on '$file'");
            my $highlighted = $self->_get_highlighted_text($code);
            open my $fh, '>', $file or die "Cannot open '$file' for writing: $!";
            print $fh $highlighted;
            return $highlighted;
        }
    }
    else {
        return $self->_get_highlighted_text($code);
    }
}

sub _get_highlighted_text {
    my ( $self, $code ) = @_;

    my @code;
    my $line_num = 0;
    my $in_pod   = 0;
    my %pod_lines;
    my @pod_line_nums;
    foreach ( split /\n/ => $code ) {
        if (/^=(?!cut\b)/) {
            $in_pod = 1;
        }
        if ($in_pod) {
            $pod_lines{$line_num} = $_;
            push @pod_line_nums => $line_num;
            push @code          => '';
        }
        else {
            push @code => $_;
        }
        if (/^=cut\b/) {
            $in_pod = 0;
        }
        $line_num++;
    }
    $code = join "\n" => @code;
    my $highlighted = $self->_highlighter->highlightText($code);
    @code = split /\n/ => $highlighted;
    @code[@pod_line_nums] = @pod_lines{@pod_line_nums};
    return join "\n" => map { BLUE . $_ . RESET } @code;
}

sub _get_path_and_file {
    my ( $self, $code ) = @_;
    unless ( $self->_should_cache ) {
        $self->_debug("Caching disabled");
        return;
    }
    my $md5 = md5_hex( $self->_get_unique_factors, $code );
    my $dir = substr $md5, 0, 2, '';
    my $file = $md5;

    my $path = catdir( $self->_cache_dir, $dir );
    $self->_debug("Cache path is '$path'. Cache file is '$file'");
    return $path, $file;
}

sub _format_number {
    return $FORMAT_NUMBER;
}

sub _get_unique_factors {
    my $self = shift;
    return ( $self->_format_number, ref $self );
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
