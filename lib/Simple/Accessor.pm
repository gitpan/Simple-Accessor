package Simple::Accessor;
{
  $Simple::Accessor::VERSION = '0.10';
}
use strict;
use warnings;

# ABSTRACT: a light and simple way to provide accessor in perl

=head1 NAME
Simple::Accessor - very simple, light and powerful accessor

=head1 VERSION

version 0.10

=head1 DESCRIPTION

Simple::Accessor provides a simple object layer without any dependency.
It can be used where other ORM could be considered too heavy.
But it has also the main advantage to only need one single line of code.

It can be easily used in scripts...

=head1 Usage

Create a package and just call Simple::Accessor.
The new method will be imported for you, and all accessors will be directly
accessible.

    package MyClass;
    # that s all what you need ! no more line required
    use Simple::Accessor qw{foo bar cherry apple};

You can now call 'new' on your class, and create objects using these attributes
    
    package main;    
    use MyClass;

    my $o = MyClass->new() 
        or MyClass->new(bar => 42) 
        or MyClass->new(apple => 'fruit', cherry => 'fruit', banana => 'yummy');

You can get / set any value using the accessor
    
    is $o->bar(), 42;
    $o->bar(51);
    is $o->bar(), 51;
    
You can provide your own init method that will be call by new with default args.
This is optional.

    package MyClass;

    sub initialize {
        my ($self, %opts) = @_;
        
        $self->foo(12345);
    }

You can also provide individual initializers 

    sub _initialize_bar {
        # will be used if no value has been provided for bar
        1031;
    }

    sub _initialize_cherry {
        'red';
    }

You can even use a very basic but useful hook system.
Any false value return by before or validate, will stop the setting process.
Be careful with the after method, as there is no protection against infinite loop.

    sub _before_foo {
        my ($self, $v) = @_;
    
        # do whatever you want with $v
        return 1 or 0;
    }

    sub _validate_foo {
        my ($self, $v) = @_;
        # invalid value ( will not be set )
        return 0 if ( $v == 42);
        # valid value
        return 1;        
    }

    sub _after_cherry {
        my ($self) = @_;
        
        # use the set value for extra operations
        $self->apple($self->cherry());
    }
    
=head1 METHODS

None. The only public method provided is the classical import.

=cut

sub import {
    my ( $class, @attr ) = @_;

    my $from = caller();

    _add_new($from);
    _add_accessors( to => $from, attributes => \@attr );
}

sub _add_new {
    my $class = shift;
    return unless $class;

    my $init = 'initialize';
    my $new  = $class . '::new';
    {
        no strict 'refs';
        *$new = sub {
            my ( $class, %opts ) = @_;

            my $self = bless {}, $class;

            # set values if attributes exist
            map {
                eval { $self->$_( $opts{$_} ) }
            } keys %opts;

            if ( defined &{ $class . '::' . $init } ) {
                return unless $self->$init(%opts);
            }

            return $self;
        };
    }
}

sub _add_accessors {
    my (%opts) = @_;

    return unless $opts{to};
    my @attributes = @{ $opts{attributes} };
    return unless @attributes;

    foreach my $att (@attributes) {
        my $accessor = $opts{to} . "::$att";

        # allow symbolic refs to typeglob
        no strict 'refs';
        *$accessor = sub {
            my ( $self, $v ) = @_;
            if ( defined $v ) {
                foreach (qw{before validate set after}) {
                    if ( $_ eq 'set' ) {
                        $self->{$att} = $v;
                        next;
                    }
                    my $sub = '_' . $_ . '_' . $att;
                    if ( defined &{ $opts{to} . '::' . $sub } ) {
                        return unless $self->$sub($v);
                    }
                }
            }
            elsif ( !defined $self->{$att} ) {

                # try to initialize the value
                my $sub = '_' . 'initialize' . '_' . $att;
                if ( defined &{ $opts{to} . '::' . $sub } ) {
                    $self->{$att} = $self->$sub();
                }
            }

            return $self->{$att};
        };
    }
    @attributes = ();
}

1;

=head1 CONTRIBUTE

You can contribute to this project on github https://github.com/atoomic/Simple-Accessor

=cut

__END__
