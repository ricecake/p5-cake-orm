package Cake::Object::CDS::Flex;
use base qw(Cake::Object::CDS);
use strict;

__PACKAGE__->mk_classdata('__memoStore');
__PACKAGE__->mk_classdata('__objectStore'=>[]);
__PACKAGE__->mk_classdata('__relationStore'=>[]);
__PACKAGE__->mk_classdata('__searchStore'=>[]);
__PACKAGE__->mk_classdata('__canonicalStore');

my @all;
my @find;
my @create;
my @relations;
my @update;
my @delete;
my @search;

sub __init {
	my ($class) = @_;
	{
		@all = (
			$class->__memoStore,
			@{$class->__objectStore},
			@{$class->__relationStore},
			@{$class->__searchStore},
			$class->__canonicalStore,
		);

		@find = (
			@{$class->__objectStore},
			@{$class->__relationStore},
			@{$class->__searchStore},
			$class->__canonicalStore,
		);

		@create= (
			@{$class->__searchStore},
			@{$class->__relationStore},
			@{$class->__objectStore},
			$class->__memoStore,
		);

		@relations= (
			@{$class->__relationStore},
			@{$class->__searchStore},
			$class->__canonicalStore,
		);

		@update= (
			$class->__canonicalStore,
			@{$class->__searchStore},
			@{$class->__relationStore},
			@{$class->__objectStore},
			$class->__memoStore,
		);

		@delete= (
			$class->__canonicalStore,
			@{$class->__searchStore},
			@{$class->__relationStore},
			@{$class->__objectStore},
			$class->__memoStore,
		);

		@search= (
			@{$class->__searchStore},
			$class->__canonicalStore,
		);

		map { $_->__init($class) } @all;
		map { $class->_installPostSetupActions($_->__setupStorageTraits($class)) } @all;
	}
}

sub asHashRef {
	my $self = shift;
	return $self->__memoStore->_asHashRef($self);
}
sub _find {
	my ($class, $invocant, $search) = @_;
	my @misses;
	foreach my $engine (@find) {
		my ($object, $data) = $engine->__fetch_object($invocant, $search);
		if($object) {
			$object->{sunk} = 1;
			$object->{found} = $engine;
			if (@misses) {
				foreach my $miss (@misses) {
					$miss->__load_object($object,$data);
					$miss->__flush;
				}
			}
			return $class->__memoStore->__load_object($object,$data);
		}
		else {
			unshift(@misses,$engine);
		}
	}
	return;
}
sub __get_field {
	my ($class, $self, $traits, $field) = @_;
	$self->_sync unless $self->{sunk};
	return $class->__memoStore->__get_field($self, $traits, $field);
}
sub __set_field {
	my ( $class, $self, $traits, $field, $value ) = @_;
	return $self if $value eq $self->$field;
	
	foreach my $engine (@update) {
		$engine->__set_field($self, $traits, $field, $value);
		$engine->__flush;
	}
	return $self;
}
sub __get_has_a {
	my ($class, $self, $traits, $field) = @_;
	my ($myField, $otherClass, $otherField) = @{$traits};

	$self->_sync unless $self->{sunk};
	my @misses;

	foreach my $engine (@relations) {
		my $rs = $engine->__get_has_a($self, $traits, $field);
		if(defined $rs) {
			if (@misses) {
				my $data = $engine->__fetch_unique_index($otherClass, $otherField);
				foreach my $miss (@misses) {
					$miss->__load_unique_index($otherClass, $otherField, $data);
					$miss->__flush;
				}
			}
			return $rs;
		}
		else {
			unshift(@misses,$engine);
		}
	}
	return;
}
sub __get_has_many {
	my ($class, $self, $traits, $field, $order, $options) = @_;
	my ($myField, $otherClass, $otherField) = @{$traits};

	$self->_sync unless $self->{sunk};
	my @misses;
	my $value = $self->$myField;
	foreach my $engine (@relations) {
		my $rs = $engine->__get_has_many($self, $traits, $field, $order, $options);
		if(defined $rs) {
			if (@misses) {
				my $data = $engine->__fetch_index($otherClass, $otherField, $value);
				foreach my $miss (@misses) {
					$miss->__load_index($otherClass, $otherField, $value, $data);
					$miss->__flush;
				}
			}
			return $rs;
		}
		else {
			unshift(@misses,$engine);
		}
	}
	return;
}
sub _create {
	my ($class, $invocant, $params, $definition ) = @_;
	
	my $object = $invocant->__canonicalStore->_create($invocant, $params, $definition);
	my $data = $invocant->__canonicalStore->_asHashRef($object);
	
	foreach my $engine (@create) {
		$engine->__load_object($object,$data);
		$engine->__flush;
	}

	return $object;
}
sub _update {
	my ($class, $invocant, $params, $definition, $where) = @_;
	Cake::Exception::NotSupported->throw({action => 'class level update'}) if defined $where;
	
	my $object = $invocant->__canonicalStore->_update($invocant, $params, $definition);
	
	foreach my $engine (@create) {
		$engine->_update($object, $params, $definition);
		$engine->__flush;
	}
	return $invocant;
}
sub _delete {
	my ($class, $invocant, $where) = @_;
	Cake::Exception::NotSupported->throw({action => 'class level update'}) if defined $where;
	foreach my $engine (@delete) {
		$engine->_delete($invocant);
		$engine->__flush;
	}
	return 1;
}
sub _search {
	my ($class, $invocant, $search, $order, $options) = @_;

	foreach my $engine (@search) {
		my $resultset = $engine->_search($invocant, $search, $order, $options);
		return $resultset if defined($resultset);
	}
}
sub _sync {
	my ($object) = @_;
	my @misses;
		
	foreach my $engine (@find) {
		my $data = $engine->_asHashRef($object);
		if(ref($data)) {
			$object->{found} = $engine;
			$object->{sunk} = 1;
			foreach my $miss (@misses) {
				$miss->__load_object($object,$data);
				$miss->__flush;
			}
			return $object->__memoStore->__load_object($object,$data);
		}
		else {
			unshift(@misses,$engine);
		}
	}
	return;
}

sub _rebuild {
	my ($object, $engine, $field) = @_;
	my $class = $object->_CLASS;
	if($object->__fieldTraitMap->{$field}{unique}) {
		my $data = $object->__canonicalStore->__fetch_unique_index($class, $field);
		$engine->__load_unique_index($class, $field, $data);
		$engine->__flush;
	}
	elsif ($object->__fieldTraitMap->{$field}{index}) {
		my $fieldValue = $object->$field;
		my $data = $object->__canonicalStore->__fetch_index($class, $field, $fieldValue);
		$engine->__load_index($class, $field, $fieldValue, $data);
		$engine->__flush;
	}
}

1;

