
# Resource.pm - access resources in files

package Games::Resource;

# (C) by Tels <http://bloodgate.com/>

use strict;

require Exporter;
use vars qw/@ISA $VERSION/;
@ISA = qw/Exporter/;
use File::Spec;
use Archive::Zip;

$VERSION = '0.01';

##############################################################################
# methods

# some defaults
my $h = {
  data_path => 'data',
  mod_path => '',
  lang => 'en',
  resource_files => [ ],
  resource_hints => { },
  resource_extension => '.zip',
  };

sub config
  {
  if (@_ > 0)
    {
    my $config = shift;

    foreach my $n (qw/ data_path mod_path language 
      resource_extension resource_files resource_hints
      /)
      {
      $h->{$n} =
       $config->{$n} if exists $config->{$n} && defined $config->{$n};
      }
    }

  # return hash ref with values
   {
    data_path => $h->{data_path},
    mod_path => $h->{mod_path},
    language => $h->{lang},
    resource_extension => $h->{resource_extension},
    resource_files => [ @{$h->{resource_files}} ],	# make copy
    resource_hints => $h->{resource_hints},	# should also make a copy
   };
  }

sub _new
  {
  my ($FILE, $type) = @_;

  bless { handle => $FILE, type => $type || 'file' }, __PACKAGE__;
  }

sub open
  {
  my $file = pop(@_);

  # if we have a mod, try this first:
  if ($h->{mod_path} ne '')
    {
    chdir $h->{mod_path};
    my $FILE = Games::Resource::_open($h->{data_path}, @_, $file);
    chdir File::Spec->updir();
    return $FILE if defined $FILE;
    }
  Games::Resource::_open($h->{data_path}, @_ ,$file);
  }

sub _open
  {
  my $file = pop(@_);

  my ($name,$FILE);
  # first try language version
  $name = File::Spec->catfile(@_, $h->{lang}, $file);
  if (-e $name && -f $name)
    {
    CORE::open $FILE, $name;
    return _new($FILE) if defined $FILE;
    }
  # hm, no language, try without
  $name = File::Spec->catfile(@_, $file);
  if (-e $name && -f $name)
    {
    CORE::open $FILE, $name;
    return _new($FILE) if defined $FILE;
    }
  # hm, no luck, so browser resource files

  my $ext = $h->{resource_extension};
  foreach my $archive (@{$h->{resource_files}})
    {
    $name = File::Spec->catfile( $h->{data_path}, $archive . $ext);
    if (-e $name && -f $name)
      {
      my $zip = Archive::Zip->new($name);
      if (ref($zip))
        {
        $name = join ('/', @_, $h->{lang}, $file);
        my $member = $zip->memberNamed($name);
        if (!defined $member)
          {
          $name = join ('/', @_, $file);
          $member = $zip->memberNamed($name);
          }
        return _new($member,'zip') if defined $member;
        }
      }
    }
  # not found at all
  undef;
  }

###############################################################################
# OO methods

sub DESTROY
  {
  my $self = shift;

  close $self->{handle} unless $self->{type} eq 'zip';
  }

sub handle
  {
  my $self = shift;

  $self->{handle};
  }

sub contents
  {
  my $self = shift;

  if ($self->{type} eq 'zip')
    {
    return $self->{handle}->contents();
    }
  local $/;				# slurp mode
  my $handle = $self->{handle};
  seek ($handle, 0, 0);			# go to start
  <$handle>;
  }

# not done yet:
sub write
  {
  my $self = shift;
  
  if ($self->{type} eq 'ZIP')
    {
    require Carp; Carp::croak ("Cannot write to ZIP file members.");
    }
  }

1;

__END__

=pod

=head1 NAME

Games::Resource - open game resource files via standard paths

=head1 SYNOPSIS

	use Games::Resource;

	# set configuration

	Games::Resource::config (
	  data_path => 'data',
	  mod_path => '',
	  language => 'de',
	  resource_extension => '.zip',
	  resource_files => [ 'sounds', 'textures', 'models', ... ],
	  resource_hints => { md2 => 'models', ogg => 'sounds', ... },
	);

	# construct an object	
	my $file = Games::Resource::open('models','apple.md2');

	# get the handle to the file (unless part of an zip file)
        # This is not recommended.
	my $FILE_HANDLE = $file->handle();

	# or just the contents, regardless of how the file was stored
	$contents = $file->contents();		# not handle->contents unless

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

This package provides a standard way to access your game resources stored
in files. After setting up the paths and resource hints, you can simple
specify the filename and the module will figure out where the file actually
is. Here is an example with the example values from above:

	my $FILE_HANDLE = Game::Resource::open('books/book1.txt');

This would first try:

	data/books/en/book1.txt

On the reasoning that you specified 'de' as language. If it was not found
(because there is no German version), the next file tried would be:
	
	data/books/book1.txt

to access the "default language" version. If it was still not found, the
resource files will be tried. Since you did not specifiy a hint for C<.txt>
files, all of them (in semi-random order) will be tried, like:

	data/sounds.zip
	data/textures.zip
	data/models.zip
	...

In each of these resource files, the files:

	data/books/en/book1.txt
	data/books/book1.txt

will be tried.

If the file cannot be found at all, undef will be returned.

The reasource files must currently be ZIP archive. Maybe later other archive
formats will be supported.

The paths are assumed relative to the current path.

The file will be closed automatically when the object returned by L<open>
is destroyed, e.g. goes out of scope or is freed otherwise.

=head1 METHODS

=over 2

=item config()

	my $cfg = Game::Resource::config( );
	Game::Resource::config( $config );

Set/get the config values.

=item open()

	Games::Resource::open ($path, $file);

Try to find the given path and file and return a file handle. On error, returns
undef.

=back

=head1 AUTHORS

(c) 2003, Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<SDL:App::FPS>, L<SDL::App> and L<SDL>.

=cut


1;

__END__

=pod

=head1 NAME

Games::Resource - open game resource files via standard paths

=head1 SYNOPSIS

	use Games::Resource;

	Games::Resource::config (
	  data_path => 'data',
	  mod_path => '',
	  language => 'de',
	  resource_extension => '.zip',
	  resource_files => [ 'sounds', 'textures', 'models', ... ],
	  resource_hints => [ md2 => 'models', ogg => 'sounds', ... ],
	);
	
	my $FILE_HANDLE = Games::Resource::open('models','apple.md2');

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

This package provides a standard way to access your game resources stored
in files. After setting up the paths and resource hints, you can simple
specify the filename and the module will figure out where the file actually
is. Here is an example with the example values from above:

	my $FILE_HANDLE = Game::Resource::open('books/book1.txt');

This would first try:

	data/books/en/book1.txt

On the reasoning that you specified 'de' as language. If it was not found
(because there is no German version), the next file tried would be:
	
	data/books/book1.txt

to access the "default language" version. If it was still not found, the
resource files will be tried. Since you did not specifiy a hint for C<.txt>
files, all of them (in semi-random order) will be tried, like:

	data/sounds.zip
	data/textures.zip
	data/models.zip
	...

In each of these resource files, the files:

	data/books/en/book1.txt
	data/books/book1.txt

will be tried.

If the file cannot be found at all, undef will be returned.

=head1 METHODS

=over 2

=item config()

	my $cfg = Game::Resource::config( );
	Game::Resource::config( $config );

Set/get the config values.

Renders the brush.

=item open()

	Games::Resource::open ($path, $file);
	
Try to find the given path and file and return a file handle. On error, returns
undef.

=back

=head1 AUTHORS

(c) 2003, Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<SDL:App::FPS>, L<SDL::App> and L<SDL>.

=cut

sub open
  {
  my $file = pop(@_);
  my $path = File::Spec::catpath(@_);

  # if we have a mod, try this first:
  my $m = _mod_path();
  if ($m ne '')
    {
    my $FILE = Games::Resource::open($path,$m,$file);
    return $FILE if defined $FILE;
    }
  
  
  }

1;

__END__

=pod

=head1 NAME

Games::Resource - open game resource files via standard paths

=head1 SYNOPSIS

	use Games::Resource;

	Games::Resource::config (
	  data_path => 'data',
	  mod_path => '',
	  language => 'de',
	  resource_extension => '.zip',
	  resource_files => [ 'sounds', 'textures', 'models', ... ],
	  resource_hints => [ md2 => 'models', ogg => 'sounds', ... ],
	);
	
	my $FILE_HANDLE = Games::Resource::open('models','apple.md2');

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

This package provides a standard way to access your game resources stored
in files. After setting up the paths and resource hints, you can simple
specify the filename and the module will figure out where the file actually
is. Here is an example with the example values from above:

	my $FILE_HANDLE = Game::Resource::open('books/book1.txt');

This would first try:

	data/books/en/book1.txt

On the reasoning that you specified 'de' as language. If it was not found
(because there is no German version), the next file tried would be:
	
	data/books/book1.txt

to access the "default language" version. If it was still not found, the
resource files will be tried. Since you did not specifiy a hint for C<.txt>
files, all of them (in semi-random order) will be tried, like:

	data/sounds.zip
	data/textures.zip
	data/models.zip
	...

In each of these resource files, the files:

	data/books/en/book1.txt
	data/books/book1.txt

will be tried.

If the file cannot be found at all, undef will be returned.

=head1 METHODS

=over 2

=item config()

	my $cfg = Game::Resource::config( );
	Game::Resource::config( $config );

Set/get the config values.

Renders the brush.

=item open()

	Games::Resource::open ($path, $file);
	
Try to find the given path and file and return a file handle. On error, returns
undef.

The returned handle is not in C<binmode>, you need to do this by yourself if
you think you need it (e.g. opening non-text files under some old fashioned OS
like win32).

=back

=head1 AUTHORS

(c) 2003, Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<SDL:App::FPS>, L<SDL::App> and L<SDL>.

=cut

