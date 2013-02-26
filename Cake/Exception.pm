package Cake::Exception;
use strict;
use overload '""' => \&__stringify;

=head1 NAME

Cake::Exception

=head1 DESCRIPTION

Cake::Exception is the exception class used by Cake.  The exceptions that it throws come with a stack trace, as well
as information pertaining to how it was called, a (hopefully) descriptive message, and details about the error.

An unhandled exception will be automatically stringified, and have the stack trace attached to it.
To use the exception without the stacktrace, please see the below methods for how to access details about
the exception.

=head1 METHODS

=head2 throw

This is the basic exception method.

The throw method will gather information pertaining the the exception, and the exception class in questions,
and compile it into an exception object, which it will then die with.

=head3 Invocation:

C<< $exceptionClass->throw({exception => details}); >>

Takes as it's only parameter a hashref, containing details about the exception.

=cut

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

=head2 assert

The assert method is used for asserting that a given condition is true, and throwing an exception otherwise.

It's essentially a wrapper around C<< $class->throw unless CONDITION >>, but works out a bit more clearly in practice.

=head3 Invocation:

C<< $exceptionClass->assert(sub {1=1}, {error => "should never happen", broken => "logic"} >>

Takes as it's first argument a coderef, the truth of whos return value determines if an exception is thrown.
The second argument is a hashref, used for the same purpose as the hashref in the throw method.

=cut

sub assert  {
	my $class = shift;
	my $code = shift;
	my $args  = shift;
	
	$class->throw($args) unless eval { &{$code} };
}

=head2 message

The message method returns the message associated with an exception.

=head3 Invocation:

C<< $ex->message >>

=cut

sub message {
	my $self =shift;
	return $self->{message};
}

=head2 location

The location method gives a string containing the location in your code where the exception was thrown.

The information is conveyed as the string:
C<< 'Package:[%s] filename:[%s] Line:[%s] Function:[%s]' >>

=head3 Invocation:

C<< $ex->location >>

=cut

sub location {
	my $self =shift;
	return $self->{location};
}

=head2 details

The details method returns the hashref associated with the details specific to this exception.

=head3 Invocation:

C<< $ex->details >>

=cut

sub details {
	my $self = shift;
	return $self->{details};
}

=head2 trace

The trace method returns the arrayref associated with the stack trace taken when the exception is generated.

For more details in how the trace entires are presented, please see the location method.

=head3 Invocation:

C<< $ex->trace >>

=cut

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

=head1 EXCEPTION CLASSES

The following are specific exception classes that may be thrown by Cake, and what they mean.

=head2 Cake::Exception::PureVirtual

The method called has not been implemented in this classes inheritence tree, and is hence
undefined in this context.

=cut

{
	package Cake::Exception::PureVirtual;
	use base qw(Cake::Exception);
	our $message = "Pure virtual method called";
}

=head2 Cake::Exception::ReadOnly

an attempt was made to assign a value to a field which was defined as read only.

=cut

{
	package Cake::Exception::ReadOnly;
	use base qw(Cake::Exception);
	our $message = "Attempted to write a read-only field";
}

=head2 Cake::Exception::NotFound

An attempt was made to load or find an object which either does not exist,
or was not properly or specifically defined.

=cut

{
	package Cake::Exception::NotFound;
	use base qw(Cake::Exception);
	our $message = "The requested item could not be found";
}

=head2 Cake::Exception::DefinitionError

The class definition was malformed, and setup could not continue.

=cut

{
	package Cake::Exception::DefinitionError;
	use base qw(Cake::Exception);
	our $message = "There was an exception processing the class definition";
}

=head2 Cake::Exception::Required

A field that is mandatory was not provided.

=cut

{
	package Cake::Exception::Required;
	use base qw(Cake::Exception);
	our $message = "A required field was missing";
}

=head2 Cake::Exception::ConstraintViolation

A constraint on a fields value was violated.  This includes things like unique constraints.

=cut

{
	package Cake::Exception::ConstraintViolation;
	use base qw(Cake::Exception);
	our $message = "A field value constraint was violated";
}

=head2 Cake::Exception::TypeViolation

A field was given a value that is not acceptable for its given type.

=cut

{
	package Cake::Exception::Validation::TypeViolation;
	use base qw(Cake::Exception);
	our $message = "A value was unacceptable for its given type";
}

=head2 Cake::Exception::Role::MethodExists

An invalid attempt was made to install a role over an already existant method.

=cut

{
	package Cake::Exception::Role::MethodExists;
	use base qw(Cake::Exception);
	our $message = "The role could not be installed, as method name is in use";
}

=head2 Cake::Exception::Role::MethodUndefined

An attempt was made to alter the call semantics of a method that could not be found.

=cut

{
	package Cake::Exception::Role::MethodUndefined;
	use base qw(Cake::Exception);
	our $message = "The role could not be installed, as the target method could not be found";
}

=head2 Cake::Exception::Role::UndefinedRole

An attempt was made to implement a role that was not properly defined.

=cut

{
	package Cake::Exception::Role::UndefinedRole;
	use base qw(Cake::Exception);
	our $message = "The role could not be installed, as the role itself was undefined";
}

=head2 Cake::Exception::Config::LoadError

An error was encountered while attempting to load a configuration file.

=cut

{
	package Cake::Exception::Config::LoadError;
	use base qw(Cake::Exception);
	our $message = "An error was encountered while attempting to load a configuration file";
}

=head2 Cake::Exception::Config::UndefinedVariable

A configuration variable was not defined.

=cut

{
	package Cake::Exception::Config::UndefinedVariable;
	use base qw(Cake::Exception);
	our $message = "A configuration variable was not defined";
}

=head2 Cake::Exception::DB::DBIError

A database error was encountered.

=cut

{
	package Cake::Exception::DB::DBIError;
	use base qw(Cake::Exception);
	our $message = "A database error was encountered";
}

=head2 Cake::Exception::DataLoss

A Data Loss incident was attempted.

This is likely the result of attempting to call
delete as a class method, without providing a where clause.
If you really want to delete everything, generate a suitable
where clause.

=cut

{
	package Cake::Exception::DataLoss;
	use base qw(Cake::Exception);
	our $message = "A Data Loss incident was attempted";
}

=head2 Cake::Exception::NotSupported

An unsuported method use was attempted.

An attempt was made to use a method in a way
which is not currently supported.

=cut

{
	package Cake::Exception::NotSupported;
	use base qw(Cake::Exception);
	our $message = "An unsuported method use was attempted";
}

=head2 Cake::Exception::UnknownValue

An Unrecognized value was passed to a function.

The given option could not be understood

=cut

{
	package Cake::Exception::UnknownValue;
	use base qw(Cake::Exception);
	our $message = "An Unrecognized value was passed to a function";
}

1;

__END__

=head1 AUTHOR

Sebastian Green-Husted <ricecake@tfm.nu>

=cut
