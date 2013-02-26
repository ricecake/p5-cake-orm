package MyTest;
use lib qw(/usr/local/apps/lib);
use base qw(Cake::Object::CDS::Flex);
use strict;

__PACKAGE__->_getConfig->loadConfig('/usr/local/apps/t/config/MyTest.json');

use Cake::Object::Storage::Persistent::DB::Postgres;
use Cake::Object::Storage::Persistent::NoSQL::Cassandra;
use Cake::Object::Storage::Volatile::Redis;
use Cake::Object::Storage::Volatile::Local;

__PACKAGE__->__memoStore("Cake::Object::Storage::Volatile::Local");
__PACKAGE__->__canonicalStore("Cake::Object::Storage::Persistent::DB::Postgres");
__PACKAGE__->__relationStore([qw(
		Cake::Object::Storage::Persistent::NoSQL::Cassandra
)]);
#		Cake::Object::Storage::Volatile::Redis

__PACKAGE__->__init;

1;
