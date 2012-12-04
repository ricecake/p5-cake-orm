package Cake::Object::Storage::Volatile::Redis;
use base qw(Cake::Object::Storage::Volatile);
use strict;

use Redis;

__PACKAGE__->__engine(__PACKAGE__);

sub __init {
	my $config = __PACKAGE__->_getConfig->fetchAll;


	__PACKAGE__->__driver(Redis->new(%$config));
}

sub __retrieveKey {
	my ($object) = @_;
	$object->_local->{key} ||= do {
		my ( $pkField, $pkValue ) = $self->_pk;
		"$class=$pkValue";
		);
	};
}

sub _create {
	my ($class, $params, $definition ) = @_;
	my $primary = $class->__traitFieldMap()->{primary};
}
sub _search {
	my ($class, $search, $order) = @_;
	my $primary = $class->__traitFieldMap()->{primary};
}
sub _find {
	my ($class, $search) = @_;
	my $primary = $class->__traitFieldMap()->{primary};
}
sub __get_field {
	my ( $class, $self, $traits, $field, $value ) = @_;
	my $objClass = $self->_CLASS;
	my $key = __retrieveKey($self);
	my $r = $class->__driver;

	return $r->hget( $key, $field );
}
sub __set_field {
	my ( $class, $self, $traits, $field, $value ) = @_;
	my $objClass = $self->_CLASS;
	my $key = __retrieveKey($self);
	my $r = $class->__driver;

	if ( $traits->{unique} ) {
		my $oldVal = $self->$field;
		my $index  = "$objClass->$field";
		if ( $r->hsetnx( $index, $value, $key ) ) {
			$r->hdel( $index, $oldVal, sub { } );
			$r->hset( $key, $field, $arg, sub { } );
		}
		else {
			Cake::Exception::ConstraintViolation->throw({contraint => 'unique', field => $field, value => $value});
		}
	}
	elsif ( $traits->{index} ) {
		my $search = "$objClass->$field=$value";
		if ( my $oldVal = $r->hget( $key, $field ) ) {
			my $oldSearch = "$class->$field=$oldVal";
			$r->smove( $oldSearch, $search, $key, sub { } );
		}
		else {
			$r->sadd( $search, $key, sub { } );
		}
		$r->hset( $key, $field, $value, sub { } );
	}
	else {
		$r->hset( $key, $field, $value, sub { } );
	}
	return $self;
}
sub __get_has_a {
	my ($class, $self, $traits, $field, $value) = @_;
	my $primary = $class->__traitFieldMap()->{primary};
}
sub __get_has_many {
	my ($class, $self, $traits, $field, $value) = @_;
	my $primary = $class->__traitFieldMap()->{primary};
}
sub _update {
	my ($invocant, $parameters, $definition, $where) = @_;
	my $primary = $invocant->__traitFieldMap()->{primary};

}
sub _delete {
	my ($invocant, $where) = @_;
	my $primary = $invocant->__traitFieldMap()->{primary};
}

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
	Cake::Exception::PureVirtual->throw;
}


1;
