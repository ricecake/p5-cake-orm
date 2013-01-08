package Cake::Object::Storage::Persistent::NoSQL::Cassandra::Resultset;
use base qw(Cake::Object::Resultset);
use strict;
use overload '${}' => \&__scalarREF, '@{}' => \&__arrayREF, '""' => \&__stringify;;

sub create {
	my ($class, $of, $results) = @_;
	$results = [values %$results];
	my $self = {results => $results, of => $of};
	bless $self, $class;
	return $self;
}

sub all {
	my ($self) = @_;
	my $of = $self->of;
	my $primary = $of->__traitFieldMap()->{primary};
	my @results = map {
		$of->_build({ $primary => $_->{$primary} })->_sync
		} @{ $self->{results} };
	return wantarray? @results : \@results;
}

sub next {
	my ($self) = @_;
	my $of = $self->of;
	my $primary = $of->__traitFieldMap()->{primary};

	my $result = shift(@{$self->{results}});

	if($result) {
		return $of->_build({ $primary => $result->{$primary} })->_sync;
	}
	return;
}

sub count {
	my ($self) = @_;
	return scalar @{$self->{results}};
}

sub __ascAlpha  { $a cmp $b };
sub __ascNumer  { $a <=> $b };
sub __descAlpha { $b cmp $a };
sub __descNumer { $b <=> $a };

sub sort {
	my ($self, $order, $options) = @_;
}
sub of {
	return shift->{of};
}
sub delete {
	Cake::Exception::PureVirtual->throw;	
}


1;
