package DB::Color;

use 5.008;
use strict;
use warnings;
use DB::Color::Highlight;
use IO::Handle;
use File::Spec::Functions qw(catfile catdir);
use Scalar::Util 'dualvar';

=head1 NAME

DB::Color - Colorize your debugger output

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

Put the following in your $HOME/.perldb file:

 sub afterinit {
     push @DB::typeahead, "{{v"
       unless $DB::already_curly_curly_v++;
 }
 use DB::Color;

Then use your debugger like normal:

 perl -d some_file.pl

=head1 DISABLING COLOR

If the NO_DB_COLOR environment variable is set to a true value, syntax
highlighting will be disabled.

=head1 PERFORMANCE

Syntax highlighting the code is very, very slow. As a result, we cache the
output files in F<$HOME/.perldbcolor>. This is done by calculating the md5 sum
of the file contents. If the file is changed, we get a new sum. This means
that syntax highlighting is very slow at first, but every time you hit the
same file, assuming its unchnanged, the cached version is served first.

Note that the cache files are never removed. This has merely been a naive hack
for a proof of concept. Patches welcome.

=head1 ALPHA

This is only a proof of concept. In fact, it's fair to say that this code
sucks. It's not very configurable and has bugs. It's also going to possibly be
a memory hog, as if the debugger wasn't bad enough already.

=cut

my %COLORED;
my $DB_BASE_DIR = catdir( $ENV{HOME}, '.perldbcolor' );
my $DB_LOG = catfile( $DB_BASE_DIR, 'debug.log' );
my $DEBUG;
if ( $ENV{DB_COLOR_DEBUG} || 1 ) {
    open $DEBUG, '>>', $DB_LOG
        or die "Cannot open $DB_LOG for appending: $!";
    $DEBUG->autoflush(1);
}
my $HIGHLIGHTER = DB::Color::Highlight->new(
    {
        cache_dir => $DB_BASE_DIR,
        debug_fh  => $DEBUG,
    }
);

sub import {
    return if $ENV{NO_DB_COLOR};
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

            # quick hack
            no warnings 'uninitialized';
            my $code = join "" => @{"::_<$filename"};
            [
                  split /(?<=\n)/ => $HIGHLIGHTER->highlight_text($code)
            ];
        };

        {
            # lie to the debugger about what the lines of code are
            no strict 'refs';
            my $line_num = 0;
            foreach ( @{"::_<$filename"} ) {
                next unless defined;   # thanks Liz! (why does this work?)
                my $line = $lines->[$line_num++];
                my $numeric_value = 0+$_;
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

1;

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-db-color at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DB-Color>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




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


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of DB::Color
