package Agent::Containers;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

has namespace_path => '/sys/fs/cgroup/devices/lxc';

sub start {
    my $self = shift;
    #going to be a http param
    my $image_name = $self->param('image_name');
    # images should be created from dockerfiles which specify ports to be
    # exposed.
    my $container_id = `docker run -d $image_name`;
    my $true_pid = $self->_create_netns($container_id);
    $self->_register_container($container_id, $true_pid);
    #fire up tshark and start listening
}

sub stop {
    my $self = shift;
    my $container_id = $self->stash('id');
    system("docker stop $container_id");
}

sub _register_container {
    my $self = shift;
    my $json = Mojo::JSON->new;
    my ($container_id, $true_pid) = @_;
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
    $sth->bind_param($container_id, $image_id, $ip_address, $true_pid, $lxc_pid, $date_started);
    $sth->execute();
}

sub _create_netns {
    my $self = shift;
    my $container_id = shift;
    my $true_pid = $self->_get_true_pid($container_id);
    system('mkdir -p /var/run/netns');
    system("rm -f /var/run/netns/$true_pid");
    system("ln -s /proc/$true_pid/ns/net /var/run/netns/$true_pid");
    $true_pid;
}

sub _get_true_pid {
    my $self = shift;
    my $container_id = shift;
    my $namespace = $self->namespace_path . '/' . $container_id;
    open my $tasks_fh, '<', "$namespace/tasks";
    <$tasks_fh>;
}

1;
