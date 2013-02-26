package Cake::Config;
use strict;

use File::Slurp qw(:std);
use JSON;

=head1 NAME

Cake::Exception

=head1 DESCRIPTION

The module provide a common interface for configuration access and loading.
It operates under the basic assumption that there is one configuration file.

The package holds a global variable, holding the json defined config file.
It provides objects which can be used to access the information in the file.

=head1 METHODS

=head2 new

this method provides a new interface object.

=head3 Invocation:

C<< Cake::Config->new() >>

This is a generic new function.  it does not accept any parameters.

=cut
use Data::Dumper qw(Dumper);
sub new {
	my $class = shift;
	
	my $self  = { __CONFIG__ => my $scalar='' };
	
	bless $self, $class;

	return $self;
}

=head2 loadConfig

This method specifies the config file that should be loaded, and that will be used
in configuration retrieval.

=head3 Invocation:

C<< $configObject->loadConfig('this/is/a/file/name.json') >>

This method will not attempt to do any resolution of path names.

=cut

sub loadConfig {
	my ($self, $file) = @_;

	Cake::Exception::Config::LoadError->assert(sub{
		read_file($file, buf_ref => \($self->{__CONFIG__}) )
		}, {file => $file});

	$self->{__CONFIG__} = decode_json($self->{__CONFIG__});

	return $self;
}

=head2 fetchAll

This method is used to fetch a hashref of all the variable => value pairs in a given namespace, or the
current one if none is given.

=head3 Invocation:

C<< $configObject->fetchAll() #I use the current package name >>

C<< $configObject->fetchAll("config::Name::Space") # I use the given namespace >>

=cut

sub fetchAll {
	my ($self, $package) = @_;
	my $caller = caller;
	
	my $namespace = $package || $caller;

	return $self->{__CONFIG__}{$namespace};
}

=head2 AUTOLOAD

The heart of the package is using autoload to automatically search the config file for a variable
matching the one requested.
by default, it will search first in the current package, and then up progressive levels until such point
that it reaches the global namespace, where it will throw an exception if it doesn't fine the variable.

=head3 Invocation:

C<< $configObject->Anything >>

=cut

sub AUTOLOAD {
	my ($self, $package) = @_;
	
	our $AUTOLOAD;
	my $caller   = caller;
	my $namespace = $package || $caller;
	
	(my $variable = $AUTOLOAD) =~ s/.*:://;
	
	while($namespace) {
		if(exists $self->{__CONFIG__}{$namespace}{$variable}) {
			return $self->{__CONFIG__}{$namespace}{$variable};
		}
		$namespace =~ s/::.*?$// or last;
	}
	if(exists $self->{__CONFIG__}{GLOBAL}{$variable}) {
		return $self->{__CONFIG__}{GLOBAL}{$variable};
	}
	else {
		Cake::Exception::Config::UndefinedVariable->throw({variable => $variable});
	}
}

sub DESTROY {}

1;

__END__

=head1 AUTHOR

Sebastian Green-Husted <ricecake@tfm.nu>

=cut
