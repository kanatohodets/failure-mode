package Agent::Containers::Container;
use Mojo::Base -base;
use List::Util qw(first);
use DatabaseConnection;
use Agent::Containers::Conditions;
use Data::Dumper qw(Dumper);

use Mojo::UserAgent;
use Mojo::IOLoop;

has namespace_path => '/sys/fs/cgroup/devices/lxc';
has id => undef;
has db => sub { DatabaseConnection::get(); };
has conditions => sub { \1; };
has true_pid => undef;
has stream_id => undef;

sub new {
    my $self = shift->SUPER::new(@_);
    my $conditions = Agent::Containers::Conditions->new({container => $self});
    $self->conditions($conditions);
    return $self;
}

sub start {
    my $self = shift;
    my $image_name = shift;
    my $container_id = `docker run -d $image_name`;
    $self->id($self->_get_full_id($container_id));
    $self->_init();
    return $self->id;
}

sub add_condition {
    my $self = shift;
    my ($type, $subtype) = (shift, shift);
    my $args = shift;
    say "add condition: $type, $subtype";
    say Dumper($args);
    #$self->conditions->add($type, $subtype, $args);
    #$self->apply_conditions();
}

sub remove_condition {
    my $self = shift;
    my ($type, $subtype) = @_;
    $self->conditions->remove($type, $subtype);
}

sub apply_conditions {
    my $self = shift;
    $self->conditions->apply();
}

sub _init {
    my $self = shift;
    my $ua = Mojo::UserAgent->new;
    $ua->inactivity_timeout(0);
    my $app_ip = '172.17.42.1:3005';
    my $id = $self->id;
    my $true_pid = $self->_create_netns();
    $self->_register();
    #change tshark args based on role of container
    open(my $fh, "ip netns exec $true_pid tshark -i eth0 |");
    my $stream = Mojo::IOLoop::Stream->new($fh)->timeout(0);
    my $stream_id = Mojo::IOLoop->stream($stream);
    $self->stream_id($stream_id);
    $ua->websocket("ws://$app_ip/container/$id/net" => sub {
        my ($ua, $tx) = @_;
        say 'WebSocket handshake failed!' and return unless $tx->is_websocket;

        $tx->on(finish => sub {
            my ($tx, $code, $reason) = @_;
        });

        $tx->on(message => sub { 1; });

        $stream->on(data => sub {
            my ($stream, $bytes) = @_;
            $tx->send($bytes);
        });
    });
}

sub stop {
    my $self = shift;
    my $container_id = $self->id;
    Mojo::IOLoop->remove($self->stream_id);
    system("docker stop $container_id");
    $self->_unregister();
}

sub _register {
    my $self = shift;
    my $json = Mojo::JSON->new;
    my ($container_id, $true_pid) = ($self->id, $self->true_pid);

    my $details = `docker inspect $container_id`;
    $details = $json->decode($details)->[0];
    my $ip_address = $details->{'NetworkSettings'}->{'IPAddress'};
    my $lxc_pid = $details->{'NetworkSettings'}->{'IPAddress'};
    my $date_started = $details->{'State'}->{'StartedAt'};
    my $image_id = $details->{'Image'};

    my $sth = $self->db->prepare("
        INSERT INTO container
        (
            container_id,
            parent_image_id,
            ip_address,
            true_pid,
            container_pid,
            date_started
        ) VALUES (?, ?, ?, ?, ?, ?)");
    $sth->execute($container_id, $image_id, $ip_address, $true_pid, $lxc_pid, $date_started);
}

sub _unregister {
    my $self = shift;
    my $sth = $self->db->prepare("
        DELETE FROM container WHERE container_id = ?
    ");
    $sth->execute($self->id);
}

sub _create_netns {
    my $self = shift;
    my $container_id = $self->id;
    my $true_pid = $self->_get_true_pid($container_id);
    chomp($true_pid);
    system('mkdir -p /var/run/netns');
    system("rm /var/run/netns/$true_pid") if -e "/var/run/netns/$true_pid";
    system("ln -s /proc/$true_pid/ns/net /var/run/netns/$true_pid");
    $self->true_pid($true_pid);
    return $true_pid;
}

sub _get_true_pid {
    my $self = shift;
    my $container_id = $self->id;
    my $namespace = $self->namespace_path . '/' . $container_id;
    open my $tasks_fh, '<', "$namespace/tasks" or warn "ARGH ARGH NO FILE TO OPEN";
    my $true_pid = <$tasks_fh>;
    close $tasks_fh;
    return $true_pid;
}

sub _get_full_id {
    my $self = shift;
    my $short_id = shift;
    my $json = Mojo::JSON->new;
    my $details = `docker inspect $short_id`;
    $details = $json->decode($details)->[0];
    return $details->{ID};
}

sub is_running {
    my $self = shift;
    my $id_prefix = substr $self->id, 0, 12;
    return first { index($_, $id_prefix) >= 0 } $self->_get_running_containers;
}

sub _get_running_containers {
    my $self = shift;
    my @container_ids = `docker ps | tail -n +2 | awk '{print \$1}'`;
    return @container_ids;
}

1;
