package Cake::Object::Storage;
use strict;
use base qw(Cake::Object);

use Cake::Role qw(Cake::Role::Config);


=pod
The engine function should return the name of the engine in use.  Typically this is the package name for the storage mechanism.
This is needed so that objects that are inheriting different methods from different engines can keep their namespaces clean for local
and class data.
=cut

__PACKAGE__->mk_classdata( "__engine" => __PACKAGE__ );

=pod
the driver method should just return a reference to the low level driver that the
storage class uses, be it the redis connection object, a local storage hash, or the DBI handle.
=cut

__PACKAGE__->mk_classdata( "__driver");

=pod
The class data is for the storage of information regarding storage semanitics relating to the
entire class.  For example, compiled sql for retriving particular fields for a class.  Not specific to object.
=cut

__PACKAGE__->mk_classdata( "__ClassData" => {} );

=pod
The local method is for the storage of data particular to an object.  For example, the objects primary retrieval key.
This should be limited to data needed to grab the object out of storage.  For caching object information locally,
please investigate using a local storage engine.
=cut

sub __load_object {
	Cake::Exception::PureVirtual->throw;
}

sub __fetch_object {
	Cake::Exception::PureVirtual->throw;
}

sub __load_index {
	Cake::Exception::PureVirtual->throw;
}

sub __fetch_index {
	Cake::Exception::PureVirtual->throw;
}

sub __load_unique_index {
	Cake::Exception::PureVirtual->throw;
}

sub __fetch_unique_index {
	Cake::Exception::PureVirtual->throw;
}

sub __instantiate {
	return;
}

sub __init {
	return;
}

sub __flush {
		return;
}

sub __setupStorageTraits {
		return;
}

1;
