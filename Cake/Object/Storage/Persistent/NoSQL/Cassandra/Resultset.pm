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

sub sort {
	my ($self, $order, $options) = @_;
	
	my ($sortOrder) = grep { /^-(asc|desc)$/i } keys %$order;
	Cake::Exception::Required->throw({field => 'sort', values => '-asc, -desc'}) unless $sortOrder;

	my $sortKey = $order->{$sortOrder};
	$sortOrder = lc($sortOrder) eq '-desc'? 'descending' : 'ascending';

	my $collate = $options->{-collate};
	$collate = ($collate eq 'alpha')?  'alpha'   :
			   ($collate eq undef)  ?  'alpha'   :
			   ($collate =~ /^num/i)?  'numeric' :
			   Cake::Exception::UnknownValue->throw({
					field => '-collate',
					value => $collate,
					acceptable => 'alpha, numeric'
				});
			   
	my %sortFunc = (
		alpha   => {
			ascending  => sub { $a->{$sortKey} cmp $b->{$sortKey} },
			descending => sub { $b->{$sortKey} cmp $a->{$sortKey} },
		},
		numeric => {
			ascending  => sub { $a->{$sortKey} <=> $b->{$sortKey} },
			descending => sub { $b->{$sortKey} <=> $a->{$sortKey} },
		},
	);
	my $function = $sortFunc{$collate}{$sortOrder};

	@{ $self->{results} } = sort $function @{ $self->{results} };
	
	if(exists $options->{-limit}) {
		my $limit  = $options->{-limit};
		my $offset = $options->{-offset} || '0';
		@{ $self->{results} } = splice(@{ $self->{results} }, $offset, $limit);
	}

	return $self;
}
sub of {
	return shift->{of};
}
sub delete {
	Cake::Exception::PureVirtual->throw;	
}


1;
