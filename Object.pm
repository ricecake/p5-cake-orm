package Cake::Object;

use strict;

use Sub::Name;
use Cake::Validation;
use Cake::Exception;

use base qw(Class::Data::Inheritable Cake::Role);

__PACKAGE__->mk_classdata( "__fieldTraitMap" => {} );
__PACKAGE__->mk_classdata( "__traitFieldMap" => {} );
__PACKAGE__->mk_classdata( "__hasMany" => {} );
__PACKAGE__->mk_classdata( "__hasA" => {} );
__PACKAGE__->mk_classdata( "__initCallbacks" => [] );
__PACKAGE__->mk_classdata( "__postSetupActions"  => [] );

use Cake::Role qw(Cake::Role);

#public inherited methods

sub _preCreate  {
	return;
}
sub _create {
	Cake::Exception::PureVirtual->throw;	
}
sub _postCreate {
	return;
}
sub asHashRef {
	Cake::Exception::PureVirtual->throw;
}
sub _update {
	Cake::Exception::PureVirtual->throw;
}
sub _delete {
	Cake::Exception::PureVirtual->throw;
}
sub _search {
	Cake::Exception::PureVirtual->throw;
}
sub _find {
	Cake::Exception::PureVirtual->throw;
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
sub __get_has_many {
	Cake::Exception::PureVirtual->throw;
}


sub search {
	my ($class, $search, $order, $options) = @_;
	return $class->_search($class, $search, $order, $options);
}

sub find {
	my ($class, $args) = @_;
	
	my %traitMap = %{ $class->__traitFieldMap() };
	my %definition   = %{ $class->__fieldTraitMap() };
	
	if(ref($args) eq 'HASH') { #We were passed a named field to search by, and should only use it.
		return $class->_find($class, $args);
	}
	else { #We were passed just one, and must build or out of unique fields.
		my @search;
		foreach my $field (@{ $traitMap{unique} }, $traitMap{primary}) {
			Cake::Validation::checkType($definition{$field}{isa}, $args) or next;
			push(@search, ($field, $args));
		}
		return $class->_find($class, \@search);
	}
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

sub _build {
	my ($class, $key) = @_;
	my $object = {};
	bless $object, $class;
	
	$object->_pk($key) if $key;
	map { $_->($object) } @{ $class->__initCallbacks };
	
	return $object;
}

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
	map {
		Cake::Validation::enforceType($definition{$_}{isa}, $parameters->{$_}, $_);
	} keys %{$parameters};
	
	$class->_preCreate($parameters);
	my $object   = $class->_create($class, $parameters, \%definition);
	$class->_postCreate($object, $parameters);
	
	return $object;
};

sub update {
	my ($invocant, $parameters, $where ) = @_;
	
	my %definition = %{ $invocant->__fieldTraitMap() };
	my %traitMap   = %{ $invocant->__traitFieldMap() };

	map {
		Cake::Exception::ReadOnly->throw({field=> $_})
			if $definition{$_}{readOnly};
		Cake::Exception::Required->throw({field => $_})
			if !defined $parameters->{$_} && $definition{$_}{required};
		Cake::Validation::enforceType($definition{$_}{isa}, $parameters->{$_}, $_);
	} keys %{$parameters};

	if(ref($invocant)) {
		return $invocant->_update($invocant, $parameters, \%definition);
	}
	else {
		defined $where or Cake::Exception::DataLoss->throw();
		return $invocant->_update($invocant, $parameters, \%definition, $where);
	}
}

sub delete {
	my ($invocant, $where) = @_;
	if(ref($invocant)) {
		return $invocant->_delete($invocant);
	}
	else {
		defined $where or Cake::Exception::DataLoss->throw();
		return $invocant->_delete($invocant, $where);
	}
}

#private inherited methods

=pod

The _fields method lays out the description of the fileds in a class.
Should specify if the field is index (default), unique, read-only, required or
the primary key.
will eventually also specify the 'type' of the field.
{
	field => {
		primary  => 0,
		required => 1,
		index     => 0,
		unique  => 1,
		readOnly => 1,
		isa => "INTEGER'
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
			delete $definition->{$field}{index};
		}

		if ( $definition->{$field}{primary} ) {
			delete $definition->{$field}{index};
			delete $definition->{$field}{unique};
			$definition->{$field}{readOnly} = 1;
		}

		foreach my $trait ( keys %{ $definition->{$field} } ) {
			next if $trait eq 'isa';
			if ($trait eq 'primary') {
				Cake::Exception::DefinitionError->throw( { trait => 'primary' } ) if $reverseDefinition->{primary};
				$reverseDefinition->{primary} = $field;
				next;
			}
			my $traitSet = $definition->{$field}{$trait};
			if ($traitSet) {
				push( @{ $reverseDefinition->{$trait} }, $field );
			}
		}
		push( @{ $reverseDefinition->{isa}{$definition->{$field}{isa}} }, $field );
	}

	unless ( exists $reverseDefinition->{primary} )
	{
		Cake::Exception::DefinitionError->throw( { trait => 'primary' } );
	}

	$class->__fieldTraitMap( $definition );
	$class->__traitFieldMap( $reverseDefinition );
}

=pod

the _has_a method describes relationships that a class has,
where an object in the class has a singular relationship to another object in the given class.
maps the relation name to an array where the first element the local field that is referencing,
the second field is the class that is referenced,
and the third is the name of the field that is being refernced.
equivelent to a forign key relationship, where THIS.field references OTHER.givenField
if the value is not a arrayref, it assumes the primary keys of the classes.
{
	Owner => [owner => 'Apps::Memo::User' => 'name'],
	Sender => [sender => 'Apps::Memo::User' => 'name']
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

	no strict qw(refs);
	
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
	
	foreach my $action (@{ $class->__postSetupActions }) {
		$action->($class);
	}
	
	Cake::Role::installRoles($class, $class->__roles);
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
			return $class->__get_field($self, $traits, $field);
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
			Cake::Validation::enforceType($traits->{isa}, @_[0], $field);
			return $class->__set_field($self, $traits, $field, @_ );
		}
		else {
			return $class->__get_field($self, $traits, $field);
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
			Cake::Exception::ReadOnly->throw;
		}
		else {
			return $class->__get_has_a($self, $details, $field);
		}
	}
}

sub ___mk_has_many {
	my $class    = shift;
	my $field     = shift;
	my $details = shift;

	return subname "${class}::${field}" => sub {
		my $self  = shift;
		my $order = shift;
		my $options = shift;
		if (@_) {
			Cake::Exception::ReadOnly->throw;
		}
		else {
			return $class->__get_has_many($self, $details, $field, $order, $options);
		}
	}
}

sub _pk {
	my ($self, $key) = @_;
	return $self->{_pk} ||= $key;
}


sub _local {
	my $self = shift;
	my $caller = shift || caller;
	my $engine = $caller->__engine;

	return $self->{$engine} ||= {};
}

sub _classData {
	my $self = shift;
	my $class = ref($self);
	my $caller = caller;
	
	return $caller->__ClassData->{$class} ||= {};
	
}

sub _registerInitCallback {
	my ($class, $callback) = @_;
	push(@{$class->__initCallbacks}, $callback);
}

sub _CLASS {
	my ($invocant) = @_;
	my $ref = ref($invocant);
	return $ref? $ref : $invocant;
}

sub _defineEngineTraits {
	my ($class, $traits) = @_;
	
	while (my ($traitName, $default) = each %{$traits}) {
		$class->mk_classdata($traitName => $default);
	}
}

sub _installPostSetupActions {
	my ($class, $action) = @_;
	return unless defined $action;
	push(@{$class->__postSetupActions}, $action);
}

1;
