package Agent::Containers;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use Agent::Containers::Container;

sub stop {
    my $self = shift;
    my $container_id = $self->stash('id');
    my $container = $self->_get_container_object($container_id);
    if ($container) {
        $container->stop();
        $self->render(json => {message => "OK"});
    } else {
        $self->render(json => {message => "no such container"}, status => 404);
    }
}

sub add_condition {
    my $self = shift;
    my $json = Mojo::JSON->new;
    my $container_id = $self->stash('id');
    my $type = $self->stash('type');
    my $subtype = $self->stash('subtype');
    my $args = $json->decode($self->req->body);
    my $container = $self->_get_container_object($container_id);
    if ($container) {
        $container->add_condition($type, $subtype, $args);
        $self->render(json => {message => "OK"});
    } else {
        $self->render(json => {message => "no such container"}, status => 404);
    }
}

sub list_conditions {
    my $self = shift;
    my $container_id = $self->stash('id');
    my $container = $self->_get_container_object($container_id);
    if ($container) {
        my $conditions = $container->list_conditions;
        $self->render(json => $conditions);
    } else {
        $self->render(json => {message => "no such container"}, status => 404);
    }
}

sub remove_condition {
    my $self = shift;
    my $container_id = $self->stash('id');
    my $type = $self->stash('type');
    my $subtype = $self->stash('subtype');
    my $container = $self->_get_container_object($container_id);
    if ($container) {
        $container->remove_condition($type, $subtype);
        $self->render(json => {message => "OK"});
    } else {
        $self->render(json => {message => "no such container"}, status => 404);
    }
}

sub remove_conditions {
    my $self = shift;
    my $container_id = $self->stash('id');
    my $container = $self->_get_container_object($container_id);
    if ($container) {
        $container->remove_all_conditions();
        $self->render(json => {message => "OK"});
    } else {
        $self->render(json => {message => "no such container"}, status => 404);
    }
}

sub inspect {
    my $self = shift;
    my $json = Mojo::JSON->new;
    my $container_id = $self->stash('id');
    my $details = $self->_paranoid_inspect($container_id);
    $details = $json->decode($details);
    $self->render(json => $details);
}

sub list {
    my $self = shift;
    my @raw_containers = `docker ps | tail -n +2`;
    my $containers = [];
    foreach my $container (@raw_containers) {
        chomp($container);
        # turn the goofy space-separated field into - delimited.
        $container =~ s/(\w)[\W]{2,}(\w)/$1-$2/g;
        # and trim the end whitespace
        $container =~ s/[\W]+$//;
        my ($id, $image, $command, $created, $status, $ports, $names) = split "-", $container;

        push $containers, {
            id => $id,
            image => $image,
            command => $command,
            created => $created,
            status => $status,
            ports => $ports,
            names => $names
        };
    }

    $self->render(json => $containers);
}

sub _get_container_object {
    my $self = shift;
    my $container_id = shift;
    my $output = $self->_paranoid_inspect($id);
    return '' if $output =~ /No such image or container/ or !$output;
    return Agent::Containers::Container->new($container_id);
}

sub _paranoid_inspect {
    my $id = shift;
    my $only_hex_id = $id =~ /^[0-9a-f]*$/;
    return `docker inspect $id` if $only_hex_id;
    return '';
}

1;
