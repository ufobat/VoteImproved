use v6;
use VoteImproved;
use Bailador;

my $psgi-app = VoteImproved.new.get-psgi-app();
my $port = 3000;

#use HTTP::Server::Smack;
#given HTTP::Server::Smack.new(:host<0.0.0.0>, :$port) {
#    say "Entering the development dance floor: http://0.0.0.0:$port";
#    .run($psgi-app);
#}

use HTTP::Server::P6W;
given HTTP::Server::P6W.new(:host<0.0.0.0>, :$port) {
    say "Entering the development dance floor: http://0.0.0.0:$port";
    .run($psgi-app);
}

#use HTTP::Easy::PSGI;
#given HTTP::Easy::PSGI.new(:host<0.0.0.0>, :$port) {
#    .app($psgi-app);
#    say "Entering the development dance floor: http://0.0.0.0:$port";
#    .run;
#}
