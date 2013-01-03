package Cake::Object::Storage::Persistent::NoSQL::Cassandra;
use strict;
use base qw(Cake::Object::Storage::Persistent::NoSQL);

use Cake::Object::Storage::Persistent::NoSQL::Cassandra::Resultset;

use Cassandra::Simple;

__PACKAGE__->__engine(__PACKAGE__);

sub __init {
	my ($self, $class) = @_;
	$class->_registerInitCallback(__PACKAGE__->can('__instantiate'));
	$self->SUPER::__init($class);
}

sub __setupStorageTraits {
	my ($class) = @_;
	return sub {
		my ($objClass) = shift;
		print "$class => $objClass\n";
	}
}

1;
