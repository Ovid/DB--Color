use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'DB::Color',
    AUTHOR        => q{Curtis "Ovid" Poe <ovid@cpan.org>},
    VERSION_FROM  => 'lib/DB/Color.pm',
    ABSTRACT_FROM => 'lib/DB/Color.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'                      => 0,
        'Syntax::Highlight::Engine::Kate' => 0.06,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'DB-Color-*' },
);
