package Agent::Containers::Conditions;
use Mojo::Base -base;
use DatabaseConnection;
use Data::Dumper qw(Dumper);
use experimental qw(postderef signatures);
## no critic ProhibitSubroutinePrototypes

use Agent::Containers::Conditions::Net::Drop;
use Agent::Containers::Conditions::Net::Delay;
use Agent::Containers::Conditions::Net::Ignore;
use Agent::Containers::Conditions::Net::Reject;
use Agent::Containers::Conditions::Net::Throttle;
use Agent::Containers::Conditions::Disk::Fill;
use Agent::Containers::Conditions::Mem::Fill;
use Agent::Containers::Conditions::CPU::Max;

has container => sub { \1; };

# really this needs to be in the db
has conditions => sub {
    {
        net => {},
        disk => {},
        cpu => {},
        mem => {}
    }
};

has condition_names => sub {
    {
        100 => ['net', 'delay'],
        101 => ['net', 'drop'],
        102 => ['net', 'isolation'],
        103 => ['net', 'throttle'],
        104 => ['net', 'reject'],
        105 => ['net', 'ignore'],
        200 => ['disk', 'fill'],
        300 => ['memory', 'fill'],
        400 => ['cpu', 'max'],
    }
};

has db => sub { DatabaseConnection::get() };

sub new {
    my $self = shift->SUPER::new(@_);
    my $hashref = $self->get_all();
    $self->_load_conditions($hashref);
    return $self;
}

sub _load_conditions {
    my $self = shift;
    my $hashref = shift;
    foreach my $condition_id (keys $hashref->%*) {
        my ($condition_type, $condition_id) = @{$hashref->{$condition_id}}{qw(condition_type condition_id)};
        my ($type, $subtype) = @{$self->condition_names->{$condition_type}};
        my $condition = $self->get_condition($type, $subtype, undef, $condition_id);
        $self->conditions->{$type}->{$subtype} = $condition;
    }
}

sub get_all {
    my $self = shift;
    my $container_id = $self->container->id;
    my $sth = $self->db->prepare("
        SELECT * FROM container_condition WHERE container_id = ?
    ");
    $sth->execute($container_id);
    #need to fetch all the specific conditions out, then objectify them.
    return $sth->fetchall_hashref('container_condition_id');
}

sub add {
    my $self = shift;
    my $type = shift;
    my $subtype = shift;
    my $args = shift;
    #say Dumper($args);
    my $condition = $self->get_condition($type, $subtype, $args->{'args'});
    $condition->save;
    $self->conditions->{$type}->{$subtype} = $condition;
}

sub remove {
    my $self = shift;
    my ($type, $subtype) = (shift, shift);
    my $condition = $self->get_condition($type, $subtype);
    $condition->remove();
    delete $self->conditions->{$type}->{$subtype};
    $self->enable();
}

sub remove_all {
    my $self = shift;
    my $container_id = $self->container->id;
    my $sth = $self->db->prepare("
        DELETE FROM container_condition WHERE container_id = ?
    ");
    $sth->execute($container_id);
    $self->disable();
    $self->conditions({});
}

sub get_condition {
    my $self = shift;
    my ($type, $subtype) = (ucfirst(lc(shift)), ucfirst(lc(shift)));
    my $args = shift;
    my $condition_id = shift;
    my $params = {
        container => $self->container,
        type => lc($type),
        subtype => lc($subtype)
    };
    $params->{args} = $args if defined $args;
    $params->{id} = $condition_id if defined $condition_id;

    #Agent::Containers::Conditions::Net::Delay, for example
    no strict 'refs';
    my $condition = eval {
        "Agent::Containers::Conditions::$type::$subtype"->new($params);
    };
    warn $@ if $@;
    return $@ if $@;

    return $condition;
}

sub enable {
    my $self = shift;
    $self->_enable_net();
    $self->_enable_disk();
    $self->_enable_cpu();
    $self->_enable_mem();
}

sub disable {
    my $self = shift;
    $self->_disable_net();
    $self->_disable_disk();
    $self->_disable_cpu();
    $self->_disable_mem();
}

sub _disable_net {
    my $self = shift;
    $self->_disable_netem;
    $self->_disable_iptables;
}

sub _disable_netem {
    my $self = shift;
    # net drop/delay share a device, so disabling one disables the other.
    # double disabling isn't a huge deal.
    my $net_drop = $self->conditions->{net}->{drop};
    my $net_delay = $self->conditions->{net}->{delay};
    my $netem_net_condition = $net_drop // $net_delay;

    $netem_net_condition->disable_netem() if defined $netem_net_condition;
}

sub _disable_iptables {
    my $self = shift;
    my $net_reject = $self->conditions->{net}->{reject};
    my $net_ignore = $self->conditions->{net}->{ignore};
    my $iptables_net_condition = $net_reject // $net_ignore;
    $iptables_net_condition->disable_iptables() if defined $iptables_net_condition;
}

sub _enable_net {
    my $self = shift;
    $self->_enable_net_drop_delay();
    $self->_enable_net_reject_ignore();
}

sub _enable_net_drop_delay {
    my $self = shift;
    my $net_drop = $self->conditions->{net}->{drop};
    my $net_delay = $self->conditions->{net}->{delay};
    my $net_condition = $net_drop // $net_delay;
    #say "I have a net condition?" if defined $net_condition;
    #say Dumper($net_condition);
    return if !defined $net_condition;

    my $drop_cmd = $net_drop->prepare_command if defined $net_drop;
    my $delay_cmd = $net_delay->prepare_command if defined $net_delay;

    $self->_clear_net_drop_delay();
    my $command = $net_condition->tc_netem_command_base;
    $command .= $drop_cmd if defined $drop_cmd;
    $command .= $delay_cmd if defined $delay_cmd;
    say "command: $command";
    system($command);
}

sub _clear_net_drop_delay {
    my $self = shift;
    my $net_condition = $self->conditions->{net}->{drop} // $self->conditions->{net}->{delay};
    return if !defined $net_condition;
    $net_condition->disable_netem();
}

sub _clear_net_reject_ignore {
    my $self = shift;
    my $net_condition = $self->conditions->{net}->{reject} // $self->conditions->{net}->{ignore};
    return if !defined $net_condition;
    $net_condition->disable_iptables();
}

sub _enable_net_reject_ignore { 
    my $self = shift;
    my $net_reject = $self->conditions->{net}->{reject};
    my $net_ignore = $self->conditions->{net}->{ignore};
    my $net_condition = $net_reject // $net_ignore;
    #say "I have a net condition?" if defined $net_condition;
    #say Dumper($net_condition);
    return if !defined $net_condition;

    my $reject_cmd = $net_reject->prepare_command if defined $net_reject;
    my $ignore_cmd = $net_ignore->prepare_command if defined $net_ignore;

    $self->_clear_net_reject_ignore();
    my $full_reject_cmd = '';
    $full_reject_cmd = $net_condition->iptables_command_base . $reject_cmd if $reject_cmd;

    my $full_ignore_cmd = '';
    $full_ignore_cmd = $net_condition->iptables_command_base . $ignore_cmd if $ignore_cmd;
    say "commands: ", $full_reject_cmd, $full_ignore_cmd;

    system($full_reject_cmd) if $full_reject_cmd;
    system($full_ignore_cmd) if $full_ignore_cmd;
}

sub _enable_disk { }
sub _enable_cpu { }
sub _enable_mem { }

sub _disable_disk { }
sub _disable_cpu { }
sub _disable_mem { }

1;
