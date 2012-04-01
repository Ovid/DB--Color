package DB::Color;

use 5.008;
use strict;
use warnings;
use DB::Color::Highlight;
use DB::Color::Config;

use IO::Handle;
use File::Spec::Functions qw(catfile catdir);
use Scalar::Util 'dualvar';
use File::Find;

=head1 NAME

DB::Color - Colorize your debugger output

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

Put the following in your F<$HOME/.perldb> file:

 use DB::Color;

Then use your debugger like normal:

 perl -d some_file.pl

If you don't want a F<$HOME/.perldb> file, you can do this:

 perl -MDB::Color -e some_file.pl

=head1 DISABLING COLOR

If the NO_DB_COLOR environment variable is set to a true value, syntax
highlighting will be disabled.

=head1 WINDOWS

No, sorry. It's a combination of bad Windows support for ANSI escape sequences
and bad debugger design.

=head1 PERFORMANCE

When using the debugger and when you step into something, or continue to a
breakpoint in a new file, the debugger may appear to hang for a moment
(perhaps a long moment if the file is big) while the file is syntax
highlighted and cached. The next time the debugger enters this file, the
highlighting should be instantaneous.

You can speed up the debugger by using the L<perldbsyntax> program which is
included in this distribution. It will pregenerate syntax files for you.

Syntax highlighting the code is very slow. As a result, we cache the output
files in F<$HOME/.perldbcolor>. This is done by calculating the md5 sum of the
file contents. If the file is changed, we get a new sum. This means that
syntax highlighting is very slow at first, but every time you hit the same
file, assuming its unchanged, the cached version is served first.

Note that the cache files are removed after they become 30 (but see config)
days old without being used. If you use the debugger regularly, commonly
debugged files will load very quickly (assuming they haven't changed).

=head1 CONFIGURATION

You can optionally configure C<DB::Color> by creating a
F<$HOME/.perldbcolorrc> configuration file. It looks like this:

 [core]
 
 # the class that will highlight the code
 highlighter = DB::Color::Highlight
 
 # Any cache file not accessed after this number of days is purged
 cache_max_age = 30
 
 # where to put the cache dir
 cache_dir   = /users/ovid/.perldbcolor
 
The above values are more or less the defaults for this module. They are all
optional.

=head1 ALPHA

This is only a proof of concept. In fact, it's fair to say that this code
sucks. It's not very configurable and has bugs. It's also going to possibly be
a memory hog, as if the debugger wasn't bad enough already.

=cut

my $config = DB::Color::Config->read( default_rcfile() );

my %COLORED;
my $DB_BASE_DIR = $config->{core}{cache_dir} || default_base_dir();

my $DB_LOG = catfile( $DB_BASE_DIR, 'debug.log' );
my $CACHE_MAX_AGE = $config->{core}{cache_max_age} || 30;
my $DEBUG;

# Not documenting this because I don't guarantee stability, but you can play
# with it if you want.
if ( $ENV{DB_COLOR_DEBUG} ) {
    open $DEBUG, '>>', $DB_LOG
      or die "Cannot open $DB_LOG for appending: $!";
    $DEBUG->autoflush(1);
}

my $HIGHLIGHTER_CLASS = $config->{core}{highlighter} || 'DB::Color::Highlight';
eval "use $HIGHLIGHTER_CLASS";
die $@ if $@;

my $HIGHLIGHTER = $HIGHLIGHTER_CLASS->new(
    {
        cache_dir => $DB_BASE_DIR,
        debug_fh  => $DEBUG,
    }
);

sub DB::afterinit {
    no warnings 'once';
    push @DB::typeahead => "{{v"
      unless $DB::already_curly_curly_v++;
}

sub default_rcfile { catfile( $ENV{HOME}, '.perldbcolorrc' ) }
sub default_base_dir { catfile( $ENV{HOME}, '.perldbcolor' ) }

sub import {
    return if $ENV{NO_DB_COLOR};
    if ( 'MSWin32' eq $^O ) {
        warn <<"END";
DB::Color does not run under Windows because the Windows terminal is too
broken to understand terminal color code.

DB::Color does not use Win32::Console because the debugger is too broken to be
properly extensible.
END
        return;
    }
    my $old_db = \&DB::DB;

    my $new_DB = sub {
        my $lvl = 0;
        while ( my ($pkg) = caller( $lvl++ ) ) {
            return if $pkg eq "DB" or $pkg =~ /^DB::/;
        }
        my ( $package, $filename ) = caller;
        if ($DEBUG) {
            print $DEBUG "In package '$package', filename '$filename'\n";
        }

        # syntax highlight everything and cache it
        my $lines = $COLORED{$package}{$filename} ||= do {
            no strict 'refs';
            no warnings 'uninitialized';
            [
                split /(?<=\n)/ =>
                  $HIGHLIGHTER->highlight_text( join "" => @{"::_<$filename"} )
            ];
        };

        {

            # lie to the debugger about what the lines of code are
            no strict 'refs';
            my $line_num = 0;
            foreach ( @{"::_<$filename"} ) {

                # uncomment these to blow your f'in mind
                #if ( not defined ) {
                #    use Devel::Peek;
                #    warn "line number is $line_num";
                #    Dump($_);
                #}
                # The debugger special cases the first value in ::_<$filename.
                # It's "undef" but sometimes contains some data about the
                # program. I don't know entirely what it is, but this solves
                # the "off by one" bug.
                next unless defined;    # thanks Liz! (why does this work?)
                my $line = $lines->[ $line_num++ ];
                next unless defined $line;    # happens when $_ = "\n"
                my $numeric_value = 0 + $_;

                # Internally, the debugger uses dualvars for each line of
                # code. If it's numeric value is 0, then the line is not
                # breakable. If we don't include this, no lines in the
                # debugger are breakable.
                $_ = dualvar $numeric_value, $line;
            }
        }
        goto $old_db;
    };

    {
        no warnings 'redefine';
        *DB::DB = $new_DB;
    }

    return;
}

END {
    find(
        sub {

            # delete empty files or files > $CACHE_MAX_AGE days old
            if ( -f $_ && ( -z _ || -M _ > $CACHE_MAX_AGE ) ) {
                unlink($_) or die "Could not unlink '$File::Find::name': $!";
            }
        },
        $DB_BASE_DIR,
    );
    # we're not testing for failure as this is a cheap hack to delete empty
    # directories
    finddepth( sub { rmdir $_ if -d }, $DB_BASE_DIR );
}

1;

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-db-color at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DB-Color>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DB::Color

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DB-Color>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DB-Color>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DB-Color>

=item * Search CPAN

L<http://search.cpan.org/dist/DB-Color/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Nick Perez, Liz, and the 2012 Perl Hackathon for helping to overcome
some major hurdles with this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of DB::Color
