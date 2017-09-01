use v6;

class X::VoteImproved::Error is Exception {
    has Str $.reason is required;
    method message { "failure: $.reason" }
}
