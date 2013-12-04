package Agent::Containers::Conditions::Net::Reject;
use Mojo::Base 'Agent::Containers::Conditions::Net';

has columns => sub { [ qw(target) ] };

sub new {
    my $self = shift->SUPER::new(@_);
    $self->type_id($self->SUPER::NET_REJECT);
    return $self;
}

sub disable {
    my $self = shift;
    $self->SUPER::disable_iptables();
}

sub prepare_command {
    my $self = shift;
    my $hashref = $self->get();
    my ($target) = @$hashref{qw(target)};
    return if not defined $target;
    my $command = "$target -j REJECT";
    return $command;
}

1;
