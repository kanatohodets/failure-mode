package Agent::Containers::Conditions;
use Mojo::Base -base;

has container => sub { \1; };

# really this needs to be in the db
has conditions => sub { 
    {
        Net => {},
        Disk => {},
        CPU => {},
        Mem => {}
    }
};

has db => sub { DatabaseConnection::get() };

sub new {
    my $self = shift->SUPER::new(@_);
}

sub get_all {
    my $self = shift;
    my $container_id = shift;
    my $sth = $self->db->prepare("
        SELECT * FROM container_condition WHERE container_id = ?
    ");
    $sth->execute($container_id);
    #need to fetch all the specific conditions out, then objectify them.
    return $sth->fetchall_arrayref;
}

sub add {
    my $self = shift;
    my $type = ucfirst(shift);
    my $subtype = ucfirst(shift);
    my $args = shift;
    no strict 'refs';
    #Conditions::Net::Delay, for example.
    my $condition = "Conditions::$type::$subtype"->new({
        container => $self->container,
        args => $args
    });
    use strict 'refs';
    $self->conditions->{$type}->{$subtype} = $condition;
}

sub remove {
    my $self = shift;
    my ($type, $subtype) = @_;
    $self->conditions->{$type}->{$subtype}->remove() if exists $self->conditions->{$type}->{$subtype};
    delete $self->conditions->{$type}->{$subtype};
}

sub apply {
    my $self = shift;
    $self->_apply_net();
    $self->_apply_disk();
    $self->_apply_cpu();
    $self->_apply_mem();
}

sub _apply_net {
    my $self = shift;
    $self->_apply_net_loss_delay();
    $self->apply_net_isolation();
}

sub _apply_net_loss_delay {
    my $self = shift;
    my $loss_args = $self->conditions->{Net}->{Loss}->args if exists $self->conditions->{Net}->{Loss};
    my $delay_args = $self->conditions->{Net}->{Delay}->args if exists $self->conditions->{Net}->{Delay};

    $self->_clear_net_loss_delay();
    my $container_pid = $self->container->true_pid;
    my $command_base = "ip netns exec $container_pid tc qdisc add dev eth0 root netem";
    $command_base .= 'delay ' . join ' ', $delay_args if defined $delay_args;
    $command_base .= 'loss ' . join ' ', $loss_args if defined $loss_args;
    system($command_base);
}

sub _clear_net_loss_delay {
    my $self = shift;
    my $container_pid = $self->container->true_pid;
    system("ip netns exec $container_pid tc qdisc del dev eth0");
}

sub _apply_net_isolation { };

sub _apply_disk { }
sub _apply_cpu { }
sub _apply_mem { }

1;
