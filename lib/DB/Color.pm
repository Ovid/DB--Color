package DB::Color;

use 5.008;
use strict;
use warnings;
use DB::Color::Highlight;

=head1 NAME

DB::Color - Colorize your debugger output

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

Put the following in your $HOME/.perldb file:

 sub afterinit {
     push @DB::typeahead, "{{v"
       unless $DB::already_curly_curly_v++;
 }
 use DB::Color;

Then use your debugger like normal:

 perl -d some_file.pl

=head1 ALPHA

This is only a proof of concept. In fact, it's fair to say that this code
sucks. It's not very configurable and has bugs. It's also going to possibly be
a memory hog, as if the debugger wasn't bad enough already.

=cut

my $HIGHLIGHTER = DB::Color::Highlight::highlighter();
my %COLORED;

sub import {
    my $old_db = \&DB::DB;

    my $new_DB = sub {
        my $lvl = 0;
        while ( my ($pkg) = caller( $lvl++ ) ) {
            return if $pkg eq "DB" or $pkg =~ /^DB::/;
        }
        my ( $package, $filename ) = caller;

        # syntax highlight everything and cache it
        my $lines = $COLORED{$package}{$filename} ||= do {
            no strict 'refs';

            # quick hack
            no warnings 'uninitialized';
            my $code = join "" => @{"::_<$filename"};
            [
                map { "$_\n" }
                  split /\n/ => $HIGHLIGHTER->highlightText($code)
            ];
        };

        # lie to the debugger about what the lines of code are
        {
            no strict 'refs';
            @{"::_<$filename"} = @$lines;
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
