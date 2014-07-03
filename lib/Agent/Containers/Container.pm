package Agent::Containers::Container;
use Mojo::Base -base;
use Agent::Containers::Conditions;
use Agent::Containers qw(inspect);

use Mojo::UserAgent;
use Mojo::IOLoop::ReadWriteFork;

has namespace_path => '/sys/fs/cgroup/devices/lxc';
has id => undef;
has db => sub { DatabaseConnection::get(); };
has conditions => sub { \1; };
has true_pid => undef;
has stream_id => undef;
has stream => undef;
has ua => sub { state $ua = Mojo::UserAgent->new };

sub new {
    my $self = shift->SUPER::new(@_);
    my $conditions = Agent::Containers::Conditions->new({container => $self});
    $self->conditions($conditions);
    # host may have restarted or something, need to make sure the ip and true
    # pid are still correct
    $self->_update if $self->true_pid;
    return $self;
}

sub start {
    my $self = shift;
    my $image_name = shift;
    my $container_name = shift;
    my $cpu_shares = shift // 1000;
    my $link_source_name = shift // '';
    my $link_local_name = shift // '';
    my $port_to_forward = shift // '';
    my $port_string = '';
    $port_string = "-p $port_to_forward:$port_to_forward" if $port_to_forward;
    say $port_string;

    my $link_string = '';
    $link_string = "-link $link_source_name:$link_local_name" if $link_source_name && $link_local_name;
    say $link_string;

    my $container_id = `docker run -c $cpu_shares -d $port_string $link_string -name $container_name $image_name`;
    if ($container_id) {
        $self->id(_get_full_id $container_id);
        $self->_init();
        return $self->id;
    }
    return;
}

sub list_conditions {
    my $self = shift;
    my $conditions = $self->conditions->get_all;
    # above is a hashref, we're just interested in the values for JSON-ification
    { conditions => [values %$conditions]};
}

sub add_condition {
    my $self = shift;
    my ($type, $subtype) = (shift, shift);
    my $args = shift;
    $self->conditions->add($type, $subtype, $args);
    $self->enable_conditions();
}

sub remove_condition {
    my $self = shift;
    my ($type, $subtype) = @_;
    $self->conditions->remove($type, $subtype);
}

sub remove_all_conditions {
    my $self = shift;
    $self->conditions->remove_all;
}

sub enable_conditions {
    my $self = shift;
    $self->conditions->enable();
}

sub disable_conditions {
    my $self = shift;
    $self->conditions->disable();
}

sub _init {
    my $self = shift;
    $self->ua->inactivity_timeout(0);
    my $app_ip = '127.0.0.1:3008';
    my $id = $self->id;
    my $true_pid = $self->_create_netns();
    $self->_register();
    #change tshark args based on role of container
    #say "starting tshark";
    #open(my $fh, "-|", "ip netns exec $true_pid tshark -i eth0");
    #my $stream = Mojo::IOLoop::Stream->new($fh)->timeout(0);
    #my $stream_id = Mojo::IOLoop->stream($stream);
    #$self->stream_id($stream_id);
    #$self->stream($stream);
    #say "starting ua websocket";
    #$self->ua->websocket("ws://$app_ip" => sub {
    #    my ($ua, $tx) = @_;
    #    if (!$tx->is_websocket) {
    #        warn 'WebSocket handshake failed!';
    #        #Mojo::IOLoop->remove($stream_id);
    #        #return;
    #    }
    #
    #    $tx->on(finish => sub {
    #        my ($tx, $code, $reason) = @_;
    #    });
    #
    #    $tx->on(message => sub { 1; });
    #
    #    $stream->on(read => sub {
    #        my ($stream, $bytes) = @_;
    #        say "tshark: ", $bytes;
    #    #    $tx->send($bytes);
    #    });
    #});
    #say "finished ua websocket thingy";
}

sub stop {
    my $self = shift;
    my $container_id = $self->id;
    Mojo::IOLoop->remove($self->stream_id) if $self->stream_id;
    system("docker stop $container_id");
    system("docker rm $container_id");
    $self->_unregister();
}

sub _register {
    my $self = shift;
    my $sth = $self->db->prepare("
        INSERT INTO container
        (
            container_id,
            true_pid
        ) VALUES (?, ?)");
    $sth->execute($self->id, $self->true_pid);
}

sub _update {
    my $self = shift;
    my $true_pid = $self->_create_netns;
    my $sth = $self->db->prepare("
        UPDATE container
        SET
            true_pid = ?,
        WHERE
            container_id = ?");
    $sth->execute($true_pid, $self->id);
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
    return $true_pid;
}

sub _remove_netns {
    my $self = shift;
    my $true_pid = $self->true_pid;
    system("rm /var/run/netns/$true_pid");
}

sub _get_true_pid {
    my $self = shift;
    my $container_id = $self->id;
    my $namespace = $self->namespace_path . '/' . $container_id;
    open my $tasks_fh, '<', "$namespace/tasks" or warn "ARGH ARGH NO FILE TO OPEN";
    my $true_pid = <$tasks_fh>;
    close $tasks_fh;
    chomp($true_pid);
    $self->true_pid($true_pid);
    return $true_pid;
}

sub _get_full_id {
    my $id = shift;
    my $details = inspect $id;
    return $details->{ID} // '';
}

1;
