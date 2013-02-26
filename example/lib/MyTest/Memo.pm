package MyTest::Memo;
use base qw(MyTest);
use strict;

__PACKAGE__->_table('TESTmemo');
__PACKAGE__->_fields({
	id =>{
		primary => 1,
		isa => 'int',
	},
	subject => {
		isa => 'text',
		required => 1,
	},
	body => {
		isa => 'text',
		required => 1,
	},
	time => {
		isa => 'line',
	},
	owner=> {
		isa => 'line',
		required => 1,
		index => 1,
	},
	sender=> {
		isa => 'line',
		required => 1,
		index => 1,
	},
});

__PACKAGE__->_has_a({
	Owner  => ['owner' =>'MyTest::User'=>'name'],
	Sender => ['sender'=>'MyTest::User'=>'name']
});


__PACKAGE__->_setup;

1;
