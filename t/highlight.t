#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use DB::Color::Highlight;
use File::Temp qw(tempfile tempdir);

my ( $fh, $file ) = tempfile();
my $dir = tempdir( CLEANUP => 1 );

ok my $highlight = DB::Color::Highlight->new(
    {
        cache_dir => $dir,
        debug_fh  => $fh,
    }
  ),
  'We should be able to create a new DB::Color::Highlight object';
isa_ok $highlight, 'DB::Color::Highlight', '... and the object it returns';

my $test_more_file = $INC{'Test/More.pm'};
open my $test_fh, '<', $test_more_file
  or die "Cannot open '$test_more_file' for reading: $!";

my $test_more_code = do { local $/; <$test_fh> };
close $test_fh;

can_ok $highlight, '_get_path_and_file';
my ( $md5_path, $md5_file ) = $highlight->_get_path_and_file($test_more_code);
ok $md5_path, '... and it should return a path';
ok $md5_file, '... and it should return a md5_filename';

my ( $md5_path1, $md5_file1 ) = $highlight->_get_path_and_file($test_more_code);
is $md5_path1, $md5_path, 'Calling it more than once should return the same path';
is $md5_file1, $md5_file, '... and the same md5_file';

can_ok $highlight, '_get_highlighted_text';
ok my $highlighted =  $highlight->_get_highlighted_text($test_more_code),
    '... and calling it should highlight our text (*cough*)';
my @old_lines = split /\n/ => $test_more_code;
my @new_lines = split /\n/ => $highlighted;

is @old_lines, @new_lines, '... and the number of lines of code should be the same';

done_testing;
