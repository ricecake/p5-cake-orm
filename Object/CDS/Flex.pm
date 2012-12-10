package Cake::Object::CDS::Flex;
use base qw(Cake::Object::CDS);
use strict;

__PACKAGE__->mk_classdata('__memoStore');
__PACKAGE__->mk_classdata('__objectStore'=>[]);
__PACKAGE__->mk_classdata('__relationStore'=>[]);
__PACKAGE__->mk_classdata('__searchStore'=>[]);
__PACKAGE__->mk_classdata('__canonicalStore');

my @find;
my @create;
my @relations;
my @update;
my @delete;
my @search;

sub __init {
	my ($class) = @_;
	{
		no strict qw(refs);
		map { &{"${_}::__init"}($class) } (
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
			$class->__canonicalStore,
			@{$class->__searchStore},
			@{$class->__relationStore},
			@{$class->__objectStore},
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
		);

		@search= (
			@{$class->__searchStore},
			$class->__canonicalStore,
		);
	}
}

sub asHashRef {
	my $self = shift;
	return $self->__memoStore->asHashRef;
}
sub _find {
	my ($class, $invocant, $search) = @_;
	my @misses;
	foreach my $engine (@find) {
		my ($object, $data) = $engine->__fetch_object($invocant, $search);
		if($object) {
			if (@misses) {
				foreach my $miss (@misses) {
					$miss->__load_object($object,$data);
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
	return $class->__memoStore->__get_field($self, $traits, $field);
}
sub __set_field {
	Cake::Exception::PureVirtual->throw;
}
sub __get_has_a {
	Cake::Exception::PureVirtual->throw;
}
sub __get_has_many {
	my ($class, $self, $traits, $field, $order) = @_;
	my ($myField, $otherClass, $otherField) = @{$traits};

	my @misses;
	foreach my $engine (@relations) {
		my $rs = $engine->__get_has_many($self, $traits, $field, $order);
		if(defined $rs) {
			if (@misses) {
				my $data = $engine->__fetch_index($self, $traits, $field);
				foreach my $miss (@misses) {
					$miss->__load_index($self, $traits, $field, $data);
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
	Cake::Exception::PureVirtual->throw;	
}
sub _update {
	Cake::Exception::PureVirtual->throw;
}
sub _delete {
	Cake::Exception::PureVirtual->throw;
}
sub _search {
	Cake::Exception::PureVirtual->throw;
}
sub _sync {
	my ($object) = @_;
	my @misses;
	foreach my $engine (@find) {
		my $data = $engine->_asHashRef($object);
		if($data) {
			foreach my $miss (@misses) {
				$miss->__load_object($object,$data);
			}
			return $object->__memoStore->__load_object($object,$data);
		}
		else {
			unshift(@misses,$engine);
		}

	}
	return;
}


1;

