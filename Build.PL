use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'DB::Color',
    license           => 'perl',
    dist_author       => q{Curtis 'Ovid' Poe <ovid@cpan.org>},
    dist_version_from => 'lib/DB/Color.pm',
    build_requires    => { 'Test::More' => 0, },
    requires          => {
        'Syntax::Highlight::Engine::Kate' => 0.06,
        'Digest::MD5'                     => 0,
        'Term::ANSIColor' => 0,        # 3.0 or better to get bright colors
        'File::Path'      => '2.07',
    },
    configure_requires => { 'Module::Build' => '0.4' },
    add_to_cleanup       => ['DB-Color-*'],
    create_makefile_pl   => 'traditional',
    recursive_test_files => 1,
    script_files         => 'script',
    meta_merge =>
      { resources => { repository => 'https://github.com/Ovid/DB--Color' } },
);

$builder->create_build_script();
