package Cake::Object::Storage::Persistent::DB;
use strict;
use base qw(Cake::Object::Storage::Persistent);

use DBI;
use SQL::Abstract;
use Cake::Object::Storage::Persistent::DB::Resultset;

__PACKAGE__->__engine(__PACKAGE__);



my $sql = SQL::Abstract->new;

sub __instantiate {
	my ($object) = @_;
	$object->_local->{test} = "POSTGRES";
	return;
}


sub __rectifyOrder {
	my $order = shift;
	return unless $order;
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
	my ($class, $invocant, $search) = @_;
	
	my $table = $invocant->_table;
	my $primary = $invocant->__traitFieldMap()->{primary};
	
	my ($query, @bind) = $sql->select($table, $primary, $search);
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);

	my ($key)  = $sth->fetchrow_array;
	return unless $key;

	return $invocant->_build({$primary => $key});
}

sub _create {
	my ($class, $invocant, $params, $definition ) = @_;

	my $table = $invocant->_table;
	my $primary = $invocant->__traitFieldMap()->{primary};

	my ($query, @bind) = $sql->insert($table, $params, {returning => $primary});
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);

	my ($key)  = $sth->fetchrow_array;
	return unless $key;

	return $invocant->_build({$primary => $key});
}

sub _search {
	my ($class, $invocant, $search, $order) = @_;
	
	my $table = $invocant->_table;
	my $primary = $invocant->__traitFieldMap()->{primary};
	
	my ($query, @bind) = $sql->select($table, $primary, $search, $order);
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);

	return Cake::Object::Storage::Persistent::DB::Resultset->create($invocant, $sth);
}

sub _update {
	my ($class, $invocant, $parameters, $definition, $where) = @_;
	my $table = $invocant->_table;
	$where   ||= {$invocant->_local->{key}{field} => $invocant->_local->{key}{value} };

	my ($query, @bind) = $sql->update($table, $parameters, $where);

	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);

	if(ref($invocant)) {
		return $invocant;
	}
	else {
		return $sth->rows;
	}
}

sub _delete {
	my ($class, $invocant, $where) = @_;
	my $table = $invocant->_table;
	$where   ||= $invocant->_pk;

	my ($query, @bind) = ($invocant->_classData->{sql}{delete} ||= $sql->delete($table, $where));
	unless(@bind) {
		@bind = $sql->values($where);
	}

	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);
	return $sth->rows;
}

#made sure that $class was passed in first, so that inteface and cacher methods can call getter methods on
#the classes that they're targeting, and don't call them on their local classes
#need to back up, and make sure that all methods take params in form of engine, domain/thing, method specific args

sub __get_field {
	my ($class, $self, $traits, $field) = @_;
	my $table = $self->_table;
	my $key   = $self->_pk;

	my ($query, @bind) = ($self->_classData->{sql}{get}{$field} ||= $sql->select($table, $field, $key));
	unless(@bind) {
		@bind = $sql->values($key);
	}
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);
	return $sth->fetchrow_array;
}

sub __set_field {
	my ($class, $self, $traits, $field, $value) = @_;	
	my $table = $self->_table;
	my $key   = $self->_pk;
	
	my ($query, @bind) = ($self->_classData->{sql}{set}{$field} ||= $sql->update($table, {$field => $value}, $key ) );
	unless(@bind) {
		@bind = $sql->values($key);
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
	
	my $key   = $self->_pk;
	my ($field, $value) = %{$key};
	
	my ( $query, @bind ) = (
		$self->_classData->{sql}{has_a}{$field} ||= $sql->select(
			[ "$myTable me", "$otherTable them" ],
			"them.$otherPK",
			{
				"me.$field"        => $value,
				"them.$otherField" => { -ident => "me.$myField" }
			}
		)
	);

	unless(@bind) {
		@bind = $sql->values({$key->{field} => $key->{value}});
	}
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);
	
	my $result = $sth->fetchrow_arrayref;
	if($result) {
		return $otherClass->_build({$otherPK => $result->[0] });
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
	
	my $key   = $self->_pk;
	my ($field, $value) = %{$key};
	
	my ( $query, @bind ) = (
		$self->_classData->{sql}{has_many}{$field} ||= $sql->select(
			[ "$myTable me", "$otherTable them" ],
			"them.$otherPK",
			{
				"me.$field"        => $value,
				"them.$otherField" => { -ident => "me.$myField" }
			},
			$order
		)
	);

	unless(@bind) {
		@bind = $sql->values($key);
	}
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);
	return Cake::Object::Storage::Persistent::DB::Resultset->create($otherClass, $sth);
}



sub __load_object {
	Cake::Exception::PureVirtual->throw;
}

sub __fetch_object {
	my ($class, $invocant, $search) = @_;
	
	my $table = $invocant->_table;
	my $primary = $invocant->__traitFieldMap()->{primary};
	
	my ($query, @bind) = $sql->select($table, [ keys %{$invocant->__fieldTraitMap()} ], $search);
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);
	my $data = $sth->fetchrow_hashref;
	
	return unless $data;
	return ($invocant->_build({$primary => $data->{$primary}}), $data);
}

sub __fetch_index {
	my ($class, $self, $traits, $field, $order) = @_;
	my ($myField, $otherClass, $otherField) = @{$traits};
	
	$order = __rectifyOrder($order);

	eval "require $otherClass";
	
	my $myTable    = $self->_table;
	my $otherTable = $otherClass->_table;
	my $otherPK    = $otherClass->__traitFieldMap()->{primary};
	
	my $key   = $self->_pk;
	my ($field, $value) = %{$key};
	
	my ( $query, @bind ) = (
		$self->_classData->{sql}{has_many}{$field} ||= $sql->select(
			[ "$myTable me", "$otherTable them" ],
			"them.$otherPK",
			{
				"me.$field"        => $value,
				"them.$otherField" => { -ident => "me.$myField" }
			},
			$order
		)
	);

	unless(@bind) {
		@bind = $sql->values($key);
	}
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);
	return  [ map { @{$_} } @{$sth->fetchall_arrayref} ];
}

sub __fetch_unique_index {
	Cake::Exception::PureVirtual->throw;
}

sub _asHashRef {
	my ($class, $object) = @_;
	my $table = $object->_table;
	my $primary = $object->__traitFieldMap()->{primary};
	
	my ($query, @bind) = $sql->select($table, [ keys %{$object->__fieldTraitMap()} ], $object->_pk);
	my $sth = $class->__driver->prepare($query);
	$sth->execute(@bind);
	my $data = $sth->fetchrow_hashref;
	
	return unless $data;
	return $data;
}


1;
