use v6;

use Bailador::App;
use Bailador::Route;
use Bailador::Route::StaticFile;
use DBIish;
use Crypt::Bcrypt;

class X::VoteImproved::Error is Exception {
    has Str $.reason is required;
    method message { "failure: $.reason" }
}

class VoteImproved is Bailador::App {
    has IO::Path $!rootdir;
    has $!title = "Vote Improved";
    has $!sqlite;

    submethod BUILD(|) {
        $!rootdir = $?FILE.IO.parent.parent;
        $!sqlite  = $!rootdir.child('db/voteimproved.db');
        self.location = $!rootdir.child("views").dirname;
        self.sessions-config.cookie-expiration = 180;

        self.get:  '/login' => sub { self.session-delete; self.master-template: 'login.tt' };
        self.post: '/login' => self.curry: 'login-post';
        my $only-if-loggedin = Bailador::Route.new: path => /.*/, code => sub {
            return True if self.session<user>;
            return False;
        };
        $only-if-loggedin.get:  '/vote/index'       => sub { self.logged-in-template: 'vote-index.tt' };
        $only-if-loggedin.get:  '/vote/listuser'    => self.curry: 'vote-listuser';
        $only-if-loggedin.get:  '/vote/deluser/:id' => self.curry: 'vote-deluser';
        $only-if-loggedin.get:  '/vote/adduser'     => sub { self.logged-in-template: 'vote-adduser.tt' };
        $only-if-loggedin.post: '/vote/adduser'     => self.curry: 'vote-adduser-post';
        $only-if-loggedin.get:  '/vote/modifyuser'  => sub { self.logged-in-template: 'vote-modifyuser.tt' };
        $only-if-loggedin.post: '/vote/modifyuser'  => self.curry: 'vote-modifyuser-post';
        $only-if-loggedin.get:  '/vote/addimage'    => sub { self.logged-in-template: 'vote-addimage.tt' };
        $only-if-loggedin.post: '/vote/addimage'    => self.curry: 'vote-addimage-post';
        $only-if-loggedin.get:  '/logout'           => sub { self.session-delete; self.redirect: '/login' };
        $only-if-loggedin.add_route: Bailador::Route::StaticFile.new: path => / ^ vote '/' img '/'  (<[\w\.]>+)/, directory => $!rootdir.child("vote-img/");

        self.add_route: $only-if-loggedin;
        self.add_route: Bailador::Route::StaticFile.new: path => / (<[\w\.]>+ '/' <[\w\.\-]>+)/, directory => $!rootdir.child("public");
        self.get: / ^ '/' [ $ || 'vote' || 'logout' ] / => sub {self.redirect: '/login' };
    }

    # Database
    method get-dbi {
         my $dbh = DBIish.connect("SQLite", database => $!sqlite.abspath);
    }

    # Teplate methods
    method master-template(Str:D $template, *@param) {
        my $inner = self.template: $template, @param;;
        self.render: self.template: 'master.tt', $!title, $inner;
    }

    method logged-in-template(Str:D $template, *@param) {
        my $inner = self.template: $template, @param;
        my $logged-in = self.template: 'logged-in-master.tt', $!title, $inner;
        self.render: self.template: 'master.tt', $!title, $logged-in;
    }

    method vote-message(Str $message, Str :$type = 'default', Str :$title) {
        my $header;
        if $title {
            $header = $title
        }
        else {
            if $type eq 'danger' {
                $header = 'Error';
            }
            elsif $type eq 'info' {
                $header = 'Info'
            }
            else{
                $header = 'Success';
            }
        }
        self.logged-in-template: 'vote-message.tt', $type, $header, $message;
    }

    # Routes
    method login-post() {
        my %param = self.request.params();
        try {
            my $dbh;
            die X::VoteImproved::Error.new: reason => "Missing parameters" unless %param<inputUser>:exists and %param<inputPassword>:exists;
            my $user = %param<inputUser>;
            my $pass = %param<inputPassword>;
            die X::VoteImproved::LoginError.new: reason => "user invalid" unless $user ~~ / \w+ /;
            #my $dbh will leave { .dispose } = self.get-dbi;
            $dbh  = self.get-dbi;
            my $sth  = $dbh.prepare("SELECT * FROM users WHERE name= ? AND isactive=1");
            $sth.execute($user);
            my %dbval = $sth.row(:hash);
            die X::VoteImproved::Error.new: reason => "user not found" unless %dbval<name>:exists;
            die X::VoteImproved::Error.new: reason => "password missmatch "unless bcrypt-match($pass, %dbval<passwd>);

            my $session = self.session;
            $session<user> = $user;
            $session<user-id> = %dbval<id>;

            $dbh.dispose if $dbh;

            self.redirect: '/vote/index';

            CATCH {
                given X::VoteImproved::Error {
                    self.master-template: 'login.tt';
                }
                default {
                    .say;
                    self.master-template: 'login.tt';
                }
            }
        }
    }

    method vote-adduser-post {
        my %param = self.request.params();
        if %param<newuser>:exists and %param<newpasswd>:exists and %param<newemail>:exists {
            my $session = self.session;
            my $user = %param<newuser>;
            my $pass = %param<newpasswd>;
            my $mail = %param<newemail>;
            my $createdat = time;
            my $createdby = $session<user-id>;
            my $passhash  = bcrypt-hash($pass);

            my $dbh = self.get-dbi;

            try {
                LEAVE { $dbh.dispose };
                CATCH {
                    default {
                        self.vote-message: type => 'danger', .message;
                    }
                };
                my $sth = $dbh.prepare("INSERT INTO users values(NULL, ?, ?, ?, ?, ?, 1)");
                $sth.execute($user, $passhash, $mail, $createdat, $createdby);
            }
        }
        self.vote-message: 'Added user';
    }

    method vote-listuser {
        my $session = self.session;
        my $my-id = $session<user-id>;
        my $dbh = self.get-dbi;
        my $sth = $dbh.prepare("select * from users");
        $sth.execute;
        my @users = $sth.allrows(:array-of-hash);
        $dbh.dispose;
        self.logged-in-template: 'vote-listuser.tt', $my-id, @users;
    }

    method vote-deluser(Match $user-id) {
        my Int $id = + $user-id.Str;
        my $dbh = self.get-dbi;
        try {
            LEAVE { $dbh.dispose }
            my $session = self.session;
            my $my-id = $session<user-id>;
            die X::VoteImproved::Error: reason => 'you can not delete yourself' if $my-id == $id;
            my $sql = 'UPDATE users SET isactive = 0 WHERE id = ?';
            my $sth = $dbh.prepare($sql);
            $sth.execute($id);

            self.vote-message: 'Deleted user ' ~ $id;
            CATCH {
                default {
                    self.vote-message: type => 'danger', .message;
                }
            }
        }
    }

    method vote-modifyuser-post {
        my $session = self.session;
        my $my-id = $session<user-id>;
        my %param = self.request.params();
        my $dbh  = self.get-dbi;
        try {
            LEAVE { $dbh.dispose };
            CATCH {
                default {
                    self.vote-message: type => 'danger', .message;
                }
            }

            die X::VoteImproved::Error.new: reason => "old password is requird" unless %param<oldpasswd>:exists and %param<oldpasswd> ne "";

            my $sth = $dbh.prepare("select * from users where id = ?");
            $sth.execute($my-id);
            my %dbval = $sth.row(:hash);

            die X::VoteImproved::Error.new: reason => "password missmatch "unless bcrypt-match(%param<oldpasswd>, %dbval<passwd>);

            # passwd
            my @changed-what;
            if %param<newpasswd>:exists and %param<newpasswd>.chars > 1  {
                my $passhash  = bcrypt-hash(%param<newpasswd>);
                my $sql = "UPDATE users SET passwd = ? WHERE id = ?";
                my $sth = $dbh.prepare($sql);
                $sth.execute($passhash, $my-id);
                @changed-what.push('password');
            }
            # email
            if %param<newemail>:exists and %param<newemail>.chars > 1 {
                my $sql = "UPDATE users SET email = ? WHERE id = ?";
                my $sth = $dbh.do($sql);
                $sth.execute(%param<newemail>, $my-id);
                @changed-what.push('email');
            }
            if @changed-what.elems > 0 {
                self.vote-message: 'Successfully changed user: ' ~ @changed-what.join(' and ');
            }
            else {
                self.vote-message: type => 'danger', 'Nothing to Change';
            }
        }
    }

    method vote-addimage-post {
        my $session = self.session;
        my $my-id = $session<user-id>;
        my %param = self.request.params();
        my $dbh  = self.get-dbi;
        try {
            LEAVE { $dbh.dispose };
            CATCH {
                default {
                    self.vote-message: type => 'danger', .message;
                }
            }
            self.vote-message: %param.perl;
        }
    }
}
