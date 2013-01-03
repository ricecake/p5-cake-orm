package Cake::Object::Storage::Volatile::Redis::Resultset;
use base qw(Cake::Object::Resultset);
use strict;
use overload '${}' => \&__scalarREF, '@{}' => \&__arrayREF, '""' => \&__stringify;;

sub create {
	my ($class, $of, $r) = @_;
	my $self    = {of => $of, r => $r};
	bless($self,$class);
	my $id      = $r->incr("${class}::GLOBAL::seq");
	$self->{key}= "$class=$id";
	return $self;
}
sub createFromSet {
	my $class = shift;
	my $setKey= shift;
	my $r = shift;
	my ($setClass) = $setKey =~ /^([\w:]+)->/;
	my $self  = $class->create($setClass, $r);
	$self->{cow} = $self->{key};
	$self->{key} = $setKey;
	$self->{mode} = 'SET';
	return $self;
}
sub asHashRefs {
	Cake::Exception::PureVirtual->throw;
}
sub sort {
	my ($self, $order, $options) = @_;
	my $r = $self->{r};

	my ($sortOrder) = grep { /^-(asc|desc)$/i } keys %$order;
	Cake::Exception::Required->throw({field => 'sort', values => '-asc, -desc'}) unless $sortOrder;

	my $sortKey = $order->{$sortOrder};
	$sortKey = "*->$sortKey";
	$sortOrder = lc($sortOrder) eq '-desc'?'desc':'asc';

	my $collate = $options->{-collate};
	$collate = ($collate eq 'alpha')? 'alpha' :
			   ($collate eq undef)  ? 'alpha' :
			   ($collate =~ /^num/i)?  undef  :
			   Cake::Exception::UnknownValue->throw({field => '-collate',
								 value => $collate,
								 acceptable => 'alpha, numeric'});
	
	my @limit;
	if(exists $options->{-limit}) {
		my $limit  = $options->{-limit};
		my $offset = $options->{-offset} || '0';
		push(@limit, ('LIMIT', $offset, $limit));
	}
	
	my @sortOptions;
	if ($self->{cow}) {
		@sortOptions = grep {defined} ($self->{key}, 'BY', $sortKey, $sortOrder, $collate, @limit, "STORE", $self->{cow}, sub{});
		$r->sort(@sortOptions);
		$self->{key} = delete $self->{cow};
	}
	else {
		@sortOptions = grep {defined} ($self->{key}, 'BY', $sortKey, $sortOrder, $collate, @limit, "STORE", $self->{key}, sub{});
		$r->sort(@sortOptions);
	}

	$self->{mode} = 'LIST';
	return $self;
}
sub all {
	my $self = shift;
	my $mode = $self->{mode};
	my $of = $self->of;
	my $r  = $self->{r};
	my $primary = $of->__traitFieldMap()->{primary};
	my @results;

	if ($mode eq 'LIST') {
		@results = map { $of->_build({$primary => $_}) }
					map { s/^.+=//o and $_ } $r->lrange($self->{key},0,-1);
	}
	else {
		@results = map { $of->_build({$primary => $_}) }
					map { s/^.+=//o and $_ } $r->smembers($self->{key});
	}
	return wantarray? @results : \@results;
}
sub next {
	my $self = shift;
	my $mode = $self->{mode};
	my $of = $self->of;
	my $r  = $self->{r};
	my $primary = $of->__traitFieldMap()->{primary};
	my $next;
	
	if ($mode eq 'LIST') {
		$next = $r->lpop($self->{key});
	}
	else {
		if ($self->{cow}) {
			$r->sunionstore($self->{cow}, $self->{key}, sub{});
			$self->{key} = delete $self->{cow};
		}
		$next = $r->spop($self->{key});
	}
	return unless defined $next;
	$next =~ s/^.+=//o;
	$next = $of->_build({$primary => $next});
	
	return $next;
}

sub count {
	Cake::Exception::PureVirtual->throw;
}
sub of {
	my $self = shift;
	return $self->{of};
}
sub delete {
	Cake::Exception::PureVirtual->throw;
}
sub DESTROY {
	my $self = shift;
	return if $self->{cow};
	my $key = $self->{key};
	require Redis;
	my $redis = Redis->new;
	$redis->select(2);
	$redis->del($key, sub{});
}


sub _scalarREF {
	my ($self, $other, $swap) = @_;
	Cake::Exception::PureVirtual->throw;
}

sub _arrayREF {
	my ($self, $other, $swap) = @_;
	Cake::Exception::PureVirtual->throw;
}

sub __stringify {
	my ($self, $other, $swap) = @_;
	Cake::Exception::PureVirtual->throw;
}

1;
