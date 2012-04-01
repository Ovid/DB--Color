# NAME

DB::Color - Colorize your debugger output

# VERSION

Version 0.07

# SYNOPSIS

Put the following in your `$HOME/.perldb` file:

    use DB::Color;

Then use your debugger like normal:

    perl -d some_file.pl

If you don't want a `$HOME/.perldb` file, you can do this:

    perl -MDB::Color -e some_file.pl

# DISABLING COLOR

If the NO_DB_COLOR environment variable is set to a true value, syntax
highlighting will be disabled.

# WINDOWS

No, sorry. It's a combination of bad Windows support for ANSI escape sequences
and bad debugger design.

# PERFORMANCE

When using the debugger and when you step into something, or continue to a
breakpoint in a new file, the debugger may appear to hang for a moment
(perhaps a long moment if the file is big) while the file is syntax
highlighted and cached. The next time the debugger enters this file, the
highlighting should be instantaneous.

Syntax highlighting the code is very slow. As a result, we cache the output
files in `$HOME/.perldbcolor`. This is done by calculating the md5 sum of the
file contents. If the file is changed, we get a new sum. This means that
syntax highlighting is very slow at first, but every time you hit the same
file, assuming its unchanged, the cached version is served first.

Note that the cache files are removed after they become 30 (but see config)
days old without being used. This has merely been a naive hack for a proof of
concept. Patches welcome.

# CONFIGURATION

You can configure `DB::Color` by creating a `$HOME/.perldbcolorrc`
configuration file. It looks like this:

    [core]
    

    # the class that will highlight the code
    highlighter = DB::Color::Highlight
    

    # Any cache file not accessed after this number of days is purged
    cache_max_age = 30
    

    # where to put the cache dir
    cache_dir   = /users/ovid/.perldbcolor
    

The above values are more or less the defaults for this module.

# ALPHA

This is only a proof of concept. In fact, it's fair to say that this code
sucks. It's not very configurable and has bugs. It's also going to possibly be
a memory hog, as if the debugger wasn't bad enough already.

# AUTHOR

Curtis "Ovid" Poe, `<ovid at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-db-color at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DB-Color](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DB-Color).  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DB::Color

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

[http://rt.cpan.org/NoAuth/Bugs.html?Dist=DB-Color](http://rt.cpan.org/NoAuth/Bugs.html?Dist=DB-Color)

- AnnoCPAN: Annotated CPAN documentation

[http://annocpan.org/dist/DB-Color](http://annocpan.org/dist/DB-Color)

- CPAN Ratings

[http://cpanratings.perl.org/d/DB-Color](http://cpanratings.perl.org/d/DB-Color)

- Search CPAN

[http://search.cpan.org/dist/DB-Color/](http://search.cpan.org/dist/DB-Color/)

# ACKNOWLEDGEMENTS

Thanks to Nick Perez, Liz, and the 2012 Perl Hackathon for helping to overcome
some major hurdles with this module.

# LICENSE AND COPYRIGHT

Copyright 2011 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

