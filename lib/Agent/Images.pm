package Agent::Images;
use Mojo::Base 'Mojolicious::Controller';
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
    my $image_name = $self->param('image_name');
    my $container = Agent::Containers::Container->new();
    my $container_id = $container->start($image_name);
    $self->render(json => {container_id => $container_id}); 
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
