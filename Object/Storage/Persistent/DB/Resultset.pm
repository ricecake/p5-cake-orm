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
		Cake::Object::Storage::Persistent::DB::__instantiate($of, { field => $primary, value => $_->[0] })
		} @{ $self->{sth}->fetchall_arrayref };
	return wantarray? @results : \@results;
}
sub next {
	my ($self) = @_;
	my $of = $self->of;
	my $primary = $of->__traitFieldMap()->{primary};
	my $result = $self->{sth}->fetchrow_arrayref;
	if($result) {
		return Cake::Object::Storage::Persistent::DB::__instantiate($of,
			{ field => $primary, value => $result->[0] });
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
