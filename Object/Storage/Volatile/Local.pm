package Cake::Object::Storage::Volatile::Local;
use base qw(Cake::Object::Storage::Volatile);

use strict;

__PACKAGE__->__engine(__PACKAGE__);
__PACKAGE__->__driver({});

sub __get_field {
	my ($class, $self, $traits, $field) = @_;

	return $self->{data}{$field};
}

sub __set_field {
	my ($class, $self, $traits, $field, $value) = @_;	
	
	$self->{data}{$field} = $value;
	return $self;
}

sub _build {
	my $class = shift;
	my $params = shift;
	my $def = shift;
	my $self = {};
	bless $self,$class;

	my $primaryKey = $class->__traitFieldMap->{primary};
	my $keyVal ||= $class->_driver()->{$class}{seq}{$primaryKey}++;
	$params->{$primaryKey} = $keyVal;
	
		%{$self->{data}} = %{$params};
		
	return $self;
}

sub asHashRef {
	my $self = shift;
	return $self->{data};
}

1;
