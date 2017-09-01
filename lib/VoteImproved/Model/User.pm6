use v6.c;

use Crypt::Bcrypt;
use X::VoteImproved::Error;
use VoteImproved::Helper;

class VoteImproved::Model::User {
    has $.dbh is required;

    method login(Str $user, Str $pass) {

        die X::VoteImproved::Error.new: reason => "user invalid" unless $user ~~ / \w+ /;

        my $sth  = $.dbh.prepare("SELECT * FROM users WHERE name= ? AND isactive=1");
        $sth.execute($user);
        my %dbval = $sth.row(:hash);

        die X::VoteImproved::Error.new: reason => "user not found" unless %dbval<name>:exists;
        die X::VoteImproved::Error.new: reason => "password missmatch" unless bcrypt-match($pass, %dbval<passwd>);

        return %dbval;
    }

    method get-all-user {
        my $sth = $.dbh.prepare("select * from users");
        $sth.execute;
        my @users = $sth.allrows(:array-of-hash);
        return @users;
    }

    method delete-user(Int $my-id, Int $id) {
        die X::VoteImproved::Error: reason => 'you can not delete yourself' if $my-id == $id;
        my $sql = 'UPDATE users SET isactive = 0 WHERE id = ?';
        my $sth = $.dbh.prepare($sql);
        $sth.execute($id);
    }

    method add-user(Str $user, Str $pass, Str $email, Int $createdby) {
        my $createdat = time;
        my $passhash  = bcrypt-hash($pass);

        my $sth = $.dbh.prepare("INSERT INTO users values(NULL, ?, ?, ?, ?, ?, 1)");
        $sth.execute($user, $passhash, $email, $createdat, $createdby);
    }

    method check-old-pw(Int $user-id, Str $oldpass) {
        my $sth = $.dbh.prepare("select * from users where id = ?");
        $sth.execute($user-id);
        my %dbval = $sth.row(:hash);

        die X::VoteImproved::Error.new: reason => "password missmatch " unless bcrypt-match($oldpass, %dbval<passwd>);
    }

    method update-password(Int $user-id, Str $oldpass, Str $newpass) {
        self.check-old-pw($user-id, $oldpass);
        my $sql = "UPDATE users SET passwd = ? WHERE id = ?";
        my $sth = $.dbh.prepare($sql);
        my $passhash  = bcrypt-hash($newpass);
        $sth.execute($passhash, $user-id);
    }

    method update-email(Int $user-id, Str $oldpass, Str $email) {
        self.check-old-pw($user-id, $oldpass);
        my $sql = "UPDATE users SET email = ? WHERE id = ?";
        my $sth = $.dbh.do($sql);
        $sth.execute($email, $user-id);
    }
}
