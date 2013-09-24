[Japanese](https://github.com/aki2o/plsense/blob/master/README-ja.md)

What's this?
============

This is a development tool for Perl using the type inference by analyzing source code.  
This tool is for highly functional editor like Emacs/Vim.


Feature
=======

You can do the following function by using this tool.

### Omni completion

About the following programming element, you can do the optimized completion for context.  
It's Omni completion what is called.  

* Variable
* Method
* Module
* Initializer of Class
* LIST of Use/Require statement
* Key of Hash

![demo1](image/demo1.png)

### Smart help

![demo1](image/demo2.png)

### Signature of sub

![demo1](image/demo3.png)

### Jump to definition


Demo
====

This is a coding demo when this tool is used on Emacs.

http://www.youtube.com/watch?v=Q8XDhxqmaXs

For using on Emacs, see https://github.com/aki2o/emacs-plsense/blob/master/README.md


Install
=======

This tool is a Perl module.

### From CPAN

2013/07/24 Not yet available.

### Using cpanm

Download latest PlSense-?.??.tar.gz from [here](https://github.com/aki2o/plsense/releases)
and execute cpanm to the downloaded file path.

### Manually

Download latest PlSense-?.??.tar.gz from [here](https://github.com/aki2o/plsense/releases)
and extract the file, move the maked directory, execute the following.

```
$ perl Makefile.PL
$ make
$ make test
$ make install
```

If the module is not yet installed that this module depends on, error maybe happen.  
In the case, install the module and retry. About the module, see Makefile.PL.

### Verify installation

execute `plsense -v` on shell.  
If show the PlSense version, installation is finished.

### After installation

Making config file is easy way for using this tool.  
Do `plsense` on terminal. plsense confirm whether make config file.  

\* For remake config file, do `plsense config`.  
\* You can use this tool without config file. see https://github.com/aki2o/plsense/wiki/Config.  


Usage
=====

For the end user, perhaps it's no need to know usage of this tool.  
About usage/specification of this tool, see https://github.com/aki2o/plsense/wiki/Home.  


Tested On
=========

* WindowsXP Pro SP3 32bit
* Cygwin 1.7.20-1
* Perl 5.14.2


**Enjoy!!!**

