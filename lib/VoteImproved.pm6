use v6;

use Bailador;
use VoteImproved::IoC;
use VoteImproved::Controller::User;
use VoteImproved::Controller::Image;
use X::VoteImproved::Error;

class VoteImproved {
    submethod TWEAK(|) {
        container setup-ioc();
        config.log-filter = ();
        config.cookie-expiration = 180;
        config.layout = 'logged-in-master';

        get '/login' => sub {
            session-delete;
            template 'login', :layout('master');
        };
        post '/login' => {
            service => 'ControllerUser',
            to      => 'post-login'
        };
        prefix / ^ <?before .*> / => sub {
            prefix-enter sub {
                return True if session<user>;
                return False;
            };

            get '/vote/index'       => sub { template 'vote-index' };
            get '/vote/adduser'     => sub { template 'vote-adduser' };
            get '/vote/modifyuser'  => sub { template 'vote-modifyuser' };
            get '/vote/addimage'    => sub { template 'vote-addimage' };
            get '/vote/listuser'    => {
                service => 'ControllerUser',
                to      => 'list-users'
            };
            get '/vote/deluser/:id' => {
                service => 'ControllerUser',
                to      => 'delete-user'
            };
            post '/vote/adduser'     => {
                service => 'ControllerUser',
                to      => 'add-user'
            };
            post '/vote/modifyuser'  => {
                service => 'ControllerUser',
                to      => 'modify-user',
            };
            post '/vote/addimage'    => {
                service => 'ControllerImage',
                to      => 'add-image',
            };
            get '/vote/listimages'    => {
                service => 'ControllerImage',
                to      => 'list-all-images',
            };
            get '/vote/showimage/:id'    => {
                service => 'ControllerImage',
                to      => 'show-image',
            };
            post '/vote/vote_image/:id' => {
                service => 'ControllerImage',
                to      => 'vote-image',
            };
            get  '/logout'           => sub {
                session-delete;
                redirect '/login';
            };
            static-dir / ^ '/' vote '/' img '/' ( <[ \w \- \_ \. ]>+ ) / => "img-store/";
        }
        static-dir / (<[\w\.]>+ '/' <[\w\.\-]>+)/ => 'public/';
        get / ^ '/' [ $ || 'vote' || 'logout' ] / =>  sub {
            redirect '/login'
        };
    }

    method start {
        baile;
    }
}
