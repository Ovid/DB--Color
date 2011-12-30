#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DB::Color' ) || print "Bail out!\n";
}

diag( "Testing DB::Color $DB::Color::VERSION, Perl $], $^X" );
