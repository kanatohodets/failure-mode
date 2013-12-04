package Agent::Containers::Conditions::Net;
use Mojo::Base 'Agent::Containers::Conditions::Condition';

sub new {
    my $self = shift->SUPER::new(@_);
    return $self;
}

sub tc_netem_command_base {
    my $self = shift;
    my $container_pid = $self->container->true_pid;
    return "ip netns exec $container_pid tc qdisc add dev eth0 root netem";
}

sub iptables_command_base {
    my $self = shift;
    my $container_pid = $self->container->true_pid;
    return "ip netns exec $container_pid iptables -A INPUT -s ";
}

sub disable_netem {
    my $self = shift;
    my $container_pid = $self->container->true_pid;
    system("ip netns exec $container_pid tc qdisc del dev eth0 root") if $self->netem_is_active;
}

sub disable_iptables {
    my $self = shift;
    my $container_pid = $self->container->true_pid;
    system("ip netns exec $container_pid iptables -F") if $self->iptables_is_active;
}

sub netem_is_active {
    my $self = shift;
    my $container_pid = $self->container->true_pid;
    my $output = `ip netns exec $container_pid tc qdisc show dev eth0`;
    return index($output, 'netem') != -1;
}

sub iptables_is_active {
    my $self = shift;
    my $container_pid = $self->container->true_pid;
    my $output = `ip netns exec $container_pid iptables --list`;
    return index($output, 'DROP') != -1 || index($output, 'REJECT') != -1;
}


1;
