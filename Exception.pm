package Cake::Exception;
use strict; use warnings;
use overload '""' => \&__stringify;

sub throw {
	no strict qw(refs);

	my $class = shift;
	my $args  = shift;
	my $self = {};
	bless $self, $class;
	$self->{location}   = sprintf("Package:[%s] filename:[%s] Line:[%s] Function:[%s]", caller(1));
	$self->{message} = ${"${class}::message"} || "An exception has ocured";
	$self->{details} = $args;
	
	my $frame = 1;
	while(my ($package, $file, $line, $function) = caller($frame++)) {
		push(@{ $self->{trace} }, sprintf("Package:[%s] filename:[%s] Line:[%s] Function:[%s]", $package, $file, $line, $function) );
	}
	die $self;
}

sub assert  {
	my $class = shift;
	my $code = shift;
	my $args  = shift;
	
	$class->throw($args) unless &{$code};
}

sub message {
	my $self =shift;
	return $self->{message};
}
sub location {
	my $self =shift;
	return $self->{location};
}
sub details {
	my $self = shift;
	return $self->{details};
}
sub trace {
	my $self = shift;
	return $self->{trace};
}
sub __stringify {
	my ($self, $other, $swap) = @_;
	my $message = sprintf "%s at %s", $self->message, $self->location;
	
	if($self->details) {
		my %details = %{ $self->details };
		my $details = join("\n", map { "    $_ => $details{$_}" } keys %details );
		$message .= "\ndetails:\n$details\n";
	}
	$message .= "\nStack trace:\n" . join("", map {"\t$_\n"} @{$self->{trace}});
	return $message;
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
{
	package Cake::Exception::NotFound;
	use base qw(Cake::Exception);
	our $message = "The requested item could not be found";
}
{
	package Cake::Exception::DefinitionError;
	use base qw(Cake::Exception);
	our $message = "There was an exception processing the class definition";
}
{
	package Cake::Exception::Required;
	use base qw(Cake::Exception);
	our $message = "A required field was missing";
}
{
	package Cake::Exception::TypeViolation;
	use base qw(Cake::Exception);
	our $message = "A value was unacceptable for its given type";
}
{
	package Cake::Exception::ConstraintViolation;
	use base qw(Cake::Exception);
	our $message = "A field value constraint was violated";
}

1;
