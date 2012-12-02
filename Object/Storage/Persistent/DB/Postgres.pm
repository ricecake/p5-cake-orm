package Cake::Object::Storage::Persistent::DB::Postgres;
use strict;
use base qw(Cake::Object::Storage::Persistent::DB);

sub __init {
	my $config = __PACKAGE__->_getConfig->fetchAll;

	my $platform = $config->{platform};
	my $database = $config->{database};
	my $host = $config->{host};
	my $port = $config->{port};
	my $user = $config->{user};
	my $pw = $config->{pw};
	
	my $dsn = "dbi:$platform:database=$database;host=$host;port=$port";
	
	__PACKAGE__->__driver(DBI->connect($dsn, $user, $pw));
	__PACKAGE__->__driver->{HandleError} = sub {Cake::Exception::DB::DBIError->throw({driver => "Postgres", "errstr" => $_[0]})};
}

1;