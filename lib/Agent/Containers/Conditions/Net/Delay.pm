package Agent::Containers::Conditions::Net::Delay;
use Mojo::Base 'Agent::Containers::Conditions::Net';

has columns => sub { [ qw(base deviation correlation distribution) ] };

sub new {
    my $self = shift->SUPER::new(@_);
    $self->type_id($self->SUPER::NET_DELAY);
    return $self;
}

sub prepare_command {
    my $self = shift;
    my $hashref = $self->get();
    my ($base, $deviation, $correlation, $distribution) = @$hashref{qw(base deviation correlation distribution)};
    return if not defined $base;
    my $command = " delay " . $base . "ms ";
    $command .= $deviation . "ms " if defined $deviation;
    $command .= $correlation . "% " if defined $correlation;
    $command .= "distribution $distribution" if defined $distribution;
    return $command;
}

1;

