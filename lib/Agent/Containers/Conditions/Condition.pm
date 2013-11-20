package Agent::Containers::Conditions::Condition;
use Mojo::Base -base;
use DatabaseConnection;
use Data::Dumper qw(Dumper);

use constant {
    NET_DELAY => 100,
    NET_DROP => 101,
    NET_IGNORE => 102,
    NET_THROTTLE => 103,
    DISK_FILL => 200,
    MEM_FILL => 300,
    CPU_MAX => 400,
};

has container => sub { \1; };
has args => sub { {}; };
has type_id => undef;
has type => undef;
has subtype => undef;
has table_name => undef;
has id => undef;
has db => sub { DatabaseConnection::get(); };

sub new {
    my $self = shift->SUPER::new(@_);
    $self->table_name('condition_' . $self->type . '_' . $self->subtype);
    $self->args($self->get) if $self->id;
    return $self;
}

sub get {
    my $self = shift;
    my @columns = @{$self->columns};
    my $table_name = $self->table_name;
    my $id_field = $table_name . "_id";
    my $select = join ', ', @columns;
    my $sth = $self->db->prepare("
        SELECT
            $select
        FROM
            $table_name
        WHERE
             $id_field = ?");

    $sth->execute($self->id);
    return $sth->fetchrow_hashref();
}

sub save {
    my $self = shift;
    my $columns = $self->columns;
    my @columns = @$columns;
    my $container_id = $self->container->id;
    # perl is the bomb. hash slice all day!
    my @args = @{$self->args}{@columns};

    # perl is terrifying. multiply the string '?, ' by the number of elements
    # in @columns, then trim off the last two chars (extra comma-space)
    my $question_marks = substr '?, ' x @columns, 0, -2;

    my $table_name = $self->table_name;
    my $id_field = $table_name . "_id";
    my $column_inserts = join ', ', @columns;
    # then generate some query action
    my $sth = $self->db->prepare("
        INSERT INTO $table_name
        ( $column_inserts
        ) VALUES ($question_marks)");

    $sth->execute(@args);

    my $condition_id = $self->db->last_insert_id(undef, undef, $table_name, $id_field);
    $self->id($condition_id);
    $self->register($container_id, $self->type, $condition_id);
    return $condition_id;
}

sub remove {
    my $self = shift;
    my $table_name = $self->table_name;
    my $id_field = $table_name . "_id";
    my $sth = $self->db->prepare("
        DELETE FROM $table_name
        WHERE
            $id_field IN
        (SELECT
            condition_id
        FROM container_condition
        WHERE
            container_id = ?
        AND
            condition_type = ?)
    ");
    $sth->execute($self->container->id, $self->type_id);
    $self->disable();
    $self->unregister();
}

sub register {
    my $self = shift;
    my $container_id = $self->container->id;
    my $condition_type = $self->type_id;
    my $condition_id = $self->id;

    my $sth = $self->db->prepare("
        INSERT OR REPLACE INTO container_condition
        (
            container_id,
            condition_type,
            condition_id
        ) VALUES (?, ?, ?)");
    $sth->execute($container_id, $condition_type, $condition_id);
    return $self->db->last_insert_id(undef, undef, 'container_condition', 'container_condition_id');
}

sub unregister {
    my $self = shift;
    my $container_id = $self->container->id;

    my $sth = $self->db->prepare("
        DELETE FROM container_condition
        WHERE
            container_id = ?
        AND
            condition_type = ?");
    $sth->execute($container_id, $self->type_id);
}

1;
