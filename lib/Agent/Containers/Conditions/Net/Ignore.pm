package Agent::Containers::Conditions::Net::Ignore;
use Mojo::Base 'Agent::Containers::Conditions::Net';

has columns => sub { [ qw(target) ] };

sub new {
    my $self = shift->SUPER::new(@_);
    $self->type_id($self->SUPER::NET_IGNORE);
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
    my $command = "$target -j DROP";
    return $command;

}

1;
