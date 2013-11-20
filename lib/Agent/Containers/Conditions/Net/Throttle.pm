package Agent::Containers::Conditions::Net::Throttle;
use Mojo::Base 'Agent::Containers::Conditions::Condition';

has columns => sub { [ qw(base correlation) ] };

sub new {
    my $self = shift->SUPER::new(@_);
    $self->type_id($self->SUPER::NET_THROTTLE);
    return $self;
}

sub prepare_command {
    my $self = shift;
    my $hashref = $self->get();
}

1;
