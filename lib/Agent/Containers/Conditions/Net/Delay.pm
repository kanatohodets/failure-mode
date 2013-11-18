package Agent::Containers::Conditions::Net::Delay;
use Mojo::Base 'Agent::Containers::Conditions::Condition';

sub new {
    my $self = shift->SUPER::new(@_);
    $self->type($self->SUPER::NET_DELAY);
    my $container_id = $self->container->id;
    # perl is the bomb
    my @args = @$self->args->{qw(base deviation correlation distribution)};

    my $sth = $self->db->prepare("
        INSERT INTO condition_net_delay
        (
            base,
            deviation,
            correlation,
            distribution
        ) VALUES (?, ?, ?, ?)");
    $sth->execute(@args);
    my $condition_id = $self->db->last_insert_id;
    $self->id($condition_id);
    $self->register($container_id, $self->type, $condition_id);
    return $self;
}

sub remove {
    my $self = shift;
    my $sth = $self->db->prepare("
        DELETE FROM condition_net_delay
        WHERE
            condition_net_delay_id IN 
        (SELECT 
            condition_id 
        FROM container_condition
        WHERE
            container_id = ?
        AND
            condition_type = ?)
    ");
    $sth->execute($self->container->id, $self->type);
    $self->unregister();
}

1;

