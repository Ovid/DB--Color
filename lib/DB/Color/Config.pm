package DB::Color::Config;

# If you thought Config::Simple was small...

use strict;
BEGIN {
    require 5.004;
    $DB::Color::Config::VERSION = '.07';
    $DB::Color::Config::errstr  = '';
}

# Create an empty object
sub new { bless {}, shift }

# Create an object from a file
sub read {
    my $class = ref $_[0] ? ref shift : shift;

    # Check the file
    my $file = shift or return $class->_error( 'You did not specify a file name' );
    return $class->_error( "File '$file' does not exist" )              unless -e $file;
    return $class->_error( "'$file' is a directory, not a file" )       unless -f _;
    return $class->_error( "Insufficient permissions to read '$file'" ) unless -r _;

    # Slurp in the file
    local $/ = undef;
    open( CFG, $file ) or return $class->_error( "Failed to open file '$file': $!" );
    my $contents = <CFG>;
    close( CFG );

    $class->read_string( $contents );
}

# Create an object from a string
sub read_string {
    my $class = ref $_[0] ? ref shift : shift;
    my $self  = bless {}, $class;
    return undef unless defined $_[0];

    # Parse the file
    my $ns      = '_';
    my $counter = 0;
    foreach ( split /(?:\015{1,2}\012|\015|\012)/, shift ) {
        $counter++;

        # Skip comments and empty lines
        next if /^\s*(?:\#|\;|$)/;

        # Remove inline comments
        s/\s\;\s.+$//g;

        # Handle section headers
        if ( /^\s*\[\s*(.+?)\s*\]\s*$/ ) {
            # Create the sub-hash if it doesn't exist.
            # Without this sections without keys will not
            # appear at all in the completed struct.
            $self->{$ns = $1} ||= {};
            next;
        }

        # Handle properties
        if ( /^\s*([^=]+?)\s*=\s*(.*?)\s*$/ ) {
            $self->{$ns}->{$1} = $2;
            next;
        }

        return $self->_error( "Syntax error at line $counter: '$_'" );
    }

    $self;
}

# Save an object to a file
sub write {
    my $self = shift;
    my $file = shift or return $self->_error(
        'No file name provided'
        );

    # Write it to the file
    my $string = $self->write_string;
    return undef unless defined $string;
    open( CFG, '>' . $file ) or return $self->_error(
        "Failed to open file '$file' for writing: $!"
        );
    print CFG $string;
    close CFG;
}

# Save an object to a string
sub write_string {
    my $self = shift;

    my $contents = '';
    foreach my $section ( sort { (($b eq '_') <=> ($a eq '_')) || ($a cmp $b) } keys %$self ) {
        # Check for several known-bad situations with the section
        # 1. Leading whitespace
        # 2. Trailing whitespace
        # 3. Newlines in section name
        return $self->_error(
            "Illegal whitespace in section name '$section'"
        ) if $section =~ /(?:^\s|\n|\s$)/s;
        my $block = $self->{$section};
        $contents .= "\n" if length $contents;
        $contents .= "[$section]\n" unless $section eq '_';
        foreach my $property ( sort keys %$block ) {
            return $self->_error(
                "Illegal newlines in property '$section.$property'"
            ) if $block->{$property} =~ /(?:\012|\015)/s;
            $contents .= "$property=$block->{$property}\n";
        }
    }
    
    $contents;
}

# Error handling
sub errstr { $DB::Color::Config::errstr }
sub _error { $DB::Color::Config::errstr = $_[1]; undef }

1;

__END__

=pod

=head1 NAME

DB::Color::Config - Read/Write .ini style files with as little code as possible

=head1 NOTE

This is an embedded fork of L<Config::Tiny> version 2.14. There is no
functional change.

=head1 SYNOPSIS

    # In your configuration file
    rootproperty=blah

    [section]
    one=twp
    three= four
    Foo =Bar
    empty=

    # In your program
    use DB::Color::Config;

    # Create a config
    my $Config = DB::Color::Config->new;

    # Open the config
    $Config = DB::Color::Config->read( 'file.conf' );

    # Reading properties
    my $rootproperty = $Config->{_}->{rootproperty};
    my $one = $Config->{section}->{one};
    my $Foo = $Config->{section}->{Foo};

    # Changing data
    $Config->{newsection} = { this => 'that' }; # Add a section
    $Config->{section}->{Foo} = 'Not Bar!';     # Change a value
    delete $Config->{_};                        # Delete a value or section

    # Save a config
    $Config->write( 'file.conf' );

=head1 DESCRIPTION

C<DB::Color::Config> is a perl class to read and write .ini style configuration
files with as little code as possible, reducing load time and memory
overhead. Most of the time it is accepted that Perl applications use a lot
of memory and modules. The C<::Tiny> family of modules is specifically
intended to provide an ultralight alternative to the standard modules.

This module is primarily for reading human written files, and anything we
write shouldn't need to have documentation/comments. If you need something
with more power move up to L<Config::Simple>, L<Config::General> or one of
the many other C<Config::> modules. To rephrase, L<DB::Color::Config> does B<not>
preserve your comments, whitespace, or the order of your config file.

=head1 CONFIGURATION FILE SYNTAX

Files are the same format as for windows .ini files. For example:

    [section]
    var1=value1
    var2=value2

If a property is outside of a section at the beginning of a file, it will
be assigned to the C<"root section">, available at C<$Config-E<gt>{_}>.

Lines starting with C<'#'> or C<';'> are considered comments and ignored,
as are blank lines.

When writing back to the config file, all comments, custom whitespace,
and the ordering of your config file elements is discarded. If you need
to keep the human elements of a config when writing back, upgrade to
something better, this module is not for you.

=head1 METHODS

=head2 new

The constructor C<new> creates and returns an empty C<DB::Color::Config> object.

=head2 read $filename

The C<read> constructor reads a config file, and returns a new
C<DB::Color::Config> object containing the properties in the file. 

Returns the object on success, or C<undef> on error.

When C<read> fails, C<DB::Color::Config> sets an error message internally
you can recover via C<DB::Color::Config-E<gt>errstr>. Although in B<some>
cases a failed C<read> will also set the operating system error
variable C<$!>, not all errors do and you should not rely on using
the C<$!> variable.

=head2 read_string $string;

The C<read_string> method takes as argument the contents of a config file
as a string and returns the C<DB::Color::Config> object for it.

=head2 write $filename

The C<write> method generates the file content for the properties, and
writes it to disk to the filename specified.

Returns true on success or C<undef> on error.

=head2 write_string

Generates the file content for the object and returns it as a string.

=head2 errstr

When an error occurs, you can retrieve the error message either from the
C<$DB::Color::Config::errstr> variable, or using the C<errstr()> method.

=head1 CAVEATS

=head2 Unsupported Section Headers

Some edge cases in section headers are not support, and additionally may not
be detected when writing the config file.

Specifically, section headers with leading whitespace, trailing whitespace,
or newlines anywhere in the section header, will not be written correctly
to the file and may cause file corruption.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Tiny>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 ACKNOWLEGEMENTS

Thanks to Sherzod Ruzmetov E<lt>sherzodr@cpan.orgE<gt> for
L<Config::Simple>, which inspired this module by being not quite
"simple" enough for me :)

=head1 SEE ALSO

L<Config::Simple>, L<Config::General>, L<ali.as>

=head1 COPYRIGHT

Copyright 2002 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
