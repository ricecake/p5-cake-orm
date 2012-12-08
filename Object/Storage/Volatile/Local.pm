package Cake::Object::Storage::Volatile::Local;
use base qw(Cake::Object::Storage::Volatile);

use strict;

__PACKAGE__->__engine(__PACKAGE__);
__PACKAGE__->__driver({});

sub __init {
	my ($class) = @_;
	$class->_registerInitCallback(__PACKAGE__->can('__instantiate'));
}

sub __instantiate {
	my ($object) = @_;
	$object->_local->{data} = undef;
	return;
}

sub __get_field {
	my ($class, $self, $traits, $field) = @_;

	return $self->_local->{data}{$field};
}

sub __set_field {
	my ($class, $self, $traits, $field, $value) = @_;	
	
	$self->{data}{$field} = $value;
	return $self;
}

sub __load_object {
	my ($class, $invocant, $data) = @_;
	$invocant->_local->{data} = $data;
	return $invocant;
}

sub asHashRef {
	my $self = shift;
	return $self->{data};
}

1;
