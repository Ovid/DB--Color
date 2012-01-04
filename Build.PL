use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name          => 'DB::Color',
    license              => 'perl',
    dist_author          => q{Curtis 'Ovid' Poe <ovid@cpan.org>},
    dist_version_from    => 'lib/DB/Color.pm',
    build_requires       => { 'Test::More' => 0, },
    requires             => { 'Syntax::Highlight::Engine::Kate' => 0.06, },
    add_to_cleanup       => ['DB-Color-*'],
    create_makefile_pl   => 'traditional',
    recursive_test_files => 1,
    meta_merge =>
      { resources => { repository => 'https://github.com/Ovid/DB--Color' } },
);

$builder->create_build_script();
