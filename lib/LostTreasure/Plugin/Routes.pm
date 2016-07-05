package LostTreasure::Plugin::Routes;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Plugin';

sub make_routes {
    my ($self, $app) = @_;
    my $r = $app->routes;
 
}

sub register {
    my ($self, $app) = @_;
    $app->helper(make_routes => sub { $self->make_routes($app) });

    $r->get("/")->name("root")->to("welcome#index");
}

1;
