package Cake::Util::json;

use strict;

use JSON;

sub new {
	my ($class, @args) = @_;
	my $self = {};

	$self->{__JSON__} = JSON->new();
	$self->{__JSON__}->utf8;
	$self->{__JSON__}->relaxed;
	$self->{__JSON__}->space_after;
	$self->{__JSON__}->allow_blessed;
	$self->{__JSON__}->convert_blessed;
	bless ($self, $class);

	return $self;
}

sub AUTOLOAD {
	my ($self, @args) = @_;

	our $AUTOLOAD;
	(my $method = $AUTOLOAD) =~ s/.*:://;

	return $self->{__JSON__}->$method(@args);
}
sub DESTROY {}

1;
