package Cake::Object::Storage::Volatile::Redis;
use base qw(Cake::Object::Storage::Volatile);
use Cake::Object::Storage::Volatile::Redis::Resultset;
use strict;

use Redis;

__PACKAGE__->__engine(__PACKAGE__);

sub __init {
	my ($self, $class) = @_;
	my $config = $class->_getConfig->fetchAll;

	__PACKAGE__->__driver(Redis->new(%$config));
	__PACKAGE__->__driver()->select(2);
	$class->_registerInitCallback(__PACKAGE__->can('__instantiate'));
}

sub __instantiate {
	my ($object) = @_;
	my $class = $object->_CLASS;
	$object->_local->{key} ||= do {
		my ( $pkField, $pkValue ) = %{$object->_pk};
		"$class=$pkValue";
	};
	return;
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
		$self->_rebuild($class, $field) unless $r->exists($index);
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
		$self->_rebuild($class, $field) unless $r->exists($search);
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
	return $otherClass->find({$otherField => $fieldValue});
}

sub __get_has_many {
	my ($class, $self, $traits, $field, $order, $options) = @_;
	my ($myField, $otherClass, $otherField) = @{$traits};
	my $r = $class->__driver;

	my $value = $self->$myField;
	my $index = "$otherClass->$otherField=$value";
	return unless $r->exists($index);
	if($order) {
		my $rs = Cake::Object::Storage::Volatile::Redis::Resultset->createFromSet($index, $r);
		return $rs->sort($order, $options);
	}
	return Cake::Object::Storage::Volatile::Redis::Resultset->createFromSet($index, $r);
}

sub _delete {
	my ($class, $self, $where) = @_;
	my $objClass = $self->_CLASS;
	my $definition = $self->__fieldTraitMap();
	my $key = $self->_local->{key};
	my $r = $class->__driver;
	my %values = %{$self->asHashRef};

	while (my ($field, $traits) = each %$definition) {
		my $oldVal = $values{$field};
		if ( $traits->{unique} ) {
			my $index  = "$objClass->$field";
			$r->hdel( $index, $oldVal, sub { } );
		}
		elsif ( $traits->{index} ) {
			my $oldSearch = "$objClass->$field=$oldVal";
			$r->srem( $oldSearch, $key, sub { } );
		}
	}
	$r->del( $key, sub{} );
	return 1;

}

sub _update {
	my ($class, $self, $parameters, $definition, $where) = @_;
	my $objClass = $self->_CLASS;
	my $key = $self->_local->{key};
	my $r = $class->__driver;

	my $value;
	my $oldVal;
	while (my ($field, $traits) = each %$definition) {
		next unless exists $parameters->{$field};

		if ( $traits->{unique} ) {
			$value = $parameters->{$field};
			$oldVal = $self->$field;
			my $index  = "$objClass->$field";
			$self->_rebuild($class, $field) unless $r->exists($index);
			$r->hdel( $index, $oldVal, sub { } );
			$r->hset( $index, $value, $key, sub{} );
		}
		elsif ( $traits->{index} ) {
			my $search = "$objClass->$field=$value";
			my $oldSearch = "$objClass->$field=$oldVal";
			$self->_rebuild($class, $field) unless $r->exists($search);
			$r->srem( $oldSearch, $key, sub { } );
			$r->sadd( $search,    $key, sub { } );
		}
	}
	$r->hmset( $key, %{$parameters}, sub{});
	return $self;
}

sub __load_object {
	my ($class, $object, $data) = @_;
	my $objClass = $object->_CLASS;
	my $key = $object->_local->{key};
	my $r = $class->__driver;

	my %traitMap = %{ $object->__traitFieldMap() };

	foreach my $field (@{ $traitMap{unique} }) {
		my $uniqIndex = "$objClass->$field";
		my $value = $data->{$field};
		$object->_rebuild($class, $field) unless $r->exists($uniqIndex);
		$r->hset($uniqIndex, $value, $key, sub {});
	}
	foreach my $field (@{ $traitMap{index} }) {
		my $value = $data->{$field};
		my $index = "$objClass->$field=$value";
		$object->_rebuild($class, $field) unless $r->exists($index);
		$r->sadd($index, $key, sub{});
	}
	my %update = %{$data};
	foreach my $key (keys %update) {
		delete $update{$key} unless defined $update{$key};
	}
	$r->hmset($key, %update);
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
	my ($class, $otherClass, $otherField, $value, $data) = @_;
	my $r = $class->__driver;

	my $index = "$otherClass->$otherField=$value";
	my @keys = map { "$otherClass=$_" } @{$data};

	$r->del($index, sub{});
	return $r->sadd($index, @keys, sub{});
}

sub __fetch_index {
	Cake::Exception::PureVirtual->throw;
}

sub __load_unique_index {
	my ($class, $otherClass, $otherField, $data) = @_;

	my $r = $class->__driver;

	my $index = "$otherClass->$otherField";
	my @keys = map { $_->[0] => "$otherClass=".$_->[1] } @{$data};

	$r->del($index, sub{});
	return $r->hmset($index, @keys, sub{});
}

sub __fetch_unique_index {
	Cake::Exception::PureVirtual->throw;
}

sub _asHashRef {
	my ($class, $object) = @_;
	my $r = $class->__driver;
	my $key = $object->_local->{key};
	my @data = $r->hgetall($key) or return;
	return unless scalar @data;
	return {@data};

}

sub __flush {
	my ($class) = @_;
	$class->__driver->wait_all_responses;
}

1;
