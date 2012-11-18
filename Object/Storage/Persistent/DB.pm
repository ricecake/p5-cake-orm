package Cake::Object::Storage::Persistent::DB;
use base qw(Cake::Object::Persistent);

use DBI;
use SQL::Abstract;

__PACKAGE__->mk_classdata( "_table");

sub __get_field {
	Cake::Exception::PureVirtual->throw;
}

sub __set_field {
	Cake::Exception::PureVirtual->throw;
}

sub __get_has_a {
	Cake::Exception::PureVirtual->throw;
}

sub __set_has_a {
	Cake::Exception::PureVirtual->throw;
}

sub __get_has_many {
	Cake::Exception::PureVirtual->throw;
}

sub __load {
	Cake::Exception::PureVirtual->throw;
}

sub __fetch {
	Cake::Exception::PureVirtual->throw;
}

1;