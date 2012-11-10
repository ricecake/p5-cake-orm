package Cake::Object;

use strict;
use warnings;

use Sub::Name;
use Cake::Validation;
use Cake::Exception;

use base qw(Class::Data::Inheritable);

no strict qw(refs);

__PACKAGE__->mk_classdata( "__fieldTraitMap" => {} );
__PACKAGE__->mk_classdata( "__traitFieldMap" => {} );
__PACKAGE__->mk_classdata( "__hasMany" => {} );
__PACKAGE__->mk_classdata( "__hasA" => {} );


#public inherited methods
sub asHashRef {
	Cake::Exception::PureVirtual->throw;
}

sub search {
	Cake::Exception::PureVirtual->throw;
}

sub find {
	Cake::Exception::PureVirtual->throw;
}

sub findOrCreate {
	my $class  = shift;
	my $params = shift;
	return $class->find($params) || $class->create($params);
}

sub findOrDie {
	my $class  = shift;
	my $params = shift;
	return ( $class->find($params) || Cake::Exception::NotFound->throw );
}

sub _preCreate  { return; }

my $createFunc = sub  {
	my $class = shift;
	my $parameters = shift;
	my %definition   = %{ $class->__fieldTraitMap() };
	my %traitMap    = %{ $class->__traitFieldMap() };

	foreach my $required (@{ $traitMap{required} }) {
		unless ( exists $parameters->{$required} && defined $parameters->{$required} ) {
			Cake::Exception::Required->throw({field => $required});
		}
	}
	foreach my $type ( keys %{ $traitMap{isa} }) {
		foreach my $field ( @{ $traitMap{isa}{$type} }) {
			next unless exists $parameters->{$field};
			Cake::Validation::enforceType($type, $parameters->{$field}, $field);
		}
	}
	
	$class->_preCreate($parameters);
	my $object   = $class->_build($parameters, \%definition);
	$class->_postCreate($object, $parameters);
	
	return $object;
};

sub _postCreate { return; }

sub _build {
	Cake::Exception::PureVirtual->throw;	
}

sub update {
	my $class = shift;
	my $parameters = shift;
	my %definition   = %{ $class->__fieldTraitMap() };
	my %traitMap    = %{ $class->__traitFieldMap() };

	foreach my $required (@{ $traitMap{required} }) {
		if (exists $parameters->{$required} && !(defined $parameters->{$required}) ) {
			Cake::Exception::Required->throw({field => $required});
		}
	}
	foreach my $type ( keys %{ $traitMap{isa} }) {
		foreach my $field ( @{ $traitMap{isa}{$type} }) {
			next unless exists $parameters->{$field};
			Cake::Validation::enforceType($type, $parameters->{$field}, $field);
		}
	}

	return $class->_update($parameters, \%definition);
}

sub _update {
	Cake::Exception::PureVirtual->throw;
}


sub delete {
	Cake::Exception::PureVirtual->throw;
}

sub _load {
	Cake::Exception::PureVirtual->throw;
}

#private inherited methods

=pod

The _fields method lays out the description of the fileds in a class.
Should specify if the field is indexed (default), unique, read-only, required or
the primary key.
will eventually also specify the 'type' of the field.
{
	field => {
		primary  => 0,
		required => 1,
		indexed => 0,
		unique  => 1,
		readOnly => 1,
		isa => "INTEGER' #not implemented yet.
	},
	...
}

=cut

sub _fields {
	my $class             = shift;
	my $definition        = shift;
	my $reverseDefinition = {};

	foreach my $field ( keys %{ $definition } ) {
		
		Cake::Exception::Required->throw({trait => 'isa', field => $field}) unless $definition->{$field}{isa};
		
		if ( $definition->{$field}{unique} ) {
			delete $definition->{$field}{indexed};
		}

		if ( $definition->{$field}{primary} ) {
			delete $definition->{$field}{indexed};
			delete $definition->{$field}{unique};
			$definition->{$field}{readOnly} = 1;
		}

		foreach my $trait ( keys %{ $definition->{$field} } ) {
			next if $trait eq 'isa';
			my $traitSet = $definition->{$field}{$trait};
			if ($traitSet) {
				push( @{ $reverseDefinition->{$trait} }, $field );
			}
		}
		push( @{ $reverseDefinition->{isa}{$definition->{$field}{isa}} }, $field );
	}

	unless ( exists $reverseDefinition->{primary} && @{ $reverseDefinition->{primary} } == 1 )
	{
		Cake::Exception::DefinitionError->throw( { trait => 'primary' } );
	}

	$class->__fieldTraitMap( $definition );
	$class->__traitFieldMap( $reverseDefinition );
}

=pod

the _has_a method describes relationships that a class has,
where an object in the class has a singular relationship to another object in the given class.
maps the field name to an array where the first element is the class that is referenced,
and the second is the name of the field that is being refernced.
equivelent to a forign key relationship, where THIS.field references OTHER.givenField
if the value is not a arrayref, it assumes the primary key of the class.
{
	owner => ['Apps::Memo::User' => 'name'],
	sender => ['Apps::Memo::User' => 'name']
}

=cut

sub _has_a {
	my $class      = shift;
	my $definition = shift;

	$class->__hasA( $definition );
}

=pod

_has_many is the counterpart to hasa.
field name is the local name for the set of remote objects which refence this one.
parameter is an array, with the first entry being the local field, the second being the remote class,
and the third field is the remote field which references the local field.
{
	recievedMsgs => ['name'=>'Apps::Memo::Message'=>'owner'],
	sentMsgs => ['name'=>'Apps::Memo::Message'=>'sender']
}

=cut

sub _has_many {
	my $class      = shift;
	my $definition = shift;

	$class->__hasMany( $definition );
}

sub _setup {
	my $class      = shift;
	my %definition = %{ $class->__fieldTraitMap() };
	my %hasMany = %{ $class->__hasMany() };
	my %hasA       = %{ $class->__hasA() };
	
	while ( my ( $field, $traits ) = each %definition ) {
		if ( $definition{$field}{readOnly} ) {
			*{"${class}::${field}"} = $class->___mk_read_only( $field, $traits );
		}
		else {
			*{"${class}::${field}"} = $class->___mk_read_write( $field, $traits );
		}
	}
	
	while ( my ( $field, $details ) = each %hasMany ) {
		*{"${class}::${field}"} = $class->___mk_has_many( $field, $details );
	}
	
	while ( my ( $field, $details ) = each %hasA ) {
		*{"${class}::${field}"} = $class->___mk_has_a( $field, $details );
	}
	*{"${class}::create"} = subname "${class}::create" => $createFunc;
}

sub __get_field {
	Cake::Exception::PureVirtual->throw;
}

sub __set_field {
	Cake::Exception::PureVirtual->throw;
}

sub __get_has_a {
	Cake::Exception::PureVirtual->throw;
}

sub __set_has_a {
	Cake::Exception::PureVirtual->throw;
}

sub __get_has_many {
	Cake::Exception::PureVirtual->throw;
}

#private 'not inherited' methods
sub ___mk_read_only {
	my $class  = shift;
	my $field  = shift;
	my $traits = shift;

	return subname "${class}::${field}" => sub {
		my $self = shift;
		if (@_) {
			Cake::Exception::ReadOnly->throw;
		}
		else {
			return $self->__get_field( $field, $traits );
		}
	}
}

sub ___mk_read_write {
	my $class  = shift;
	my $field  = shift;
	my $traits = shift;

	return subname "${class}::${field}" => sub {
		my $self = shift;
		if (@_) {
			return $self->__set_field( $field, $traits, @_ );
		}
		else {
			return $self->__get_field( $field, $traits );
		}
	}
}

sub ___mk_has_a {
	my $class  = shift;
	my $field  = shift;
	my $details = shift;

	return subname "${class}::${field}" => sub {
		my $self = shift;
		if (@_) {
			return $self->__set_has_a( $field, $details, @_ );
		}
		else {
			return $self->__get_has_a( $field, $details );
		}
	}
}

sub ___mk_has_many {
	my $class    = shift;
	my $field     = shift;
	my $details = shift;

	return subname "${class}::${field}" => sub {
		my $self = shift;
		if (@_) {
			Cake::Exception::ReadOnly->throw;
		}
		else {
			return $self->__get_has_many( $field, $details );
		}
	}
}

1;
