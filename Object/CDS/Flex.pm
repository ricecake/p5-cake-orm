package Cake::Object::CDS::Flex;
use base qw(Cake::Object::CDS);
use strict;

__PACKAGE__->mk_classdata('__canonicalStore');
__PACKAGE__->mk_classdata('__memoStore');
__PACKAGE__->mk_classdata('__objectStore'=>[]);
__PACKAGE__->mk_classdata('__relationStore'=>[]);
__PACKAGE__->mk_classdata('__searchStore'=>[]);

sub __init {
	my ($class) = @_;
	{
		no strict qw(refs);
		map { &{"${_}::__init"}($class) } (
			$class->__canonicalStore,
			$class->__memoStore,
			#@{$class->__objectStore},
			#@{$class->__relationStore},
			#@{$class->__searchStore},
		);
	}
}

sub asHashRef {
	Cake::Exception::PureVirtual->throw;
}
sub _find {
	my ($class, $invocant, $search) = @_;
	my $object = $class->__canonicalStore->_find($invocant, $search);
	my $data   = $class->__canonicalStore->__fetch_object($object);
				 $class->__memoStore->__load_object($object,$data);
	return $object;
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


1;

