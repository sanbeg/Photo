package Flickr;

# http://kylerush.net/blog/flickr-api/

use LWP;
use JSON;

my $prefix = 'http://api.flickr.com/services/rest/?format=json&nojsoncallback=1';

sub new {
  my ($class,$key) = @_;
  my %self = (key => $key, ua => LWP::UserAgent->new);
  bless \%self, $class;
}

sub set_uid {
  my ($self,$uid) = @_;
  $self->{uid} = $uid;
  return $self;
}

sub get_resp {
  my ($self,$method,%args) = @_;
  my $url = $prefix;
  $url .= "&api_key=$self->{key}";
  $url .= "&user_id=$self->{uid}" if defined $self->{uid};
  $url .= "&method=$method";
  while (my ($k,$v) = each %args){
    $url .= "&$k=$v";
  };
warn $url;
  return $self->{ua}->get($url);
}
