package Agent::Images;
use Mojo::Base 'Mojolicious::Controller';

sub create_image {
    my $self = shift;
    my $dockerfile = shift;
    my $repository_name = shift;
    my $image_id = `echo "$dockerfile" | docker build -t $repository_name -`;
    $self->_register_image($image_id, $repository_name);
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

