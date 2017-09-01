use v6;
use Bailador;
use VoteImproved::Helper;
use X::VoteImproved::Error;

class VoteImproved::Controller::User {

    has $.model;

    method post-login {
        try {
            my %param = request.params();
            die X::VoteImproved::Error.new: reason => "Missing parameters" unless %param<inputUser>:exists and %param<inputPassword>:exists;

            my $user  = %param<inputUser>;
            my $pass  = %param<inputPassword>;
            my %dbval = $.model.login($user, $pass);

            my $session = session;
            $session<user> = $user;
            $session<user-id> = %dbval<id>;

            redirect '/vote/index';

            CATCH {
                when X::VoteImproved::Error {
                    render vote-message :type('danger'), :layout('master'), .message;
                }
                default {
                    render vote-message :type('danger'), :layout('master'), .message;
                }
            }
        }
    }

    method list-users {
        my $my-id = session<user-id>;
        my @users = $.model.get-all-user();
        template 'vote-listuser', $my-id, @users;
    }

    method delete-user($user-id) {
        try {
            my $my-id = session<user-id>;
            $.model.delete-user($my-id, $user-id.Int),
            vote-message 'Deleted user ' ~ $user-id;
            CATCH {
                default {
                    vote-message type => 'danger', .message;
                }
            }
        }
    }

    method add-user {
        my %param = request.params();
        if %param<newuser>:exists and %param<newpasswd>:exists and %param<newemail>:exists {
            my $user = %param<newuser>;
            my $pass = %param<newpasswd>;
            my $mail = %param<newemail>;
            my $createdby = session<user-id>;
            try {
                $.model.add-user($user, $pass, $mail, $createdby);
                CATCH {
                    default {
                        vote-message type => 'danger', .message;
                    }
                };
            }
            vote-message 'Added user';
        } else {
            vote-message type => 'danger', 'Missing Parameters';
        }
    }

    method modify-user {
        my $my-id = session<user-id>;
        my %param = request.params();
        die X::VoteImproved::Error.new: reason => "old password is requird" unless %param<oldpasswd>:exists and %param<oldpasswd> ne "";

        $.model.modify-user();
        try {
            CATCH {
                default {
                    vote-message type => 'danger', .message;
                }
            }
            # passwd
            my @changed-what;

            if %param<newpasswd>:exists and %param<newpasswd>.chars > 1  {
                $.model.update-password($my-id, %param<oldpasswd>, %param<newpasswd>);
                @changed-what.push('password');
            }
            # email
            if %param<newemail>:exists and %param<newemail>.chars > 1 {
                $.model.update-email($my-id, %param<oldpasswd>, %param<newemail>);
                @changed-what.push('email');
            }
            if @changed-what.elems > 0 {
                vote-message 'Successfully changed user: ' ~ @changed-what.join(' and ');
            }
            else {
                vote-message type => 'danger', 'Nothing to Change';
            }
        }
    }

}
