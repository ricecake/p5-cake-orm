package Cake::Object::Storage;
use base qw(Cake::Object);

__PACKAGE__->mk_classdata( "__engine" => __PACKAGE__ );
__PACKAGE__->mk_classdata( "__driver");

sub _local {
	my $self = shift;
	my $engine = $self->__engine;
	
	return $self->{$engine} ||= {};
	
}

sub _load {
	Cake::Exception::PureVirtual->throw;
}

# should just return a reference to the low level driver that the
# storage class uses.
sub _driver {
	Cake::Exception::PureVirtual->throw;
}



1;