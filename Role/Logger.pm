package Cake::Role::Logger;

use strict;
use base qw(Cake::Role);

use Data::Uniqid qw(luniqid);

our @actions = (
	[
		wrap => '__get_field', [\&preGet, \&postGet],
	],
	[
		wrap => '__set_field', [\&preSet, \&postSet],
	]
);

sub preSet {
	my ($args) = @_;
	
	my $class = ref($args->[0]);
	my $field = $args->[1];
	my $message = luniqid;
	my $time = sprintf("%X",time);
	
	print "${message}.$time.info.${class}.init.set.${field}\n";
	#uniqid.time.warningLevel.class.status.action.field
	
	return $message;
}

sub postSet {
	my ($message, $response, $args) = @_;
	
	my $class = ref($args->[0]);
	my $field = $args->[1];
	my $time = sprintf("%X",time);
	
	print "${message}.$time.info.${class}.done.set.${field}\n";
}

sub preGet {
	my ($args) = @_;
	
	my $class = ref($args->[0]);
	my $field = $args->[1];
	my $message = luniqid;
	my $time = sprintf("%X",time);
	
	print "${message}.$time.info.${class}.init.get.${field}\n";
	
	return $message;
}

sub postGet {
	my ($message, $response, $args) = @_;
	
	my $class = ref($args->[0]);
	my $field = $args->[1];
	my $time = sprintf("%X",time);
	
	print "${message}.$time.info.${class}.done.get.${field}\n";
}

1;