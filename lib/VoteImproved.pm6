use v6;

use Bailador::App;
use Bailador::Route;
use Bailador::Route::StaticFile;

class VoteImproved is Bailador::App {
    has $!rootdir = $?FILE.IO.parent.parent;
    has $!title = "Vote Improved";

    submethod BUILD(|) {
        self.location = $!rootdir.child("views").dirname;
        self.sessions-config.cookie-expiration = 5;

        self.post: '/login' => self.curry: 'login-post';
        my $route = Bailador::Route.new: path => /.*/, code => sub {
            return True if self.session<user>;
            return False;
        };
        $route.get: '/vote/index' => self.curry: 'index';
        $route.get: '/logout' => self.curry: 'logout';
        # $route.get: Bailador::Route::StaticFile.new: path => / ^ vote \/ <-[\/]> (<[\w\.]+]>)/, dir => $rootdir.child("vote-img/");

        self.add_route: $route;

        # catch all route
        # self.get: Bailador::Route::StaticFile.new: path => /.*/, dir => $rootdir.child("public");
        self.get: /.*/ => self.curry: 'index';

    method login-get {
        self.session-delete;
        self.render: self.master-template: 'login.tt';
    }

    method login-post {
            my $user = @_[0];
            my $session = self.session;
            # $session<user> = $user;
            # TODO render
    }

    method logout {
        self.session-delete;
        self.render: self.master-template: 'logout.tt';
    }

    method index {
        self.render: self.master-template: 'index.tt';
    }

    method static-file {
    }

    method master-template(Str:D $template, *@param) {
        self.template: 'master.tt', $!title, self.template: $template, @param);
    }
}
