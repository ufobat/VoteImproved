
use v6;

use Bailador;
use VoteImproved::Helper;
use X::VoteImproved::Error;

class VoteImproved::Controller::Image {
    has $.model is required;

    method add-image {
        my $my-id = session<user-id>;
        my %param = request.params();
        try {
            my Bailador::Request::Multipart $file = %param<file>;
            my $filename = $file.filename;
            my $content  = $file.content;
            my $size     = $file.size;

            $.model.add-image($content, $my-id);

            say "$filename is $size bytes large";
            return vote-message "$filename is $size bytes large";

            CATCH {
                default {
                    return vote-message type => 'danger', .message;
                }
            }
        }
    }

    method list-all-images {
        my @images = $.model.get-all-images();
        return template 'vote-listimages', @images;
    }

    method show-image($id) {
        my $image = $.model.get-image($id.Int);
        return template 'vote-showimage', $image;
    }
}
