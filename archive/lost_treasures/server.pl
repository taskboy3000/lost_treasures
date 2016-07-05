use strict;
use HTTP::Daemon;
use HTTP::Status;
use HTTP::Response;
use XML::Simple;
use URI::Escape;
use Game;

my $d = HTTP::Daemon->new(LocalPort => "8080", 
			  LocalAddr => "0.0.0.0",
			  Reuse => 1, 
			  Listen => 10) || die;
my $Game = Game->new;
our $Sessions = {};

print $d->url, "\n";

eval 
{
    while (my $c = $d->accept) 
    {
	warn("New connection\n");
	while (my $r = $c->get_request) 
	{
	    warn("New request: " . $r->uri . "\n");
	    if ($r->method eq 'GET' ) 
	    {
		warn("Handler begin\n");
		eval
		{
		    handle($r, $c, $Game);
		};

		if ($@)
		{
		    warn("ERROR: $@\n");
		}
		warn("Handler finished\n");
	    }
	    else 
	    {
		$c->send_error(RC_FORBIDDEN)
	    }
	    $c->force_last_request;
	}
	warn("Closing connection\n");
	$c->close;
	undef($c);
    }
};
warn($@) if $@;

# This is pure AJAX hander
# my $data = { important => { values => [ 1, 2, 3 ] },
# 	     error => [ "OK" ] ,
# 	     attr2 => [ "two" ],
#            };

sub handle
{
    my ($r, $conn, $Game) = @_;
    my (undef, $method) = split('/', $r->url->path);

    my %args;  
    my @params = $r->uri->query_form();
    for (my $i = 0; $i < @params; $i += 2)
    {
	if (exists $args{ $params[ $i ] })
	{
	    my @vals = ( $args{ $params[ $i ] },
		         $params[ $i + 1 ] 
		       );
	    $args{ $params[ $i ] } = \@vals;
	}
	else
	{
	    $args{ $params[ $i ] } = $params[ $i + 1 ];
	}
    }

    my $session_id = delete $args{session_id};

    my $G = $Sessions->{$session_id} || $Game;

    my $response = HTTP::Response->new();
    my $X = XML::Simple->new();
    my %xml_opts = (RootName=>"response", XMLDecl => 0);
    my $xml = "";

    if (!$method)
    {
	warn("Sending HTML shell");
	$conn->send_file_response("game.html");
	return;
    }
    elsif (-f $method)
    {
	warn("Sending $method\n");
	$conn->send_file_response($method);
	return;
    }
    elsif ($method eq 'new_game')
    {
	# Kill the old session
	delete $Sessions->{$session_id};
        my $sid = $G->make_id();
	$Sessions->{$sid} = Game->new;
	$xml = $X->XMLout({ sid => [ $sid ] }, %xml_opts);
    }
    elsif ($Game->can($method))
    {
	warn("Method requested: $method\n");
	warn("Session: $session_id\n");
	my $data = $G->$method(%args);
	$xml = $X->XMLout($data, %xml_opts);
    }
    $response->code(HTTP::Status::RC_OK);
    $response->content($xml);
    
    $conn->send_response($response);
}

