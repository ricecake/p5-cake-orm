package Cake::Object::Storage::Volatile::Redis;
use base qw(Cake::Object::Storage::Volatile);
use Cake::Object::Storage::Volatile::Redis::Resultset;
use strict;

use Redis;

__PACKAGE__->__engine(__PACKAGE__);

sub __init {
	my ($class) = @_;
	my $config = __PACKAGE__->_getConfig->fetchAll;

	__PACKAGE__->__driver(Redis->new(%$config));
	__PACKAGE__->__driver()->select(1);
	$class->_registerInitCallback(__PACKAGE__->can('__instantiate'));
}

sub __instantiate {
	my ($object) = @_;
	my $class = $object->_CLASS;
	$object->_local->{key} ||= do {
		my ( $pkField, $pkValue ) = %{$object->_pk};
		"$class=$pkValue";
	};
	$object->_local->{test} = "REDIS";
	return;
}

sub _create {
	my ($class, $invocant, $params, $definition ) = @_;
	my $primary = $class->__traitFieldMap()->{primary};
}
sub _search {
	my ($class, $invocant, $search, $order) = @_;
	my $primary = $class->__traitFieldMap()->{primary};
}
sub _find {
	my ($class, $invocant, $search) = @_;
	my $primary = $invocant->__traitFieldMap()->{primary};
	my $r = $class->__driver;
	my $objClass = $invocant->_CLASS;

	my %options;
	if(ref($search) eq 'HASH') {
		%options = %$search;
	}
	elsif(ref($search) eq 'ARRAY') {
		%options = @$search;
	}
	else {
		return;
	}
	
	use Data::Dumper qw(Dumper);
	if (exists $options{$primary}) {
		my $key = "$objClass=" . $options{$primary};
		if($r->exists($key)) {
			return $invocant->_build({$primary => $options{$primary}})
		}
	}
	foreach my $field (keys %options) {
		my $value  = $options{$field};
		my $index  = "$objClass->$field";

		if(my $key = $r->hget($index, $value)) {
			my ($pkValue) = $key =~ /=(.+)$/;
			return $invocant->_build({$primary => $pkValue})
		}
	}
	return;
}
sub __get_field {
	my ( $class, $self, $traits, $field, $value ) = @_;
	my $objClass = $self->_CLASS;
	my $key = $self->_local->{key};
	my $r = $class->__driver;

	return $r->hget( $key, $field );
}
sub __set_field {
	my ( $class, $self, $traits, $field, $value ) = @_;
	my $objClass = $self->_CLASS;
	my $key = $self->_local->{key};
	my $r = $class->__driver;

	if ( $traits->{unique} ) {
		my $oldVal = $self->$field;
		my $index  = "$objClass->$field";
		if ( $r->hsetnx( $index, $value, $key ) ) {
			$r->hdel( $index, $oldVal, sub { } );
			$r->hset( $key, $field, $value, sub { } );
		}
		else {
			Cake::Exception::ConstraintViolation->throw({contraint => 'unique', field => $field, value => $value});
		}
	}
	elsif ( $traits->{index} ) {
		my $search = "$objClass->$field=$value";
		if ( my $oldVal = $r->hget( $key, $field ) ) {
			my $oldSearch = "$objClass->$field=$oldVal";
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
	my ($myField, $otherClass, $otherField) = @{$traits};

	my $objClass = $self->_CLASS;
	my $key = $self->_local->{key};
	my $r = $class->__driver;

	my $fieldValue  = $self->$myField;
	my $remoteIndex = "$otherClass->$otherField";
	return $otherClass->find({$otherField => $fieldValue});


}
sub __get_has_many {
	my ($class, $self, $traits, $field, $value) = @_;
	my ($myField, $otherClass, $otherField) = @{$traits};
	my $r = $class->__driver;

	my $value = $self->$myField;
	my $index = "$otherClass->$otherField=$value";
	return unless $r->exists($index);
	return Cake::Object::Storage::Volatile::Redis::Resultset->createFromSet($index, $r);
}
sub _update {
	my ($class, $invocant, $parameters, $definition, $where) = @_;
	my $primary = $invocant->__traitFieldMap()->{primary};

}
sub _delete {
	my ($class, $invocant, $where) = @_;
	my $primary = $invocant->__traitFieldMap()->{primary};
}

sub __load_object {
	my ($class, $object, $data) = @_;
	my $objClass = $object->_CLASS;
	my $key = $object->_local->{key};
	my $r = $class->__driver;

	my %traitMap = %{ $object->__traitFieldMap() };

	foreach my $field (@{ $traitMap{unique} }) {
		my $uniqIndex = "$objClass->$field";
		$r->hset($uniqIndex, $data->{$field}, $key, sub{});
	}
	foreach my $field (@{ $traitMap{index} }) {
		my $value = $data->{$field};
		my $index = "$objClass->$field=$value";
		$r->sadd($index, $key, sub{});
	}
	$r->hmset($key, %{$data});
	return $object;
}

sub __fetch_object {
	my ($class, $invocant, $search) = @_;
	my $primary = $invocant->__traitFieldMap()->{primary};
	my $r = $class->__driver;
	my $objClass = $invocant->_CLASS;

	my %options;
	if(ref($search) eq 'HASH') {
		%options = %$search;
	}
	elsif(ref($search) eq 'ARRAY') {
		%options = @$search;
	}
	else {
		return;
	}
	
	if (exists $options{$primary}) {
		my $key = "$objClass=" . $options{$primary};
		if($r->exists($key)) {
			return ($invocant->_build({$primary => $options{$primary}}), {$r->hgetall($key)});
		}
	}
	foreach my $field (keys %options) {
		my $value  = $options{$field};
		my $index  = "$objClass->$field";

		if(my $key = $r->hget($index, $value)) {
			my ($pkValue) = $key =~ /=(.+)$/;
			return ($invocant->_build({$primary => $pkValue}), {$r->hgetall($key)})
		}
	}
	return;
}

sub __load_index {
	my ($class, $self, $traits, $field, $data) = @_;
	my ($myField, $otherClass, $otherField) = @{$traits};
	my $r = $class->__driver;

	my $value = $self->$myField;
	my $index = "$otherClass->$otherField=$value";
	my @keys = map { "$otherClass=$_" } @{$data};

	return $r->sadd($index, @keys);
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

sub _asHashRef {
	my ($class, $object) = @_;
	my $r = $class->__driver;
	my $key = $object->_local->{key};
	my @data = $r->hgetall($key);
	return unless @data;
	return {@data};

}

1;
