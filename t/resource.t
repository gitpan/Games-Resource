#!/usr/bin/perl -w

use Test::More tests => 19;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('Games::Resource'); 
  }

can_ok ('Games::Resource', qw/ 
  open config
  /);

my $cfg = Games::Resource::config();

is (ref($cfg), 'HASH', 'config returns hash');

is ($cfg->{language}, 'en', 'en is default');

Games::Resource::config( { resource_files => [ 'books' ] } );
$cfg = Games::Resource::config();

is (join(", ", @{$cfg->{resource_files}}), 'books', 'set books');

##############################################################################
# open() tests

my $FILE = Games::Resource::open ( 'test.txt' );
cmp_file($FILE,'test.txt');

$FILE = Games::Resource::open ( 'book1.txt' );
cmp_file($FILE,'book1.txt');

$FILE = Games::Resource::open ( 'books', 'book2.txt' );		# just so
cmp_file($FILE,'books/book2.txt');

$FILE = Games::Resource::open ( 'books', 'book3.txt' );		# w/ lang=en
cmp_file($FILE,'books/book2.txt');

$FILE = Games::Resource::open ( 'books/book4.txt' );		# in zipfile
cmp_file($FILE,'books/book4.txt');

##############################################################################

sub cmp_file
  {
  my $file = shift;
  my $name = shift;

  is (ref($file), 'Games::Resource');
  if (defined $file)
    {
    my $FILE = $file->handle();
    my $doc = '';
    if (ref($FILE) eq 'GLOB')
      {
      binmode $FILE;
      while (<$FILE>) { $doc .= $_; }
      is ($doc, "Test\ntest\n", "$name opened and read");
      }
    $doc = $file->contents();
    is ($doc, "Test\ntest\n", "$name contents()");
    }
  else
    {
    isnt ($file ||'undef', 'undef', "$name not found?");
    }
  }
