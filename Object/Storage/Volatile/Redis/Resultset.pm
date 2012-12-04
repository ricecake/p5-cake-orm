package Cake::Object::Storage::Volatile::Redis;
use base qw(Cake::Object::Resultset);
use strict;
use overload '${}' => \&__scalarREF, '@{}' => \&__arrayREF, '""' => \&__stringify;;

sub create {
	Cake::Exception::PureVirtual->throw;
}
sub asHashRefs {
	Cake::Exception::PureVirtual->throw;
}
sub sort {
	Cake::Exception::PureVirtual->throw;
}
sub all {
	Cake::Exception::PureVirtual->throw;
}
sub next {
	Cake::Exception::PureVirtual->throw;
}
sub count {
	Cake::Exception::PureVirtual->throw;
}
sub of {
	Cake::Exception::PureVirtual->throw;
}
sub delete {
	Cake::Exception::PureVirtual->throw;
}
sub _scalarREF {
	my ($self, $other, $swap) = @_;
	Cake::Exception::PureVirtual->throw;
}

sub _arrayREF {
	my ($self, $other, $swap) = @_;
	Cake::Exception::PureVirtual->throw;
}

sub __stringify {
	my ($self, $other, $swap) = @_;
	Cake::Exception::PureVirtual->throw;
}

1;
