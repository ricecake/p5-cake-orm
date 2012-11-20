package Cake::Role::Bother;

use strict;
use base qw(Cake::Role);

our @actions = (
	[
		wrap => '__get_field', [sub {
				my $args = shift;
				print "Alright, I'll get you the damned " . $args->[1] .".  But I won't enjoy it.\n";
				do {
					print "...\n";
					sleep 1;
				} for 1..3;
				print "\n*sigh*\n";
				sleep 2;
			},
			sub {
				my ($message, $response, $args) = @_;
				$response->[0] = "It's " . $response->[0] .", you nutter.";
			}],
	],
	[
		before => 'id', [sub{print "But I don't wanna fetch an ID again!\n"}],
	]
);

1;