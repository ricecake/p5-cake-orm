package Cake::Object::Storage::Persistent::DB;
use strict;
use base qw(Cake::Object::Storage::Persistent);

use DBI;
use SQL::Abstract;
use Cake::Object::Storage::Persistent::DB::Resultset;

__PACKAGE__->__engine(__PACKAGE__);

__PACKAGE__->mk_classdata("_table");

my $sql = SQL::Abstract->new;

use Data::Dumper qw(Dumper);

sub __instantiate {
	my ($class, $key) = @_;

	my $object = {};
	bless $object, $class;
	$object->_local->{key} = $key;

	return $object;
}

sub __rectifyOrder {
	my $order = shift;
	if(not ref($order)) {
		$order =~ s/^\s+//;
		$order =~ s/\s+$//;
		$order = "them.$order";
	}
	elsif (ref($order) eq 'HASH') {
		foreach my $value (values %$order) {
			$value = __rectifyOrder($value);
		}
	}
	elsif (ref($order) eq 'ARRAY') {
		foreach my $value (@$order) {
			$value = __rectifyOrder($value);
		}
	}
	return $order;
}

sub _find {
	my ($class, $search) = @_;
	
	my $table = $class->_table;
	my $primary = $class->__traitFieldMap()->{primary};
	
	my ($query, @bind) = $sql->select($table, $primary, $search);
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);

	my ($key)  = $sth->fetchrow_array;
	return unless $key;

	return __instantiate($class, {field => $primary, value => $key});
}

sub _build {
	my ($class, $params, $definition ) = @_;

	my $table = $class->_table;
	my $primary = $class->__traitFieldMap()->{primary};

	my ($query, @bind) = $sql->insert($table, $params, {returning => $primary});
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);

	my ($key)  = $sth->fetchrow_array;
	return unless $key;

	return __instantiate($class, {field => $primary, value => $key});
}

sub _search {
	my ($class, $search, $order) = @_;
	
	my $table = $class->_table;
	my $primary = $class->__traitFieldMap()->{primary};
	
	my ($query, @bind) = $sql->select($table, $primary, $search, $order);
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);

	return Cake::Object::Storage::Persistent::DB::Resultset->create($class, $sth);
}

sub _update {
	my ($invocant, $parameters, $definition, $where) = @_;
	my $table = $invocant->_table;
	$where   ||= {$invocant->_local->{key}{field} => $invocant->_local->{key}{value} };

	my ($query, @bind) = $sql->update($table, $parameters, $where);

	my $sth = $invocant->__driver->prepare($query);
	$sth->execute(@bind);

	if(ref($invocant)) {
		return $invocant;
	}
	else {
		return $sth->rows;
	}
}

sub _delete {
	my ($invocant, $where) = @_;
	my $table = $invocant->_table;
	$where   ||= {$invocant->_local->{key}{field} => $invocant->_local->{key}{value} };

	my ($query, @bind) = ($invocant->_classData->{sql}{delete} ||= $sql->delete($table, $where));
	unless(@bind) {
		@bind = $sql->values($where);
	}

	my $sth = $invocant->__driver->prepare($query);
	$sth->execute(@bind);
	return $sth->rows;
}

#made sure that $class was passed in first, so that inteface and cacher methods can call getter methods on
#the classes that they're targeting, and don't call them on their local classes

sub __get_field {
	my ($class, $self, $traits, $field) = @_;
	my $table = $self->_table;
	my $key   = $self->_local->{key};

	my ($query, @bind) = ($self->_classData->{sql}{get}{$field} ||= $sql->select($table, $field, {$key->{field} => $key->{value}}));
	unless(@bind) {
		@bind = $sql->values({$key->{field} => $key->{value}});
	}
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);
	return $sth->fetchrow_array;
}

sub __set_field {
	my ($class, $self, $traits, $field, $value) = @_;	
	my $table = $self->_table;
	my $key   = $self->_local->{key};
	
	my ($query, @bind) = ($self->_classData->{sql}{set}{$field} ||= $sql->update($table, {$field => $value}, {$key->{field} => $key->{value} } ) );
	unless(@bind) {
		@bind = ($sql->values({$field => $value}), $sql->values({$key->{field} => $key->{value}}));
	}
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);
	
	return $self;
}

sub __get_has_a {
	my ($class, $self, $traits, $field) = @_;
	my ($myField, $otherClass, $otherField) = @{$traits};
	
	eval "require $otherClass";
	
	my $myTable    = $self->_table;
	my $otherTable = $otherClass->_table;
	my $otherPK    = $otherClass->__traitFieldMap()->{primary};
	
	my $key   = $self->_local->{key};
	
	my ($query, @bind) = ($self->_classData->{sql}{has_a}{$field} ||= $sql->select(
							["$myTable me", "$otherTable them"], "them.$otherPK",
							{
								"me.$key->{field}" => "me.$key->{value}",
								"them.$otherField" => {-ident => "me.$myField"}
							})
						  );
	unless(@bind) {
		@bind = $sql->values({$key->{field} => $key->{value}});
	}
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);
	
	my $result = $sth->fetchrow_arrayref;
	if($result) {
		return __instantiate($otherClass,
				{ field => $otherPK, value => $result->[0] });
	}
	return;
}

sub __get_has_many {
	my ($class, $self, $traits, $field, $order) = @_;
	my ($myField, $otherClass, $otherField) = @{$traits};
	
	$order = __rectifyOrder($order);

	eval "require $otherClass";
	
	my $myTable    = $self->_table;
	my $otherTable = $otherClass->_table;
	my $otherPK    = $otherClass->__traitFieldMap()->{primary};
	
	my $key   = $self->_local->{key};

	my ($query, @bind) = ($self->_classData->{sql}{has_many}{$field} ||= $sql->select(
							["$myTable me", "$otherTable them"], "them.$otherPK",
							{
								"me.$key->{field}" => "me.$key->{value}",
								"them.$otherField" => {-ident => "me.$myField"}
							}, $order )
						  );
	unless(@bind) {
		@bind = $sql->values({$key->{field} => $key->{value}});
	}
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);
	return Cake::Object::Storage::Persistent::DB::Resultset->create($otherClass, $sth);
}



sub __load_object {
	Cake::Exception::PureVirtual->throw;
}

sub __fetch_object {
	Cake::Exception::PureVirtual->throw;
}

sub __fetch_index {
	Cake::Exception::PureVirtual->throw;
}

sub __fetch_unique_index {
	Cake::Exception::PureVirtual->throw;
}

1;