#!/usr/local/bin/perl
die "Shuld be two parametr  from.file to.file \n" unless (@ARGV == 2);
use IO::File;
my $fd_r = new IO::File($ARGV[0],'r') || warn "I cant open file !$?\n";
my $fd_w = new IO::File($ARGV[1],'w') || warn "I cant open file !$?\n";
while (<$fd_r>)
{ 
    s/^(\-\-\+\w+)\s+\w+\s*(;.*)/$1$2/; 
    s/^(\-\-\+\w+)\s+\w+\s*(,.*)/$1$2/; 
    $fd_w->print($_)
};
$fd_r->close;
$fd_w->close;
