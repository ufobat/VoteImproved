use v6;

use DBIish;
use IoC;

use VoteImproved::Model::User;
use VoteImproved::Model::Image;
use VoteImproved::Controller::User;
use VoteImproved::Controller::Image;

unit module VoteImproved::IoC;

sub setup-ioc is export {
    my $container = container 'VoteImproved' => contains {
        service 'ModelUser' => {
            lifecycle    => 'Singleton',
            type         => VoteImproved::Model::User,
            dependencies => {
                dbh   => 'dbh',
            },
        };
        service 'ModelImage' => {
            lifecycle    => 'Singleton',
            type         => VoteImproved::Model::Image,
            dependencies => {
                dbh       => 'dbh',
                img-store => 'img-store',
            },
        };
        service 'ControllerUser' => {
            lifecycle    => 'Singleton',
            type         => VoteImproved::Controller::User,
            dependencies => {
                model => 'ModelUser',
            },
        };
        service 'ControllerImage' => {
            lifecycle    => 'Singleton',
            type         => VoteImproved::Controller::Image,
            dependencies => {
                model => 'ModelImage',
            },
        };

        service 'img-store' => {
            lifecycle    => 'Singleton',
            block        => sub {
                my IO $img-store = 'img-store'.IO;
                $img-store.mkdir unless $img-store.e;
                return $img-store;
            }
        }
        # https://github.com/jasonmay/perl6-ioc/issues/18
        # service 'user'     => '';
        # service 'password' => '';
        # service 'type'     => 'SQLite';
        # service 'database' => '../db/voteimproved.db';
        service 'dbh'      => {
            lifecycle => 'Singleton',
            # dependencies => {
            #     user     => 'user',
            #     password => 'password',
            #     type     => 'type',
            #     database => 'database',
            # }
            block     => sub {
                # my $service = shift;
                # my $user = $service.resolve-dependency('user');
                my $file = 'voteimproved.db'.IO;
                my $database = $file.absolute;
                DBIish.connect("SQLite", :$database);
            }
        };
    };
    return $container;
}
