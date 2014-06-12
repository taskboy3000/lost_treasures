package Game;
# A prototype of an interesting game, perhaps

use strict;
use Time::HiRes ('time');
use Data::Dumper;

sub new
{
    my ($proto, %args) = @_;
    my $self = bless {}, (ref $proto || $proto);
    $self->{Treasures} = [
	"the Golden Chalice",
	"the Mountain King's Crown",
	"a Chunky Necklace",
	"a Silver Sceptre",
	"the Tarnished Urn"
	];
    
    $self->{player} = { alive => 1,
			level => 0,
			cwd => 0, # Starts in first room
			treasures => [],
    };
    $self->{map} = [];
    $self->{room_names} = {};
    $self->generate_next_level($self->{map}, $self->{player});
    
    return $self;
}

sub make_id 
{
    my $t = time();
    $t =~ s!\.!_!;
    return $t;
}

sub generate_next_level
{
    my ($self) = @_;
    my $map = $self->{map};
    
    my $player = $self->{player};
    my $next_level = scalar @$map + 1;
    my $size = $next_level ** 2;
    
    my $level = [];
    
    push @$map, $level;
    
    for (my $i=0; $i < $size; $i++) 
    {
	my $room = $self->generate_room($i);
	push @$level, $room;
    }
    
    for my $room (@$level) 
    {
	$self->generate_treasure($room, $level, $player);
	$self->generate_exits($room, $level);
    }
    
    # Reset the visited flag for PC
    for my $room (@$level)
    {
	$room->{visited} = 0;
    }

    # For now, put stairs in the last room
    $level->[@$level - 1]->{stairs} = $self->make_stairs($level);
    
    # Start the bat in the last room 
    if ($next_level > 2)
    {
	$level->[@$level - 1]->{bat} = $self->make_bat();
    }
    return 1;
}

sub generate_treasure
{
    my ($self, $room, $level, $player) = @_;
    
    return unless @{$self->{Treasures}};
    
    # 1. Treasure found on level 3 and below
    return if $player->{level} < 3;

    my @existing;
    for my $r (@$level) 
    {
      if (@{$r->{treasures}}) 
      {
	push @existing, @{$r->{treasures}};
      }
    }

    # 2. Only 5% of the rooms per level may have treasure
    if ((scalar @existing / scalar @$level) >= 0.05) 
    {
      return;
    }
    
    # 3. Only a 25% chance that there is treasure in an eligible room
    return if rand() > 0.25;
    
    my $index = rand(@{$self->{Treasures}});
    my $treasure = splice(@{$self->{Treasures}}, $index, 1);
    my $treasure_rec = {
			id => make_id(),
			type => "treasure",
			description => $treasure,
		       };
    
    push @{$room->{treasures}}, $treasure_rec;
    return $treasure;
}

sub make_bat
{
    my ($self) = @_;
    my $bat = {
	id => $self->make_id(),
	description => "This bat steals your stuff!", 
    };
    
    return $bat;
}

sub make_stairs
{
    my ($self, $level) = @_;
    return {
	id => make_id(),
	type => "stairs",
	to => (scalar @$level),
	description => "These stairs lead down."
    };
}

# Rooms have names, which are pithy descriptions of their purpose or appearance
# Rooms may have:
# - treasure items
# - story items
# - gadgets
sub generate_room
{
      my ($self, $id) = @_;
      my $room_name = $self->make_room_name();
      # my $desc = $self->make_room_description($room_name);
      my $room = { id => $id,
		   description => "This is the $room_name",
		   visited => 0,
		   doors => [],
		   stairs => undef(),
		   type => "room",
		   treasures => [],
		   bat => undef(),
      };
      
      return $room;
}

{
    my $adjectives = [
	'red', 'blue', 'yellow', 'orange', 'green', 'purple', 'brown', 'black',
	'silver', 'gold', 'wooden', 'stone', 'metal', 'baroque',
	             ];
    my $purposes = [
	'kitchen', 'observatory', 'library', 'den', 'bedroom', 'office', 'drawing room', 'long hall', 'closet', 'living room', 'feasting hall', 'shrine', 'alcove', 'cloister', 'room',
	];
    sub make_room_name
    {
	my ($self) = @_;
	my $name;
	my $max = scalar $adjectives * scalar $purposes;

	if (scalar(keys %{$self->{room_names}}) == $max)
	{
	    return "Undescribed Room";
	}

	while (1)
	{
	    my $adj = $adjectives->[rand @$adjectives];
	    my $purp = $purposes->[rand @$purposes];
	    $name = "$adj $purp";
	    unless ($self->{room_names}->{$name})
	    {
		$name =~ s/(\w+)/ucfirst($1)/ge;
		$self->{room_names}->{$name} = 1;
		last;
	    }
	}
	return $name;
    }
}
# look for neighbors in cardinal directions;
# be mindful of maze bounderies
sub get_unvisited
{
    my ($self, $room, $level) = @_;
    
    my $id = $room->{id};
    
    my @neighbors;

    my $size = @$level;
    return \@neighbors if $size == 1;

    my $len = sqrt($size);

    # North - only rooms in the second or below row have north neighbors
    if ($id - $len > 0) 
    {
      my $n = $id - $len;
      if ($level->[$n]->{visited} == 0) 
      {
	push @neighbors, $n;
      }
    }

    # South - only rooms not in the last row have south neighbors
    if ($id + $len < $size) 
    {
      my $n = $id + $len;
      if ($level->[$n]->{visited} == 0) 
      {
	push @neighbors, $n;
      }
    }
    
    # West - only rooms not in the left column have west neighbors
    if ($id % $len != 0) 
    {
      my $n = $id - 1;
      if ($level->[$n]->{visited} == 0) 
      {
	push @neighbors, $n;
      }
    }

    # East - only rooms not in the right column have east neighbors
    # East column will always mod to 1 less than the length of the grid
    if ($id % $len != ($len - 1)) 
    {
      my $n = $id + 1;
      unless ($level->[$n]->{visited}) 
      {
	push @neighbors, $n;
      }
    }
    
    return \@neighbors;
  }

sub get_relative_room_position
{
    my ($self, $room1, $room2) = @_;

    my $id1 = $room1->{id};
    my $id2 = $room2->{id};

    if ($id1 == $id2 - 1) 
    {
      return "east";
    }

    if ($id1 == $id2 + 1) 
    {
      return "west";
    }

    if ($id1 > $id2) 
    {
      return "north";
    }

    if ($id1 < $id2) 
    {
      return "south";
    }
  	    
}

sub add_door
{
    my ($self, $room, $exit_room_id, $level) = @_;
    my $exit_loc = $self->get_relative_room_position($room,
						     $level->[$exit_room_id]);
    my %pos = ("north" => 0, "east" => 1, "south" => 2, "west" => 3);

    my $exit = {
		id => make_id(),
		type => "door",
		to => $exit_room_id,
		description => sprintf("This door is on the %s wall", $exit_loc),
		exit_side => $exit_loc,
		exit_side_pos => $pos{lc $exit_loc},
               };
    
    push @{$room->{doors}}, $exit;
}

# For now, assume a grid
sub generate_exits
{
    my ($self, $room, $level) = @_;
    
    $room->{visited} = 1;
    while (my $unvisited = $self->get_unvisited($room, $level)) 
    {
      last unless @$unvisited;
      my $choice = $unvisited->[ rand(@$unvisited) ];

      $level->[$choice]->{visited} = 1;
      # Doors are two way
      $self->add_door($room, $choice, $level);
      $self->add_door($level->[$choice], $room->{id}, $level);

      $self->generate_exits($level->[$choice], $level);
    }
}

# Web API calls
# Return various status about the game to the player
sub update_status
{
    my ($self) = @_;
    my $p = $self->{player};

    my %stats = (
	"current_level" => [ $p->{level} ],
	"alive" => [ $p->{alive} ]
	);

    if (@{$p->{treasures}})
    {
	$stats{treasures} = $p->{treasures};
    }
    
    $stats{visited_rooms} = 0;
    
    my $level = $self->{map}->[ $p->{level} ];
    $stats{total_rooms} = [ scalar @$level ];
    
    for my $room (@$level)
    {
	if ($room->{visited})
	{
	    $stats{visited_rooms} += 1;
	}
    }

    $stats{visited_rooms} = [ $stats{visited_rooms} ] ;

    return \%stats;
}

# Show the map as the player has discovered
sub update_map
{
    my ($self) = @_;
    my $map = $self->{map};
    my $player = $self->{player};
    my $level = $map->[ $player->{level} ];

    my $tmp = [];
    for my $room (@$level)
    {
	if ($room->{visited})
	{
	    push @$tmp, $room;
	}
	else
	{
	    push @$tmp, { id => $room->{id}, visited => 0 };
	}
    }

    my $known = [];

    # fold this mess into a grid for the poor UI schulb
    my $len = sqrt(scalar @$level);
    for my $y (0 .. ($len - 1))
    {
	my $row = [];
	for my $x (0 .. ($len - 1))
	{
	    push @$row, $tmp->[ ($y * $len) + $x ];
	}
	push @$known, { row => $y,
			room => $row
	              };
    }
    # warn(Dumper($known));
    return { map => { grid => $known },
	     len => [ $len ],
	     level => [ $player->{level} ],
	     cwd => [ $player->{cwd} ],
           };
}

# Describe the current room
sub update_room_description
{
    my ($self) = @_;
    my $player = $self->{player};
    my $map = $self->{map};
    my $level = $map->[$player->{level}]; 
    my $room = $level->[$player->{cwd}];

    # This may not be the best place for this flag, but it works for now
    $room->{visited} = 1;

    my $scr = "";
    $scr .= sprintf("<p>%s</p>",$room->{description});

    for my $t (@{$room->{treasures} || []}) 
    {
      $scr .= sprintf("<p>You see <a href=\"/go?id=%s\">%s</a></p>", $t->{id}, $t->{description});
    }

    if ($room->{bat})
    {
	$scr .= "<p>Oh, no! You see the kleptomanical bat.  Run away before it takes your stuff.</p>";
    }

    if (@{$room->{doors}})
    {
	$scr .= q[<p>Doors:</p><ul>];
	for my $door (@{$room->{doors}}) 
	{
	    $scr .= sprintf(qq[<li><a href="/go?id=%s" data-exit-side-pos="%s">%s</a></li>],
			    $door->{id},
			    $door->{exit_side_pos},
			    $door->{description},
		);
	}
	$scr .= q[</ul>];
    }

    if (my $s = $room->{stairs}) 
    {
       $scr .= sprintf("<p><a data-type=\"downstairs\" href=\"/go?id=%s\">%s</a></p>", $s->{id}, $s->{description});
    }

    return { 
	      alive => [ $player->{alive} ],
	      scene => [ $scr ] 
           };
}

sub go
{
    my ($self) = shift;
    my %args = (id => "",
		@_);

    unless ($args{id})
    {
	warn("go: no id given: " . join(",", @_) . "\n");
    }

    # Actually do the thing given by the id in the current room
    my $map = $self->{map};
    my $player = $self->{player};
    
    my $level = $map->[ $player->{level} ];
    my $room = $level->[ $player->{cwd} ];
    
    my $scr = "";

    unless ($room)
    {
	warn("no room!");
	return { "status" => [ "error" ] };
    }

    # Remove all player owned treasures from the room
    my @remaining;
    for my $t (@{$room->{treasures}}) 
    {
      if ($t->{id} eq $args{id})
      {
	$scr .= sprintf "<p>You take $t->{description}</p>";
	push @{$player->{treasures}}, $t;
	$scr .= sprintf("You have %d of 5 Lost Treasures.\n", scalar @{$player->{treasures}});
      }
      else 
      {
	push @remaining, $t;
      }
    }
    
    $room->{treasures} = \@remaining;
    
    # Does the player have all the treasures?
    if (scalar @{$player->{treasures}} == 5) 
    {
      $scr .= sprintf "You have collected all the lost treasures!\n";
      $scr .= sprintf "You win\n";
      $player->{alive} = 0;
      return { status => [ $scr ], alive => [ $player->{alive} ]  };
    }

    # Move bat
    $self->move_bat();
    
    # Is this a door?
    for my $door (@{$room->{doors}}) 
    {
      if ($door->{id} eq $args{id}) 
      {
	$scr .= sprintf "You walk through this door\n";
	$player->{cwd} = $door->{to};
	return { status => [ $scr ], alive => [ $player->{alive} ] };
      }
    }

    # Is this a stairway?
    if (my $s = $room->{stairs}) 
    {
	if ($s->{id} eq $args{id}) 
	{
	    $scr .= sprintf "<p>You climb down the stairs.</p>";
	    $scr .= sprintf "<p>Welcome to level %d</p>\n", ($player->{level} + 1);
	    $self->generate_next_level($map, $player);
	    $player->{cwd} = 0;
	    $player->{level} += 1;
	    return { status => [ $scr ], alive => [ $player->{alive} ] };
	}
    }


    return { status => [ $scr ], alive => [ $player->{alive} ] }
}

sub move_bat
{
    my ($self) = @_;

    if (rand() < 0.25) 
    {
	warn("**Bat would like to move\n");
	my $map = $self->{map};
	my $player = $self->{player};
	my $level = $map->[ $player->{level} ];
	
	# find the bat
	my $cwd_id = -1;
	my $bat;
	for my $room (@$level)
	{
	    if ($room->{bat})
	    {
		$cwd_id = $room->{id};
		$bat = delete $room->{bat};
		last;
	    }
	}
	
	unless ($bat)
	{
	    warn("**No bat found on this level '$player->{level}'\n");
	    return;
	}

	# Move the bat to a new room
	my $new_id = -1;
	while (1)
	{
	    $new_id = int(rand(@$level));
	    last unless $new_id == $cwd_id;
	}
	
	warn("**Moving bat from room $cwd_id to $new_id\n");
	$level->[ $new_id ]->{bat} = $bat;
    }
    else
    {
	warn("**Bat declined to move\n");
    }
}
1;
