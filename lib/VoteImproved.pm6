use v6;

use Bailador::App;
use Bailador::Route;
use Bailador::Route::StaticFile;

class VoteImproved is Bailador::App {
    has IO::Path $!rootdir;
    has $!title = "Vote Improved";

    submethod BUILD(|) {
        $!rootdir = $?FILE.IO.parent.parent;
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

    method login-get {
        self.session-delete;
        self.render: self.master-template: 'login.tt';
    }

    method login-post() {
        my $session = self.session;
        # $session<user> = $user;
        # TODO render
    }

    method logout {
        self.session-delete;
        self.render: self.master-template: 'logout.tt';
    }

    method vote-index {
        self.render: self.logged-in-template: 'index.tt';
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
