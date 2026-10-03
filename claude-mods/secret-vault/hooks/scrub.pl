#!/usr/bin/perl
# Replaces secrets in files in place: stdin is a JSON list of [secret, placeholder]
# pairs (each secret as it appears inside a JSON string), the arguments are files
# or glob patterns. Rewrites a file only when something changed, through the same
# inode, so a process that holds it open for appending keeps writing to it.
use strict;
use warnings;
use JSON::PP;
use Encode qw(encode_utf8);

my $pairs = do { local $/; decode_json(<STDIN>) };
my @bytes = map { [encode_utf8($_->[0]), encode_utf8($_->[1])] } @$pairs;

for my $path (map { glob } @ARGV) {
  open(my $fh, '+<:raw', $path) or next;
  my $text = do { local $/; <$fh> };
  next unless defined $text;
  my $out = $text;
  for my $pair (@bytes) {
    my ($secret, $placeholder) = @$pair;
    $out =~ s/\Q$secret\E/$placeholder/g;
  }
  if ($out ne $text) {
    seek($fh, 0, 0);
    print {$fh} $out;
    truncate($fh, tell($fh));
    print "$path\n";
  }
  close($fh);
}
