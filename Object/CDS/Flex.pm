package Cake::Object::CDS::Flex;
use base qw(Cake::Object::CDS);
use strict;


__PACKAGE__->mk_classdata('__canonicalStore');
__PACKAGE__->mk_classdata('__memoStore');
__PACKAGE__->mk_classdata('__objectStore'=>[]);
__PACKAGE__->mk_classdata('__relationStore'=>[]);
__PACKAGE__->mk_classdata('__searchStore'=>[]);

sub asHashRef {
	Cake::Exception::PureVirtual->throw;
}
sub __get_field {
	Cake::Exception::PureVirtual->throw;
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
sub _find {
	Cake::Exception::PureVirtual->throw;
}


1;

