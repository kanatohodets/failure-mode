package Agent::Util;
use Mojo::Base;
use Exporter qw(import);

our @EXPORT_OK = qw(looks_like_sha1);

sub looks_like_sha1 {
    my $id = shift;
    return $id =~ /^[0-9a-f]*$/;
}

1;
