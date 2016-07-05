package LostTreasure;
use strict;
use warnings;
use Mojo::Base 'Mojolicious';
use Schema;

has schema => sub {
    return Schema->connect();
};

# This method will run once at server start
sub startup {
  my $self = shift;
  $self->helper(db => sub { $self->app->schema});
  $self->plugin("LostTreasure::Plugin::Routes");
  $self->make_routes();
}

1;
