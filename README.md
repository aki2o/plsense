[Japanese](https://github.com/aki2o/plsense/blob/master/README-ja.md)

What's this?
============

This is a Perl module that provide completion/help optimized for context.  
This module is for highly functional editor like Emacs and Vim.


Feature
=======

### Show a optimized completion, help, information of method

Show a optimized completion, help, information of method by identifying context of source code.

### List of identifed context

* Variable
* Method
* Module
* Initializer of Class
* LIST of Use/Require statement
* Key of Hash


ScreenShot
==========

when using this module on Emacs.

![demo1](image/demo1.png)


Demo
====

This is a coding demo when using this module on Emacs.

http://www.youtube.com/watch?v=Q8XDhxqmaXs

For using on Emacs, see https://github.com/aki2o/emacs-plsense/blob/master/README.md


Install
=======

### From CPAN

2013/07/24 Not yet available.

### Using cpanm

    # git clone https://github.com/aki2o/plsense.git
    # cd plsense
    # cpanm PlSense-?.??.tar.gz

### Manually

    # git clone https://github.com/aki2o/plsense.git
    # cd plsense
    # perl Makefile.PL
    # make
    # make manifest
    # make test
    # make instal

If the module is not yet installed that this module depends on, error maybe happen.  
In the case, install the module and retry. About the module, see Makefile.PL.

### Verify installation

execute `plsense -v` on shell.  
If show the PlSense version, installation is finished.


Configuration
=============

### For global

The following has an effect on action of PlSense.

* cachedir ... path of directory caching analysis result.
* maxtasks ... limit count of task that run on server process.
* port1, port2, port3 ... port number for listening by server process.
* logfile ... path of log file.
* loglevel ... level of logging by Log::Handler.

**Note:** Avoid a temporary path (e.g. /tmp) for _cachedir_ because cache is available continuously.  
**Note:** The high speed device is better for _cachedir_ because I/O is required frequently.  
**Note:** About quantity for _cachedir_ and number for _maxtasks_, see 'Resource' section.  
**Note:** Architecture of PlSense is C/S. Count of server process is 3.  
**Note:** If _logfile_ is missing, do not logging.  
**Note:** About _loglevel_, see help of Log::Handler.  

#### Config file

The way for using the above item is that give a command line argument to PlSense like `plsense --cachedir=...`.  
Alternatively, it's OK by putting the file that named '.plsense' in user home directory.

    # cat ~/.plsense
    cachedir=/home/user1/.plsense.d
    logfile=/tmp/plsense.log
    loglevel=info
    maxtasks=20
    port1=33333
    port2=33334
    port3=33335

**Note:** The file can be maked when you execute `plsense`.  
**Note:** The way by giving a command line argument is prior than by the file.  

### For project

If you have library for some project, put the file that named '.plsense' in root of the project.  

    # cat /var/dev/sample/.plsense 
    name=SampleProj
    lib-path=lib

* name ... name of project. need match [a-zA-Z0-9_]+
* lib-path ... relational path to library. In the above case, it's /var/dev/sample/lib


Resource
========

Consumption of resource depends on the number and size of module analyzed.  
For example, if analyze about 200 modules,

* Quantity of _cachedir_ is about 20 MB.
* Quantity of memory kept by server process is about 100 MB.

Otherwise, task run by server process for searching library and analyzing source code.  
Quantity of memory kept by the task process is about 25 MB.  

_maxtasks_ is a max number of the task process. The default is 20.  
So, in the above case, it's maybe happen that consumption of memory up to about 600 MB temporarily.

By the way, Analyzing is done recursively.  
It means that a number of analyzed modules depends on recursive count of use/require statement.


Time Required
=============

Provision of completion/help is started soon.  
But a few miniutes is required for the result is optimized.  

It depends on recursive count of modules not yet analyzed.  
For example, it's about 15 minutes for about 200 modules when _maxtasks_ is 20.


Restriction
===========

### Literal

The idea about analyzing is collection of substitute/return statement.

```perl
sub hoge () {
    my $hoge = shift;  # substitute statement
    return $hoge;      # return statement
}
```

Identify the type of Variable/Method by gathering them.  
For identify type, literal has most priority.

```perl
my $hoge = "hoge";                # SCALAR
my @hoge = ("ho", "ge");          # ARRAY
my %hoge = ( name => "hoge", );   # HASH
my $hoge = [ "ho", "ge" ];        # REFERENCE of ARRAY
my $hoge = { name => "hoge", };   # REFERENCE of HASH
```

If the context has multiple different literal like the following,  
It can not be ensured that the type is identified.

```perl
my $hoge = [ "hoge" ];
my $fuga = {};
if ( $hoge ) { $fuga = $hoge; }  # can't identify $fuga
```

### bless

If the module has the method named 'new',  
The result of the method is considered as instance of the module.  
It is not ensured that the type is identified by returning blessed reference.

```perl
package Hoge;
sub new { return; }                                                       # be instance of Hoge absolutely
sub get_instance { Fuga->new(); }                                         # ensure instance of FUga
sub get_instance { my $cls=shift; my $r={}; bless $r, $cls; return $r; }  # not ensure instance of $cls
```

### Array

Number of element is ignored. Each element of array is considered as same type.

```perl
$hoge[0] = Hoge->new();
$hoge[1] = \%fuga;
$hoge[0]->    # not ensure complete method of Hoge
```

### Hash

The value can be discerned if the key is literal and match '[a-zA-Z0-9_\-]+'.

```perl
$hoge{hoge} = Hoge->new();
$hoge{"fuga"} = \%fuga;
my ($foo, $bar) = ("foo", "bar");
$hoge{$foo} = Foo->new();
$hoge{$bar} = Bar->new(); # not discern $bar from $foo

$hoge{hoge}->      # ensure complete method of Hoge
$hoge{'fuga'}->{   # ensure complete key of %fuga
$hoge{$foo}->      # not ensure complete method of Foo
```

### Scope of variable

Variable can be discerned until sub scope.

```perl
package Hoge;
my $some = Fuga->new();

sub get_hoge {
    my $some = Foo->new();
    foreach my $e ( "foo", "bar" ) {
        my $some = $e;
    }
    $some->  # not ensure complete method of Foo
}

$some->   # ensure complete method of Fuga
```

### Binomial operator

```perl
my $hoge = Hoge->new() || Fuga->new(); # $hoge is considered as instance of Hoge
my $fuga = Hoge->new() && Fuga->new(); # $fuga is considered as instance of Fuga
```

### Ternary operator

The first part is used.

```perl
my $some = $hoge ? Hoge->new()
         : $fuga ? Fuga->new()
         :         Bar->new();
$some->  # ensure complete method of Hoge
```

### Variable/Method in literal

Array or value of hash is identified only.

```perl
my @hoge = ( @fuga, @bar );         # if @fuga/@bar is identified, @hoge is identified.
my %hoge = ( fuga => get_fuga() );  # if get_fuga() is identified, $hoge{fuga} is identified.
my $hoge = { %fuga };               # can not identify
my $hoge = [ @fuga, @bar ];         # can not identify
```

### Call of method

```perl
my $hoge = new Hoge;   # can not identify
my $hoge = Hoge->new;  # can identify

my $hoge = myfunc $fuga;  # $fuga is not considered as argument
my $hoge = myfunc($fuga); # $fuga is considered as argument

my $hoge = shift @fuga; # if builtin method, it's OK
```

But, can not identify if the builtin method is not _handled_.  
At present, the _handled_ builtin method is the following.

* bless
* eval (BLOCK only)
* grep
* first
* pop
* push
* reverse
* shift
* sort
* undef
* unshift
* values

Also, the _handled_ external method is the following.

* List::Util::first, List::AllUtils::first
* List::MoreUtils::uniq, List::AllUtils::uniq

_handled_ means that the plugin is implemented about the method in addition to normal.  
For detail, see 'Scalability' section below.

### Argument of method

The type of argument can not be identified until found colling the method normally.

```perl
sub hoge {
    my $hoge = shift;
    $hoge->  # $hoge is unknown
}

hoge( Hoge->new() );  # if this statement exists、$hoge is identified above.
```

But, if the module that the method belongs to has the method named 'new',  
the first argument of the method in the module is considered as instance of the module.

```perl
package Hoge;

sub new { my $r = {}; bless $r; return $r; }

sub hoge {
    my $hoge = shift;  # be instance of Hoge absolutely
    my $fuga = shift;
    $hoge->  # ensure complete method of Hoge
}
```

In the case, index of given argument move to back.

```perl
package main;
use Hoge;
Hoge->hoge( $arg );  # above $fuga is considered as $arg
```

By right, the word before arrow operator is the first argument.  
But, PlSense has not the idea.

### Grammar provided by module

Analyzing is done by reading default grammar of Perl.  
If some module provide special grammar, it can be read.  
For example, write the following by using Moose,

```perl
package Hoge;
use Moose;
has 'fuga' => ( is => 'rw', isa => 'Fuga' );

package main;
my $hoge = Hoge->new();
$hoge->fuga->  # return of fuga() is instance of Fuga
```

It is not identified.

But, at present, can read special grammar of the following module.

* Class::Std

It means that the plugin is implemented about the above module.  
For detail, see 'Scalability' section below.


Scalability
===========

PlSense use Module::Pluggable and has some point for plugin.  
If you have some idea for above restriction, resolving it is possible by making plugin.  
For detail, see https://github.com/aki2o/plsense/blob/master/DevelopmentGuide.md


Usage
=====

talk with server process throw plsense command provided by installation of PlSense.  
see help of the command by executing `plsense --help`.

**Note:** If you are not developer of PlSense, no need to see the help.


Tested On
=========

* WindowsXP Pro SP3 32bit
* Cygwin 1.7.20-1
* Perl 5.14.2


**Enjoy!!!**

