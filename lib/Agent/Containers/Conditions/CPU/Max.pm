package Agent::Containers::Conditions::CPU::Max;
use Mojo::Base 'Agent::Containers::Conditions::Condition';

has columns => sub { [ qw() ] };

sub new {
    my $self = shift->SUPER::new(@_);
    $self->type_id($self->SUPER::CPU_MAX);
    return $self;
}

sub prepare_command {
    my $self = shift;
    my $hashref = $self->get();
}

1;
