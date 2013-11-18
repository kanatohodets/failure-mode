package Agent::Containers::Conditions::Condition;
use Mojo::Base -base;

use constant {
    NET_DELAY => 1,
    NET_LOSS => 2,
    NET_ISOLATION => 3,
    DISK_FULL => 4,
    MEMORY_FULL => 5,
    CPU_MAX => 6,
};

has container => sub { \1; };
has args => sub { {}; };
has type => undef;
has id => undef;
has db => sub { DatabaseConnection::get(); };

sub new {
    my $self = shift->SUPER::new(@_);
}

sub register {
    my $self = shift;
    my $container_id = $self->container->id;
    my $condition_type = $self->type;
    my $condition_id = $self->id;

    my $sth = $self->db->prepare("
        INSERT INTO container_condition
        (
            container_id,
            condition_type,
            condition_id
        ) VALUES (?, ?, ?)");
    $sth->execute($container_id, $condition_type, $condition_id);
    return $self->db->last_insert_id;
}

sub unregister {
    my $self = shift;
    my $container_id = $self->container->id;
    my $condition_id = $self->id;

    my $sth = $self->db->prepare("
        DELETE FROM container_condition
        WHERE
            container_id = ?
        AND
            condition_type = ?
        AND
            condition_id = ?");
    $sth->execute($container_id, $condition_id, $self->type);
}

1;
