#! /usr/bin/perl

use strict;
use warnings;
use JSON;

use lib '.';
use Flickr;

my $json = JSON->new->allow_nonref;

my $key = '18468584667623ade3c966e5dd1d23f9';
my $uid = '21723201@N07';

my $flickr = Flickr->new($key)->set_uid($uid);
my $resp = $flickr->get_resp('flickr.photosets.getList');

my $china_id;
if ($resp->is_success) {
  my $content = $resp->decoded_content;
  my $rsp = $json->decode($content);
  print "$rsp->{stat}\n";
  foreach my $set (@{ $rsp->{photosets}{photoset} }) {
    print $set->{title}{_content}, ' ', $set->{id}, "\n";
    $china_id = $set->{id} if $set->{title}{_content} =~ m/china/i;
  }
}

if ( defined $china_id ) {
  my $resp = $flickr->get_resp(
    'flickr.photosets.getPhotos', 
    photoset_id => $china_id
   );
 if ($resp->is_success) {
   my $content = $resp->decoded_content;
   my $rsp = $json->decode($content);
   if ( $rsp->{stat} eq 'ok') {
     foreach my $photo (@{ $rsp->{photoset}{photo} }) {
       print "$photo->{title} $photo->{id}\n";
     }
   } else {
     die "flickr call failed: $rsp->{message}";
   }
   
 }
}

