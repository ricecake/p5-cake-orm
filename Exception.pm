package Cake::Exception;
use strict; use warnings;
use overload '""' => \&__stringify;

sub throw {
	no strict qw(refs);

	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->{location}   = sprintf("Package: %s filename: %s Line: %s Function: %s", caller(1));
	$self->{message} = ${"${class}::message"} || "An exception has ocured";
	die $self;
}

sub message {
	my $self =shift;
	return $self->{message};
}
sub location {
	my $self =shift;
	return $self->{location};
}
sub __stringify {
	my ($self, $other, $swap) = @_;
	return sprintf "%s at %s", $self->message, $self->location;
}

{
	package Cake::Exception::PureVirtual;
	use base qw(Cake::Exception);
	our $message = "Pure virtual method called";
}
{
	package Cake::Exception::ReadOnly;
	use base qw(Cake::Exception);
	our $message = "Attempted to write a read-only field";
}

1;