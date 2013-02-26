package Cake::Object::Storage::Persistent::DB::Resultset;
use base qw(Cake::Object::Resultset);
use strict;

sub create {
	my ($class, $of, $sth) = @_;
	my $self = {sth => $sth, of => $of};
	bless $self, $class;
	return $self;
}
sub asHashRefs {
	Cake::Exception::PureVirtual->throw;	
}
sub all {
	my ($self) = @_;
	my $of = $self->of;
	my $primary = $of->__traitFieldMap()->{primary};
	my @results = map {
		$of->_build({ $primary => $_->[0] })->_sync
		} @{ $self->{sth}->fetchall_arrayref };
	return wantarray? @results : \@results;
}
sub next {
	my ($self) = @_;
	my $of = $self->of;
	my $primary = $of->__traitFieldMap()->{primary};

	unless(exists $self->{_results}) {
		@{ $self->{_results} } = map { @{$_} } @{ $self->{sth}->fetchall_arrayref };
	}

	my $result = shift(@{$self->{_results}});

	if($result) {
		return $of->_build({$primary => $result })->_sync;
	}
	return;
}
sub count {
	my ($self) = @_;
	my $of = $self->of;
	return $self->{sth}->rows;
}
sub of {
	return shift->{of};
}
sub delete {
	Cake::Exception::PureVirtual->throw;	
}


1;
