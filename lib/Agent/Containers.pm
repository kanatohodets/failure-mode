package Agent::Containers;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

use experimental qw(postderef signatures);
use Agent::Containers::Container;
use Agent::Util qw(looks_like_sha1);

## no critic ProhibitSubroutinePrototypes

our @EXPORT_OK = qw(inspect);

sub add_condition ($self) {
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

sub list_conditions ($self) {
    my $container_id = $self->stash('id');
    my $container = $self->_get_container_object($container_id);
    if ($container) {
        my $conditions = $container->list_conditions;
        $self->render(json => $conditions);
    } else {
        $self->render(json => {message => "no such container"}, status => 404);
    }
}

sub remove_condition ($self) {
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

sub remove_conditions ($self) {
    my $container_id = $self->stash('id');
    my $container = $self->_get_container_object($container_id);
    if ($container) {
        $container->remove_all_conditions();
        $self->render(json => {message => "OK"});
    } else {
        $self->render(json => {message => "no such container"}, status => 404);
    }
}

sub inspect ($container_id) {
    my $json = Mojo::JSON->new;
    my $details = _paranoid_inspect $container_id;
    $details = $json->decode($details)->[0];
    return $details;
}

sub get ($self) {
    my $json = Mojo::JSON->new;
    my $container_id = $self->stash('id');
    $self->render(json => inspect $container_id);
}

sub list ($self) {
    my @raw_containers = `docker ps | tail -n +2`;
    my $containers = [];
    foreach my $container (@raw_containers) {
        chomp($container);
        # turn the goofy space-separated field into - delimited.
        $container =~ s/(\w)[\W]{2,}(\w)/$1-$2/g;
        # and trim the end whitespace
        $container =~ s/[\W]+$//;
        my ($id, $image, $command, $created, $status, $ports, $names) = split "-", $container;

        push $containers->@*, {
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

sub _get_container_object ($self, $container_id) {
    my $output = _paranoid_inspect $container_id;
    return '' if $output =~ /No such image or container/ or !$output;
    return Agent::Containers::Container->new($container_id);
}

sub _paranoid_inspect ($container_id) {
    return `docker inspect $container_id` if looks_like_sha1 $container_id;
    return '';
}

1;
