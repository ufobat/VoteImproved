use v6.c;

use Crypt::Bcrypt;
use X::VoteImproved::Error;
use VoteImproved::Helper;
use UUID;
use Image::Resize;

class VoteImproved::Model::Image {
    has $.dbh is required;
    has IO $.img-store is required;

    method add-image($content, Int $user-id) {
        my $uuid = UUID.new.Str; # 36 chars
        my $sql = 'INSERT INTO images values(NULL,?,?,?)';
        my $sth = $.dbh.prepare($sql);

        my $file = $.img-store.child($uuid ~ '.jpg');
        try {
            $file.spurt($content, :createonly);
            $sth.execute($uuid, $user-id, DateTime.now.posix);
            CATCH {
                default {
                    die X::VoteImproved::Error.new(reason => 'could not store image ' ~ .message);
                }
            }
        }
    }
}
