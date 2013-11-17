use strict;
use warnings;

package DatabaseConnection;
use DBD::SQLite;
use DBI;

my $db_name = "db/agent";
my $dbh;
state $dbh = DBI->connect("dbi:SQLite:dbname=$db_name", "", "");

sub get_connection {
    my $self = shift;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_name", "", "");

}


