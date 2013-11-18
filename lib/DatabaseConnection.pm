package DatabaseConnection;
use 5.18.1;
use strict;
use warnings;
use DBI;

my $db_name = "db/agent.db";

sub get {
    state $dbh = DBI->connect("dbi:SQLite:dbname=$db_name", "", "");
}


