package Agent::Containers;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use Mojo::UserAgent::UnixSocket;

use experimental qw(postderef signatures);
use Agent::Containers::Container;
use Agent::Util qw(looks_like_sha1);

## no critic ProhibitSubroutinePrototypes

our @EXPORT_OK = qw(inspect);

my $docker_api_root = 'unix:///var/run/docker.sock';

has ua => sub { state $ua = Mojo::UserAgent::UnixSocket->new };

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

sub inspect ($self, $container_id) {
    return '' if not looks_like_sha1 $container_id;
    my $res = $self->_docker_api("/containers/$container_id/json");
    return '' if !$res or $res->code eq '404';
    return $res->json;
}

sub get ($self) {
    my $json = Mojo::JSON->new;
    my $container_id = $self->stash('id');
    my $container = $self->inspect($container_id);
    if ($container) {
        $self->render(json => $container);
    } else {
        $self->render_not_found;
    }
}

sub list ($self) {
    my $res = $self->_docker_api('/containers/json');
    if ($res) {
        $self->render(json => $res->json);
    } else {
        $self->render_exception("Bad response from docker API");
    }
}

sub _get_container_object ($self, $container_id) {
    my $output = $self->inspect($container_id);
    return '' if !$output;
    return Agent::Containers::Container->new($container_id);
}

sub _docker_api($self, $route) {
    my $tx = $self->ua->get("$docker_api_root/$route");
    if ($tx->res->code) {
        warn "internal docker error: $tx->res->json" and return '' if $tx->res->code eq '500';
        return $tx->res;
    }
    return '';
}

1;
