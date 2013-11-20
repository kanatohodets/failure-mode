package Agent::Containers::Conditions::Net::Ignore;
use Mojo::Base 'Agent::Containers::Conditions::Net';

has columns => sub { [ qw() ] };

sub new {
    my $self = shift->SUPER::new(@_);
    $self->type_id($self->SUPER::NET_IGNORE);
    return $self;
}

sub prepare_command {
    my $self = shift;
    my $hashref = $self->get();
}

1;
