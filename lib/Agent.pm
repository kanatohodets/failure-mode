package Agent;
use Mojo::Base 'Mojolicious';
use DBD::SQLite;
use DBI;

has db_name => "db/agent.db";
# This method will run once at server start
sub startup {
  my $self = shift;

  $self->helper(db => sub {
    my $db_name = $self->db_name;
    state $db = DBI->connect("dbi:SQLite:dbname=$db_name");
  });

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');

  $r->get('/containers')->to('containers#list');

  #specify a docker image
  $r->post('/containers')->to('containers#start');
  $r->delete('/containers/:id')->to('containers#stop');

  #json says what to do to the container (peg cpu, fill disk, remove disk, fill ram, etc).
  $r->post('/containers/:id/modify')->to('containers#modify');

  $r->get('/images')->to('images#list');
  $r->post('/images')->to('images#create');

}

1;
