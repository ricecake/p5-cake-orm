package Cake::Object::Storage::Persistent::DB::Postgres;
use base qw(Cake::Object::Persistent::DB);

__PACKAGE__->__engine(__PACKAGE__);
__PACKAGE__->__driver({});

1;