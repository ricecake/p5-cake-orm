package MyTest::User;

use base qw(MyTest);

#use Cake::Role qw(Cake::Role Cake::Role::Bother Cake::Role::Logger);

#__PACKAGE__->_addRoles(qw(Cake::Role::Logger Cake::Role::Bother));

__PACKAGE__->_table('TESTusers');
__PACKAGE__->_fields({
	id =>{
		primary => 1,
		isa => 'int',
	},
	name => {
		isa => 'line',
		unique => 1,
		required => 1,
	},
	color => {
		isa => 'line',
	},
});

__PACKAGE__->_has_many({
	recievedMsgs => ['name'=>'MyTest::Memo'=>'owner'],
	sentMsgs     => ['name'=>'MyTest::Memo'=>'sender']
});


__PACKAGE__->_setup;

1;
