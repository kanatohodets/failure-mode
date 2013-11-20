package Agent::Containers::Conditions::Disk::Fill;
use Mojo::Base 'Agent::Containers::Conditions::Condition';

has columns => sub { [ qw() ] };

sub new {
    my $self = shift->SUPER::new(@_);
    $self->type_id($self->SUPER::DISK_FILL);
    return $self;
}

sub prepare_command {
    my $self = shift;
    my $hashref = $self->get();
}

1;
