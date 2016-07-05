package LostTreasure::Controller::Root;
use strict;
use warnings;
use Mojo::Base 'LostTreasure::Controller::Application';

sub index {
    my ($self) = @_;
    $self->render();
}

    1;
