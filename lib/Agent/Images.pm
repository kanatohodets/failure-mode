package Agent::Images;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use Agent::Containers::Container;
use Data::Dumper qw(Dumper);

sub create_image {
    my $self = shift;
    my $dockerfile = shift;
    my $repository_name = shift;
    my $image_id = `echo "$dockerfile" | docker build -t $repository_name -`;
    $self->_register_image($image_id, $repository_name);
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

sub _register_image {
    my $self = shift;
    my ($image_id, $repository_name) = @_;
    my $sth = $self->db->prepare("
        INSERT INTO image
        (
            image_id,
            repository_name
        ) VALUES (?, ?)");
    $sth->bind_param($image_id, $repository_name);
    $sth->execute();
}

1;
