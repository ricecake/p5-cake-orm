package Cake::Validation;

use strict;
use warnings;

use Regexp::Common;
use Cake::Exception;

sub checkType {
	my $type  = shift;
	my $value = shift;
	
	if($value =~ $Cake::Validation::TYPES->{$type}){
		return 1;
	}
	else {
		return 0;
	}
}

sub enforceType {
	my $type  = shift;
	my $value = shift;
	my $field   = shift;
	unless(Cake::Validation::checkType($type, $value)){
		Cake::Exception::Validation::TypeViolation->throw({type => $type, value => $value, field => $field});
	}
	return 1;
}

our $TYPES = {
	int    => qr/^$RE{num}{int}\z/o,
	real  => qr/^$RE{num}{real}\z/o,
	text  => qr/^[^[:cntrl:]]+\z/mo,
	word => qr/^[^[:cntrl:]\s]+\z/o,
	line   => qr/^[^[:cntrl:]]+\z/o,
	bool  => qr/^(?:0|1)\z/o,
};

1;