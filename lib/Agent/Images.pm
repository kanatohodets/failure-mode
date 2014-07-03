package Agent::Images;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use Agent::Containers::Container;
use Data::Dumper qw(Dumper);
use Agent::Util qw(looks_like_sha1);

sub create_image {
    my $self = shift;
    my $dockerfile = shift;
    my $repository_name = shift;
    my $result = `echo "$dockerfile" | docker build -t $repository_name -`;
    if (looks_like_sha1 $result) {
        $self->render(json => {image_id => $result, message => "OK"});
    } else {
        $self->render(json => {message => "failed to build image: $result"}, status => 400);
    }
}

sub start {
    my $self = shift;
    my $json = Mojo::JSON->new;
    my $args = $json->decode($self->req->body);
    my $image_name = $args->{image};
    my $container_name = $args->{name};
    my $cpu = $args->{cpu_shares};
    my $link_source_name = $args->{link_source_name};
    my $link_local_name = $args->{link_local_name};
    my $port_to_forward = $args->{port_to_forward};
    my $container = Agent::Containers::Container->new();
    my $container_id = $container->start($image_name, $container_name, $cpu, $link_source_name, $link_local_name, $port_to_forward);
    if ($container_id) {
        $self->render(json => {container_id => $container_id, message => "OK"});
    } else {
        $self->render(json => {message => "failed to start"}, status => 500);
    }
}

sub list {
    my $self = shift;
    my @raw_images = `docker images | tail -n +2 | awk '{print \$1,\$3}'`;
    my $images = {};
    foreach my $image (@raw_images) {
        chomp($image);
        my ($name, $id) = split ' ', $image;
        $images->{$name} = $id;
    }
    
    $self->render(json => $images);
}

1;
