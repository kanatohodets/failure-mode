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
  #$r->get('/')->to('example#welcome');

  $r->get('/containers')->to('containers#list');
  $r->get('/containers/:id')->to('containers#inspect');

  #specify a docker image
  $r->post('/containers')->to('images#start');
  $r->delete('/containers/:id')->to('containers#stop');

  #json has args
  $r->post('/containers/:id/condition/:type/:subtype')->to('containers#add_condition');
  $r->delete('/containers/:id/condition/:type/:subtype')->to('containers#remove_condition');


  $r->get('/images')->to('images#list');

  $r->post('/images')->to('images#create');

}

1;
