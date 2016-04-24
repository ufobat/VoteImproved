use v6;

use Bailador::App;
use Bailador::Route;
use Bailador::Route::StaticFile;
use DBIish;
use Crypt::Bcrypt;

class X::VoteImproved::LoginError is Exception {
    has Str $.reason is required;
    method message { "login failed: $.reason" }
}

class VoteImproved is Bailador::App {
    has IO::Path $!rootdir;
    has $!title = "Vote Improved";
    has $!sqlite;

    submethod BUILD(|) {
        $!rootdir = $?FILE.IO.parent.parent;
        $!sqlite  = $!rootdir.child('db/voteimproved.db');
        self.location = $!rootdir.child("views").dirname;
        self.sessions-config.cookie-expiration = 5;

        self.get:  '/login' => self.curry: 'login-get';
        self.post: '/login' => self.curry: 'login-post';
        my $route = Bailador::Route.new: path => /.*/, code => sub {
            return True if self.session<user>;
            return False;
        };
        $route.get: '/vote/index' => self.curry: 'vote-index';
        $route.get: '/logout' => self.curry: 'logout';
        # $route.get: Bailador::Route::StaticFile.new: path => / ^ vote \/ <-[\/]> (<[\w\.]>+)/, directory => $rootdir.child("vote-img/");

        self.add_route: $route;

        # catch all route
        self.add_route: Bailador::Route::StaticFile.new: path => / (<[\w\.]>+ \/ <[\w\.]>+)/, directory => $!rootdir.child("public");
        self.get: /.*/ => sub {self.redirect: '/login' };
    }

    # Database
    method get-dbi {
         my $dbh = DBIish.connect("SQLite", database => $!sqlite.abspath);
    }

    method login-get {
        self.session-delete;
        self.render: self.master-template: 'login.tt';
    }

    method login-post() {
        my %param = self.request.params();
        try {
            my $dbh;
            die X::VoteImproved::LoginError.new: reason => "Missing parameters" unless %param<inputUser>:exists and %param<inputPassword>:exists;
            my $user = %param<inputUser>;
            my $pass = %param<inputPassword>;
            die X::VoteImproved::LoginError.new: reason => "user invalid" unless $user ~~ / \w+ /;
            #my $dbh will leave { .dispose } = self.get-dbi;
            $dbh  = self.get-dbi;
            my $sth  = $dbh.prepare("select * from users where name='{$user}';");
            $sth.execute;
            my %dbval = $sth.row(:hash);
            dd %dbval;
            die X::VoteImproved::LoginError.new: reason => "user not found" unless %dbval<name> eq $user;
            die X::VoteImproved::LoginError.new: reason => "password missmatch "unless bcrypt-match($pass, %dbval<passwd>);

            my $session = self.session;
            $session<user> = $user;
            say "login worked";

            $dbh.dispose if $dbh;

            self.redirect: '/vote/index';

            CATCH {
                given X::VoteImproved::LoginError {
                    self.render: self.master-template: 'login.tt';
                }
                default {
                    .say;
                    self.render: self.master-template: 'login.tt';
                }
            }
        }
    }

    method logout {
        self.session-delete;
        self.render: self.master-template: 'logout.tt';
    }

    method vote-index {
        self.render: self.logged-in-template: 'vote-index.tt';
    }

    method master-template(Str:D $template, *@param) {
        my $inner = self.template: $template, @param;;
        self.template: 'master.tt', $!title, $inner;
    }

    method logged-in-template(Str:D $template, *@param) {
        my $inner = self.template: $template, @param;;
        my $logged-in = self.template: 'logged-in.tt', $!title, $inner;
        self.template: 'master.tt', $!title, $logged-in;
    }
}
