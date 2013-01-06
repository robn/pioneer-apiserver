#!/usr/bin/env plackup

# A simple HTTP server to demo Pioneer's RPC agent
# Public domain / CC0

# This demo requires Perl's "plack" web server tools and JSON libs. Perl can
# install them:
#
# $ cpan install Plack JSON
#   or
# $ cpanm Plack JSON
#
# Or get them from your distribution, eg:
#
# $ apt-get install libplack-perl libjson-perl
#
# To run:
#
# $ plackup pioneer-rpcserver.psgi

use warnings;
use strict;

use Plack::Builder;
use Plack::Request;
use JSON;

my $json = JSON->new->allow_blessed->allow_nonref;

my %handlers = (
	serverTime => \&serverTime,
	lunchMenu  => \&lunchMenu,
);

builder {
	mount "/api" => builder {
		sub {
			my ($env) = @_;
			my $req = Plack::Request->new($env);

			# Pioneer only sends POST requests
			return $req->new_response(405)->finalize if $env->{REQUEST_METHOD} ne "POST";

			# method is always the last part of the URL, after the slash
			my ($method) = $env->{PATH_INFO} =~ m{^/([^/]+)$};
			return $req->new_response(404)->finalize if not $method;

			# get the correct handler for the method. 404 if we don't have one
			my $handler = $handlers{$method};
			return $req->new_response(404)->finalize if not $handler;

			# all requests will have Content-type: application/json
			return $req->new_response(400)->finalize if $req->content_type ne "application/json";

			# decode incoming JSON data if provided
			my $in = eval { $json->decode($req->content) };

			# call the handler, get some data back
			my $out = $handler->($in);

			# return the response to Pioneer with appropriate Content-Type.
			return $req->new_response(200, { "Content-type" => "application/json" }, $json->encode($out))->finalize;
		};
	};
};

# console:
#   ServerAgent.Call("serverTime", nil, function (t) print(t) end)
sub serverTime {
	my $data = shift;
	return localtime;
}

# console:
#   ServerAgent.Call("lunchMenu", nil, function (t) print(t) end)
#   ServerAgent.Call("lunchMenu", "vegetarian", function (t) print(t) end)
sub lunchMenu {
    my $data = shift;
    my $lunch = $data eq "vegetarian" ? "vegie burger" : "hamburger";
    return "Today's lunch is $lunch.";
}
