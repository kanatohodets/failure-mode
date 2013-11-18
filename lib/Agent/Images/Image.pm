package Agent::Images::Image;
use Mojo::Base -base;

has name => sub { '' };

sub new {
    my $self = shift->SUPER::new(@_);
}

sub start {
    my $self = shift;
}
