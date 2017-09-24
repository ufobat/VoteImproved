use v6.c;

use Crypt::Bcrypt;
use Image::Resize;
use UUID;
use VoteImproved::Helper;
use X::VoteImproved::Error;

class VoteImproved::Model::Image {
    has $.dbh is required;
    has IO $.img-store is required;

    sub uuid-to-imgname(Str $uuid) { $uuid ~ '.jpg' }
    sub uuid-to-tnname(Str $uuid)  { $uuid ~ '_tn.jpg' }

    method add-image($content, Int $user-id) {
        my $uuid = UUID.new.Str; # 36 chars
        my $sql  = 'INSERT INTO images values(NULL,?,?,?)';
        my $sth  = $.dbh.prepare($sql);
        my $file = $.img-store.child( uuid-to-imgname($uuid) );
        try {
            $file.spurt($content, :createonly);
            $sth.execute($uuid, $user-id, DateTime.now.posix);
            self.calculate-thumbnail($uuid, $file);
            CATCH {
                default {
                    die X::VoteImproved::Error.new(reason => 'could not store image ' ~ .message);
                }
            }
        }
    }

    method calculate-thumbnail($uuid, $image, Int $tnsize = 100) {
        my $tn = $.img-store.child(uuid-to-tnname($uuid));
        scale-to-height($image.Str, $tn.Str, $tnsize);
    }

    method get-all-images() {
        my $sql = 'SELECT * from images';
        my @users;
        try {
            my $sth = $.dbh.prepare($sql);
            $sth.execute;
            @users = $sth.allrows(:array-of-hash);
            CATCH {
                default {
                    .say;
                    die X::VoteImproved::Error.new(reason => 'could not fetch all images ' ~ .message);
                }
            }
        }
        for @users -> $image {
            enrich-image($image);
        }
        return @users;
    }

    my sub enrich-image($image) {
        $image<image-name> = uuid-to-imgname($image<uuid>);
        $image<tn-name>    = uuid-to-tnname($image<uuid>);
        return $image;
    }

    method get-image(Int $id) {
        my $sql = 'Select * from images where id=?';
        my $image;
        try {
            my $sth = $.dbh.prepare($sql);
            $sth.execute($id);
            $image = $sth.row(:hash);
            CATCH {
                default {
                    die X::VoteImproved::Error.new(reason => 'could not fetch image ' ~ .message);
                }
            }
        }
        return enrich-image($image);
    }

    method vote-image(Int $imageid, Int $userid, Num $rating) {
        my $sql = 'select id from votes where imageid = ? and userid = ?';
        try {
            my $sth = $.dbh.prepare($sql);
            $sth.execute($imageid, $userid);
            my ($vote-id) = $sth.row();

            my $epoch = DateTime.now.posix;
            if $vote-id {
                my $update-sql = 'update votes set rating = ?, epoch = ? where id = ?';
                $sth = $.dbh.prepare($update-sql);
                $sth.execute($rating, $epoch, $vote-id);
            } else {
                my $insert-sql = 'insert into votes values(NULL,?,?,?,?)';
                $sth = $.dbh.prepare($insert-sql);
                $sth.execute($imageid, $userid, $rating, $epoch);
            }
            CATCH {
                default {
                    die X::VoteImproved::Error.new(reason => 'could not vote image ' ~ .message);
                }
            }
        }
    }
}
