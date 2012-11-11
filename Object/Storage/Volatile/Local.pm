package Cake::Object::Storage::Volatile::Local;
use base qw(Cake::Object::Storage::Volatile);

use strict;

__PACKAGE__->__engine(__PACKAGE__);
__PACKAGE__->__driver({});

my %setters = (
	unique   => sub {
		my $self = shift;
		my $class = shift;
		my $field = shift;
		my $value = shift;
		
		Cake::Exception::ConstraintViolation->assert(
			sub {
				not exists $self->_driver()->{$class}{unique}{$field}{$value};
			}, {field => $field, value => $value, constraint => 'unique'});

		$self->_driver()->{$class}{unique}{$field}{$value} = $self;

		if(defined $self->{data}{$field}) {
			delete $self->_driver()->{$class}{unique}{$field}{$self->{data}{$field}};
		}
	},
	index   => sub {
		my $self = shift;
		my $class = shift;
		my $field = shift;
		my $value = shift;
		
		push(@{ $self->_driver()->{$class}{index}{$field}{$value} }, $self );

		if(defined $self->{data}{$field}) {
			delete $self->_driver()->{$class}{unique}{$field}{$self->{data}{$field}};
		}
	},
);

sub __get_field {
	my $self = shift;
	my $field = shift;
	my $traits = shift;
	return $self->{data}{$field};
}

sub __set_field {
	my $self = shift;
	my $field = shift;
	my $traits = shift;
	my $value = shift;
	my $class = ref($self);
	
	if($traits->{unique}) {
		$setters{unique}->($self, $class, $field, $value);
	}
	elsif ($traits->{index}) {
		$setters{index}->($self, $class, $field, $value);
	}
	
	$self->{data}{$field} = $value;
	return $self;
}

sub _build {
	my $class = shift;
	my $params = shift;
	my $def = shift;
	my $self = {};
	bless $self,$class;
	
	foreach my $field (keys %{$params}) {
		#$self->{data}{$field} = $params->{$field};
		my $traits = $def->{$field};
		my $value = $params->{$field};
		$self->__set_field($field, $traits, $value);
	}
	return $self;
}

sub asHashRef {
	my $self = shift;
	return $self->{data};
}

sub _driver {
	my $class = shift;
	return $class->__driver();
}

1;
