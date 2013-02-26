package MyTest::Foo;

use lib qw(/usr/local/apps/lib/);

use base qw(MyTest);

#use Cake::Role qw(Cake::Role Cake::Role::Bother Cake::Role::Logger);

#__PACKAGE__->_addRoles(qw(Cake::Role::Logger Cake::Role::Bother));

__PACKAGE__->_fields({
	id =>{
		primary => 1,
		isa => 'int',
	},
	name => {
		isa => 'word',
		index => 1,
	},
	tag => {
		isa => 'int',
		unique => 1,
	},
	birthday => {
		isa =>'line',
		readOnly => 1,
		required => 1,
	}
});

__PACKAGE__->_setup;

1;
