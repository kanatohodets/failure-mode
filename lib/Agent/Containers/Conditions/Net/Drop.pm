package Agent::Containers::Conditions::Net::Drop;
use Mojo::Base 'Agent::Containers::Conditions::Net';

has columns => sub { [ qw(base correlation) ] };

sub new {
    my $self = shift->SUPER::new(@_);
    $self->type_id($self->SUPER::NET_DROP);
    return $self;
}

sub disable {
    my $self = shift;
    $self->SUPER::disable_netem();
}

sub prepare_command {
    my $self = shift;
    my $hashref = $self->get();
    my ($base, $correlation) = @$hashref{qw(base correlation)};
    return if not defined $base;
    my $command = " loss " . $base . "% ";
    $command .= $correlation . "% " if defined $correlation;
    return $command;
}

1;
