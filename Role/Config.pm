package Cake::Role::Config;
use base qw(Cake::Role);

use strict;

use Cake::Config;

our @actions = (
	[
		once => 'createClassConfig', [sub{
			my $class = shift;
			$class->mk_classdata(__config => Cake::Config->new());
		}],
	],
	[
		insert => '_getConfig', [sub{
			my $class = shift;
			return $class->__config();
		}],
	],
);

1;

__END__

=head1 AUTHOR

Sebastian Green-Husted <ricecake@tfm.nu>

=cut
