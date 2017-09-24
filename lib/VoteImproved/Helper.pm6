use v6;
use Bailador;
use DBIish;

unit module Bailador::Helper;

sub vote-message($message, Str :$type = 'default', Str :$title, Str :$layout) is export {
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
    if $layout {
        return template 'vote-message.tt', $type, $header, $message.Str, :$layout;
    } else {
        return template 'vote-message.tt', $type, $header, $message.Str;
    }
}
