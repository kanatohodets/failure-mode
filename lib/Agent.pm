package Agent;
use Mojo::Base 'Mojolicious';
use DBD::SQLite;
use DBI;

has db_name => "db/agent.db";
# This method will run once at server start
sub startup {
    my $self = shift;
    $self->config(hypnotoad => {listen => ['http://*:3005']});

    $self->helper(db => sub {
        my $db_name = $self->db_name;
        state $db = DBI->connect("dbi:SQLite:dbname=$db_name");
    });

    $self->hook(before_dispatch => sub {
        my $c = shift;
        $c->res->headers->header('Access-Control-Allow-Origin' => '*');
        $c->res->headers->header('Access-Control-Allow-Methods' => 'GET,OPTIONS,PUT,POST,DELETE');
        $c->res->headers->header('Access-Control-Allow-Headers' => 'X-Requested-With, X-Access-Token, X-Revision, Content-Type');
    });

    # Router
    my $r = $self->routes;

    $r->options('*')->to(cb => sub {
        my $self = shift;
        $self->render(text => 'ok');
    });

    # Normal route to controller

    $r->get('/containers')->to('containers#list');
    $r->get('/containers/:id')->to('containers#get');

    #specify a docker image
    $r->post('/containers')->to('images#start');
    $r->delete('/containers/:id')->to('containers#stop');

    #json has args
    $r->post('/containers/:id/conditions/:type/:subtype')->to('containers#add_condition');
    $r->delete('/containers/:id/conditions/:type/:subtype')->to('containers#remove_condition');
    $r->delete('/containers/:id/conditions')->to('containers#remove_conditions');
    $r->get('/containers/:id/conditions')->to('containers#list_conditions');

    $r->get('/images')->to('images#list');

    $r->post('/images')->to('images#create');
}

1;
