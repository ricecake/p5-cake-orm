package Cake::Object::Storage::Persistent::DB;
use base qw(Cake::Object::Persistent);

use DBI;
use SQL::Abstract;

__PACKAGE__->mk_classdata( "_table");

1;