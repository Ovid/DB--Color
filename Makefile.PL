use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name 'DB-Color';
all_from 'lib/DB/Color.pm';
author q{Curtis "Ovid" Poe <ovid@cpan.org>};
license 'artistic2';

perl_version 5.006;

tests_recursive('t');

resources(
    homepage   => 'https://github.com/Ovid/DB--Color',
    license    => 'http://www.perlfoundation.org/artistic_license_2_0',
    repository => 'https://github.com/Ovid/DB--Color',
    bugtracker => 'https://github.com/Ovid/DB--Color/issues',
);

configure_requires(
    'Module::Install' => 0,
);

build_requires(
    'Test::More' => '0',
);

requires(
    'Syntax::Highlight::Engine::Kate' => 0.06,
    'Digest::MD5'                     => 0,
    'Term::ANSIColor' => 0,        # 3.0 or better to get bright colors
    'File::Path'      => '2.07',
);

install_as_cpan;
auto_install;
WriteAll;
