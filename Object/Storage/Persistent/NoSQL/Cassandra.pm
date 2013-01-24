package Cake::Object::Storage::Persistent::NoSQL::Cassandra;
use strict;
use base qw(Cake::Object::Storage::Persistent::NoSQL);

use Cake::Object::Storage::Persistent::NoSQL::Cassandra::Resultset;

use Cassandra::Simple;

__PACKAGE__->__engine(__PACKAGE__);

sub __init {
	my ($self, $class) = @_;
	my $config = $class->_getConfig->fetchAll;
	
	__PACKAGE__->__driver(Cassandra::Simple->new(%$config));
	
	$class->_registerInitCallback(__PACKAGE__->can('__instantiate'));
	$self->SUPER::__init($class);
}

sub __setupStorageTraits {
	my ($class) = @_;
	return sub {
		my ($objClass) = shift;
		my $columnFamily = $objClass;
		$columnFamily =~ s/::/_/g;
		$objClass->_classData->{columnFamily} = $columnFamily;

		unless ( grep { $_ eq $columnFamily } @{ $class->__driver->list_keyspace_cfs() } ) {
			my @indexColumns;
			my $traitMap = $objClass->__traitFieldMap;

			foreach my $type (qw(index unique)) {
				next unless exists $traitMap->{$type};
				push(@indexColumns, @{$traitMap->{$type}})
			}
			push(@indexColumns, $traitMap->{primary});

			$class->__driver->create_column_family(
				column_family            => $columnFamily,
				comparator_type          => 'UTF8Type',
				key_validation_class     => 'UTF8Type',
				default_validation_class => 'UTF8Type',
			);
			$class->__driver->create_index(
				column_family    => $columnFamily,
				columns          => \@indexColumns,
			);
		}
	}
}

sub __instantiate {
	my ($object) = @_;
	$object->_local->{key} ||= do {
		my ( $pkField, $pkValue ) = %{$object->_pk};
		$pkValue;
	};
	return;
}

sub __exists {
	my ($class, $objClass, $key) = @_;
	my $conn = $class->__driver;
	my $result = $conn->get(
		column_family => $objClass->_classData->{columnFamily},
		key => $key,
	);
	return (scalar keys %$result, $result);
}

sub __uniqExists {
	my ($class, $objClass, $field, $value) = @_;
	my $conn = $class->__driver;
	my $result = $conn->get_indexed_slices(
		column_family => $objClass->_classData->{columnFamily},
		expression_list => [ [ $field, $value ] ]
	);
	return (scalar keys %$result, values %$result);
}

sub _find {
	my ($class, $invocant, $search) = @_;
	my $primary = $invocant->__traitFieldMap()->{primary};
	my $conn = $class->__driver;
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
		my $key = $options{$primary};
		my ($exists, $data) = $class->__exists($invocant, $key);
		if($exists) {
			return $invocant->_build({$primary => $key});
		}
	}
	foreach my $field (keys %options) {
		my $value  = $options{$field};
		my ($exists, $data) = $class->__uniqExists($invocant, $field, $value);
		if($exists) {
			return $invocant->_build({$primary => $data->{$primary}});
		}
	}
	return;
}

sub __fetch_object {
	my ($class, $invocant, $search) = @_;
	my $primary = $invocant->__traitFieldMap()->{primary};
	my $conn = $class->__driver;
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
		my $key = $options{$primary};
		my ($exists, $data) = $class->__exists($invocant, $key);
		if($exists) {
			delete $data->{__SENTINEL__};
			return ($invocant->_build({$primary => $key}), $data);
		}
	}
	foreach my $field (keys %options) {
		my $value  = $options{$field};
		my ($exists, $data) = $class->__uniqExists($invocant, $field, $value);
		if($exists) {
			delete $data->{__SENTINEL__};
			return ($invocant->_build({$primary => $data->{$primary}}), $data);
		}
	}
	return;
}

sub __get_has_a {
	my ($class, $self, $traits, $field, $value) = @_;
	my ($myField, $otherClass, $otherField) = @{$traits};

	my $fieldValue  = $self->$myField;
	return $otherClass->find({$otherField => $fieldValue});
}

sub __get_has_many {
	my ($class, $self, $traits, $field, $order, $options) = @_;
	my ($myField, $otherClass, $otherField) = @{$traits};
	my $conn = $class->__driver;

	my $value = $self->$myField;
	
	my $result = $conn->get_indexed_slices(
		column_family => $otherClass->_classData->{columnFamily},
		expression_list => [ [ $otherField, $value ] ]
	);
	my $rs = Cake::Object::Storage::Persistent::NoSQL::Cassandra::Resultset->create($otherClass, $result);
	if($order) {
		$rs->sort($order, $options);
	}
	return $rs;

}

sub __load_object {
	my ($class, $object, $data) = @_;
	my $objClass = $object->_CLASS;
	my $key = $object->_local->{key};
	my $columnFamily = $objClass->_classData->{columnFamily};
	my $conn = $class->__driver;
	
	$data->{__SENTINEL__} = '__SENTINEL__';
print 1;
	while(my ($field, $value)=each %$data) {
		if(not defined $data->{$field}) {
			delete $data->{$field};
		}
	}
	$conn->insert(
		column_family => $columnFamily,
		key           => $key,
		columns       => $data,
	);
	return $object;
}

sub _asHashRef {
	my ($class, $object) = @_;
	my $conn = $class->__driver;
	my $key = $object->_local->{key};
	my $data = $conn->get(
		column_family => $object->_classData->{columnFamily},
		key => $key,
	) or return;
	return unless scalar keys %$data;
	delete $data->{__SENTINEL__};
	return $data;

}

sub __load_index {
	my ($class, $otherClass, $otherField, $value, $data) = @_;
	return 1;
}
sub __load_unique_index {
	my ($class, $otherClass, $otherField, $data) = @_;
	return 1;
}

sub __set_field {
	my ( $class, $object, $traits, $field, $value ) = @_;
	my $objClass = $object->_CLASS;
	my $key = $object->_local->{key};
	my $columnFamily = $objClass->_classData->{columnFamily};
	my $conn = $class->__driver;
	
	$conn->insert(
		column_family => $columnFamily,
		key           => $key,
		columns       => { $field => $value },
	);
	return $object;
}

sub __fetch_unique_index {
	my ($class, $searchClass, $field) = @_;
	my $conn = $class->__driver;
	
	my $result = $conn->get_indexed_slices(
		column_family => $searchClass->_classData->{columnFamily},
		expression_list => [ [ '__SENTINEL__', '__SENTINEL__' ] ]
	);
	
	my %buffer = map { $result->{$_}{$field} => $_ } keys %$result;
	return [map {[ $_ => $buffer{$_} ]} keys %buffer];
}

sub __fetch_index {
	my ($class, $otherClass, $field, $value) = @_;

	my $conn = $class->__driver;
	print Dumper(["1asdfsafd", $field, $value]);
	my $result = $conn->get_indexed_slices(
		column_family => $otherClass->_classData->{columnFamily},
		expression_list => [ [ $field, $value ] ]
	);
	
	return [keys %$result];
}

sub _update {
	my ($class, $self, $parameters, $definition, $where) = @_;
	my $objClass = $self->_CLASS;
	my $key = $self->_local->{key};
	my $columnFamily = $objClass->_classData->{columnFamily};
	my $conn = $class->__driver;
	
	$conn->insert(
		column_family => $columnFamily,
		key           => $key,
		columns       => $parameters,
	);
	return $self;
}

sub _delete {
	my ($class, $self, $where) = @_;
	my $objClass = $self->_CLASS;
	my $key = $self->_local->{key};
	my $columnFamily = $objClass->_classData->{columnFamily};
	my $conn = $class->__driver;
	
	$conn->remove(
		column_family => $columnFamily,
		keys        => [$key],
	);
	return 1;
}

1;
