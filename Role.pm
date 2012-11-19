package Cake::Role;
use strict;

use Sub::Name;

=head1 NAME

Cake::Role

=head1 DESCRIPTION

Cake::Role is the way that Cake handles adding methods to a class, or altering the behavior of existing methods.
If there is a chunk of code that is reusable, or that has a particular pice of utility that can be shared, but it doesn't fit well into the normal
notion of an inheritence tree, you can do this with a role.  The role will be installed into the package namespace, but won't affect
inheritence.

All role packages provide their functionality in the same way:  An our variable in the class named 'actions'
holds a list of lists of strategies, method names, and code.

	@actions = (
			[
				wrap => 'method', [\&, \&],
			],
	);

=head1 METHODS

=head2 __install_role

 install_role is the heart of roles.  It's basic purpose is to, oddly enough, install roles into a given package.
In general, this method should only be used for internal purposes, as the intent is to provide more convinient ways
to use roles via other methods.

=head3 Invocation:

C<< __install_role($targetPackage, $strategy => $methodName, \@codeRefs); >>

 Target package is the namespace that the role will be installed into.
 Strategy is how it will be installed.
 Method name is the name that it will be installed as.
 coderefs is an array of code references that will be installed in a fashion determined by the strategy.

 Strategy is case insensitive, but all other parameters should be assumed sensitive.

=over

=item * B<insert>

C<< __install_role('PACKAGE', 'insert' => 'method', [sub{do stuff in a new method}] ); >>

With the insert strategy, the method defined in the sub will be installed in the package, with the given name.  
 An exception will be thrown if the method already exists, or is inherited.

=item * B<replace>

C<< __install_role('PACKAGE', 'replace' => 'method', [sub{do stuff before method}] ); >>

With the replace strategy, the method defined in the sub will be installed over the given method in the package.  
 An exception will be thrown if the method does not exist, or is not inherited.

=item * B<before>

C<< __install_role('PACKAGE', 'before' => 'method', [sub{do stuff before method}] ); >>

With the before strategy, the given code will be executed I<before> the named method.  
 An exception will be thrown if the method does not exist, or is not inherited.

=item * B<after>

C<< __install_role('PACKAGE', 'after' => 'method', [sub{do stuff after method}] ); >>

With the after strategy, the given code will be executed I<after> the named method.  
 An exception will be thrown if the method does not exist, or is not inherited.

=item * B<wrap>

C<< __install_role('PACKAGE', 'wrap' => 'method', [sub{do stuff before method}, sub {do stuff after method}] ); >>

With the wrap strategy, the first code reference given will be executed I<before> the named method, and the second will be executed I<after>.
 An exception will be thrown if the method does not exist, or is not inherited.

=back

=cut

sub __install_role {
	my ( $package, $strategy, $method, $codeARRAY, ) = @_;

	$strategy = lc($strategy);

	if ( $strategy eq 'insert' ) {
		Cake::Exception::Role::MethodExists->assert(
			sub {
				not $package->can($method);
			},
			{
				package => $package,
				method  => $method,
			}
		);

		{
			no strict qw(refs);
			*{"${package}::${method}"} =
			  subname "${package}::${method}" => $codeARRAY->[0];
		}
	}
	else {
		my $original;
		Cake::Exception::Role::MethodUndefined->assert(
			sub {
				$original = $package->can($method);
			},
			{
				package => $package,
				method  => $method,
			}
		);

		if ( $strategy eq 'replace' ) {
			{
				no strict qw(refs);
				*{"${package}::${method}"} =
				  subname "${package}::${method}" => $codeARRAY->[0];
			}
		}
		elsif ( $strategy eq 'before' ) {
			my $before = subname "${package}::before_${method}" => $codeARRAY->[0];
			my $function = subname "${package}::meta_${method}" => sub {
				$before->( \@_ );
				return $original->(@_);
			};
			{
				no strict qw(refs);
				*{"${package}::${method}"} = $function;
			}
		}
		elsif ( $strategy eq 'after' ) {
			my $after    = subname "${package}::after_${method}" => $codeARRAY->[0];
			my $function = subname "${package}::meta_${method}"  => sub {
				my @response = $original->(@_);
				$after->( \@response, \@_ );
				return @response;
			};
			{
				no strict qw(refs);
				*{"${package}::${method}"} = $function;
			}
		}
		elsif ( $strategy eq 'wrap' ) {
			my $before = subname "${package}::before_${method}" => $codeARRAY->[0];
			my $after  = subname "${package}::after_${method}"  => $codeARRAY->[1];
			my $function = subname "${package}::meta_${method}" => sub {
				$before->( \@_ );
				my @response = $original->(@_);
				$after->( \@response, \@_ );
				return @response;
			};
			{
				no strict qw(refs);
				*{"${package}::${method}"} = $function;
			}
		}
	}
}

sub import {
	my $class  = shift;
	my @args   = @_;
	my $caller = caller;
	
	#if @args is defined, then we were called with a list of roles to apply to the class. so lets do that.
	if (@args) {
		no strict qw(refs);
		for my $role (@args) {
			eval "require $role";
			foreach my $action (@{"${role}::actions"}) {
				__install_role($caller, @{ $action });
			}
		}
	}
}

1;

__END__

=head1 AUTHOR

Sebastian Green-Husted <ricecake@tfm.nu>

=cut
