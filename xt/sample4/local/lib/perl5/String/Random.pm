# String::Random - Generates a random string from a pattern
# Copyright (C) 1999-2006 Steven Pritchard <steve@silug.org>
#
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# $Id: Random.pm,v 1.4 2006/09/21 17:34:07 steve Exp $

package String::Random;

require 5.006_001;

use strict;
use warnings;

use Carp;
use Exporter ();

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
    &random_string
    &random_regex
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = ();
our $VERSION = '0.26';

# These are the various character sets.
our @upper=("A".."Z");
our @lower=("a".."z");
our @digit=("0".."9");
our @punct=map { chr($_); } (33..47,58..64,91..96,123..126);
our @any=(@upper, @lower, @digit, @punct);
our @salt=(@upper, @lower, @digit, ".", "/");
our @binary=map { chr($_) } (0..255);

# What's important is how they relate to the pattern characters.
# These are the old patterns for randpattern/random_string.
our %old_patterns = (
    'C' => [ @upper ],
    'c' => [ @lower ],
    'n' => [ @digit ],
    '!' => [ @punct ],
    '.' => [ @any ],
    's' => [ @salt ],
    'b' => [ @binary ],
);

# These are the regex-based patterns.
our %patterns = (
    # These are the regex-equivalents.
    '.' => [ @any ],
    '\d' => [ @digit ],
    '\D' => [ @upper, @lower, @punct ],
    '\w' => [ @upper, @lower, @digit, "_" ],
    '\W' => [ grep { $_ ne "_" } @punct ],
    '\s' => [ " ", "\t" ], # Would anything else make sense?
    '\S' => [ @upper, @lower, @digit, @punct ],

    # These are translated to their double quoted equivalents.
    '\t' => [ "\t" ],
    '\n' => [ "\n" ],
    '\r' => [ "\r" ],
    '\f' => [ "\f" ],
    '\a' => [ "\a" ],
    '\e' => [ "\e" ],
);

# These characters are treated specially in randregex().
our %regch = (
   "\\" => sub {
               my ($self, $ch, $chars, $string)=@_;
               if (@{$chars}) {
                   my $tmp=shift(@{$chars});
                   if ($tmp eq "x") {
                       # This is supposed to be a number in hex, so
                       # there had better be at least 2 characters left.
                       $tmp=shift(@{$chars}) . shift(@{$chars});
                       push(@{$string}, [chr(hex($tmp))]);
                   } elsif ($tmp=~/[0-7]/) {
                       carp "octal parsing not implemented.  treating literally.";
                       push(@{$string}, [$tmp]);
                   } elsif (defined($patterns{"\\$tmp"})) {
                       $ch.=$tmp;
                       push(@{$string}, $patterns{$ch});
                   }
                   else {
                       if ($tmp =~ /\w/) {
                           carp "'\\$tmp' being treated as literal '$tmp'";
                       }
                       push(@{$string}, [$tmp]);
                   }
               } else {
                   croak "regex not terminated";
               }
           },
    '.' => sub {
               my ($self, $ch, $chars, $string)=@_;
               push(@{$string}, $patterns{$ch});
           },
    '[' => sub {
               my ($self, $ch, $chars, $string)=@_;
               my @tmp;
               while (defined($ch=shift(@{$chars})) && ($ch ne "]")) {
                   if (($ch eq "-") && @{$chars} && @tmp) {
                       $ch=shift(@{$chars});
                       for (my $n=ord($tmp[$#tmp]);$n<ord($ch);$n++) {
                           push(@tmp, chr($n+1));
                       }
                   } else {
                       carp "'$ch' will be treated literally inside []"
                           if ($ch=~/\W/);
                       push(@tmp, $ch);
                   }
               }
               croak "unmatched []" if ($ch ne "]");
               push(@{$string}, \@tmp);
           },
    '*' => sub {
               my ($self, $ch, $chars, $string)=@_;
               unshift(@{$chars}, split("", "{0,}"));
           },
    '+' => sub {
               my ($self, $ch, $chars, $string)=@_;
               unshift(@{$chars}, split("", "{1,}"));
           },
    '?' => sub {
               my ($self, $ch, $chars, $string)=@_;
               unshift(@{$chars}, split("", "{0,1}"));
           },
    '{' => sub {
               my ($self, $ch, $chars, $string)=@_;
               my ($n, $closed);
               for ($n=0;$n<scalar(@{$chars});$n++) {
                   if ($chars->[$n] eq "}") {
                       $closed++;
                       last;
                   }
               }
               if ($closed) {
                   my $tmp;
                   while (defined($ch=shift(@{$chars})) && ($ch ne "}")) {
                       croak "'$ch' inside {} not supported" if ($ch!~/[\d,]/);
                       $tmp.=$ch;
                   }
                   if ($tmp=~/,/) {
                       if (my ($min,$max) = $tmp =~ /^(\d*),(\d*)$/) {
                           $min = 0 if (!length($min));
                           $max = $self->{'_max'} if (!length($max));
                           croak "bad range {$tmp}" if ($min>$max);
                           if ($min == $max) {
                               $tmp = $min;
                           } else {
                               $tmp = $min + int(rand($max - $min +1));
                           }
                       } else {
                           croak "malformed range {$tmp}";
                       }
                   }
                   if ($tmp) {
                       my $last=$string->[$#{$string}];
                       for ($n=0;$n<($tmp-1);$n++) {
                           push(@{$string}, $last);
                       }
                   } else {
                       pop(@{$string});
                   }
               } else {
                   # { isn't closed, so treat it literally.
                   push(@{$string}, [$ch]);
               }
           },
);

sub new {
    my $proto=shift;
    my $class=ref($proto) || $proto;
    my $self;
    $self={ %old_patterns }; # makes $self refer to a copy of %old_patterns
    my %args=();
    %args=@_ if (@_);
    if (defined($args{'max'})) {
        $self->{'_max'}=$args{'max'};
    } else {
        $self->{'_max'}=10;
    }
    return bless($self, $class);
}

# Returns a random string for each regular expression given as an
# argument, or the strings concatenated when used in a scalar context.
sub randregex {
    my $self=shift;
    croak "called without a reference" if (!ref($self));

    my @strings=();

    while (defined(my $pattern=shift)) {
        my $ch;
        my @string=();
        my $string='';

        # Split the characters in the pattern
        # up into a list for easier parsing.
        my @chars=split(//, $pattern);

        while (defined($ch=shift(@chars))) {
            if (defined($regch{$ch})) {
                $regch{$ch}->($self, $ch, \@chars, \@string);
            } elsif ($ch=~/[\$\^\*\(\)\+\{\}\]\|\?]/) {
                # At least some of these probably should have special meaning.
                carp "'$ch' not implemented.  treating literally.";
                push(@string, [$ch]);
            } else {
                push(@string, [$ch]);
            }
        }

        foreach $ch (@string) {
            $string.=$ch->[int(rand(scalar(@{$ch})))];
        }

        push(@strings, $string);
    }

    return wantarray ? @strings : join("", @strings);
}

# For compatibility with an ancient version, please ignore...
sub from_pattern {
    my $self=shift;
    croak "called without a reference" if (!ref($self));

    return $self->randpattern(@_);
}

sub randpattern {
    my $self=shift;
    croak "called without a reference" if (!ref($self));

    my @strings=();

    while (defined(my $pattern=shift)) {
        my $string='';

        for my $ch (split(//, $pattern)) {
            if (defined($self->{$ch})) {
                $string.=$self->{$ch}->[int(rand(scalar(@{$self->{$ch}})))];
            } else {
                croak qq(Unknown pattern character "$ch"!);
            }
        }
        push(@strings, $string);
    }

    return wantarray ? @strings : join("", @strings);
}

sub random_regex {
    my $foo=new String::Random;
    return $foo->randregex(@_);
}

sub random_string {
    my($pattern,@list)=@_;

    my($n,$foo);

    $foo=new String::Random;

    for ($n=0;$n<=$#list;$n++) {
        @{$foo->{$n}}=@{$list[$n]};
    }

    return $foo->randpattern($pattern);
}

1;
__END__

=encoding utf8

=head1 NAME

String::Random - Perl module to generate random strings based on a pattern

=head1 SYNOPSIS

    use String::Random;
    my $string_gen = String::Random->new;
    print $string_gen->randregex('\d\d\d'); # Prints 3 random digits
    # Prints 3 random printable characters
    print $string_gen->randpattern("...");

I<or>

    use String::Random qw(random_regex random_string);
    print random_regex('\d\d\d'); # Also prints 3 random digits
    print random_string("...");   # Also prints 3 random printable characters

=head1 DESCRIPTION

This module makes it trivial to generate random strings.

As an example, let's say you are writing a script that needs to generate a
random password for a user.  The relevant code might look something like
this:

    use String::Random;
    my $pass = String::Random->new;
    print "Your password is ", $pass->randpattern("CCcc!ccn"), "\n";

This would output something like this:

  Your password is UDwp$tj5

B<NOTE!!!>: currently, String::Random uses Perl's built-in predictable random
number generator so the passwords generated by it are insecure.

If you are more comfortable dealing with regular expressions, the following
code would have a similar result:

  use String::Random;
  my $pass = String::Random->new;
  print "Your password is ",
      $pass->randregex('[A-Z]{2}[a-z]{2}.[a-z]{2}\d'), "\n";

=head2 Patterns

The pre-defined patterns (for use with C<randpattern()> and C<random_pattern()>)
are as follows:

  c        Any Latin lowercase character [a-z]
  C        Any Latin uppercase character [A-Z]
  n        Any digit [0-9]
  !        A punctuation character [~`!@$%^&*()-_+={}[]|\:;"'.<>?/#,]
  .        Any of the above
  s        A "salt" character [A-Za-z0-9./]
  b        Any binary data

These can be modified, but if you need a different pattern it is better to
create another pattern, possibly using one of the pre-defined as a base.
For example, if you wanted a pattern C<A> that contained all upper and lower
case letters (C<[A-Za-z]>), the following would work:

  my $gen = String::Random->new;
  $gen->{'A'} = [ 'A'..'Z', 'a'..'z' ];

I<or>

  my $gen = String::Random->new;
  $gen->{'A'} = [ @{$gen->{'C'}}, @{$gen->{'c'}} ];

The random_string function, described below, has an alternative interface
for adding patterns.

=head2 Methods

=over 8

=item new

=item new max =E<gt> I<number>

Create a new String::Random object.

Optionally a parameter C<max> can be included to specify the maximum number
of characters to return for C<*> and other regular expression patterns that
do not return a fixed number of characters.

=item randpattern LIST

The randpattern method returns a random string based on the concatenation
of all the pattern strings in the list.

It will return a list of random strings corresponding to the pattern
strings when used in list context.

=item randregex LIST

The randregex method returns a random string that will match the regular
expression passed in the list argument.

Please note that the arguments to randregex are not real regular
expressions.  Only a small subset of regular expression syntax is actually
supported.  So far, the following regular expression elements are
supported:

  \w    Alphanumeric + "_".
  \d    Digits.
  \W    Printable characters other than those in \w.
  \D    Printable characters other than those in \d.
  .     Printable characters.
  []    Character classes.
  {}    Repetition.
  *     Same as {0,}.
  ?     Same as {0,1}.
  +     Same as {1,}.

Regular expression support is still somewhat incomplete.  Currently special
characters inside [] are not supported (with the exception of "-" to denote
ranges of characters).  The parser doesn't care for spaces in the "regular
expression" either.

=back

=head2 Functions

=over 8

=item random_string PATTERN,LIST

=item random_string PATTERN

When called with a single scalar argument, random_string returns a random
string using that scalar as a pattern.  Optionally, references to lists
containing other patterns can be passed to the function.  Those lists will
be used for 0 through 9 in the pattern (meaning the maximum number of lists
that can be passed is 10).  For example, the following code:

    print random_string("0101",
                        ["a", "b", "c"],
                        ["d", "e", "f"]), "\n";

would print something like this:

    cebd

=back

=head1 BUGS

This is Bug Free™ code.  (At least until somebody finds one…)

Please report bugs here:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Random> .

=head1 AUTHOR

Original Author: Steven Pritchard C<< steve@silug.org >>

Now maintained by: Shlomi Fish ( L<http://www.shlomifish.org/> ).

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut

# vi: set ai et:
