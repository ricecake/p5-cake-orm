package Cake::Object::Storage::Persistent::NoSQL::Cassandra::Resultset;
use base qw(Cake::Object::Resultset);
use strict;
use overload '${}' => \&__scalarREF, '@{}' => \&__arrayREF, '""' => \&__stringify;;


1;
