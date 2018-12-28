#!/usr/bin/perl
use strict;
use warnings;

use Dancer2;
use LWP::UserAgent;
use URI::Escape;
use URI::Query;

my $client_secret = "your-client-secret";
my $client_id     = "your-client-id";
my $redirect_uri  = "http://localhost:3000/callback";
my $scope         = "offline_access user.read mail.read";

get '/' => sub {
	return '<html><body><a href="/login">Login</a></body></html>';
};

get '/login' => sub {
	my $url        = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize";
	my $parameters = URI::Query->new(
		client_id     => $client_id,
		redirect_uri  => uri_escape($redirect_uri),
		scope         => uri_escape($scope),
		response_type => 'code',
		response_mode => 'query',
		state         => '1234',
	);
	$url .= $parameters->qstringify();
	redirect $url;
};

get '/logout' => sub {
	app->destroy_session;
	redirect '/';
};

get '/callback' => sub {
	my %all_parameters = params;
	my $url            = "https://login.microsoftonline.com/common/oauth2/v2.0/token";
	my $args           = {
		client_id     => $client_id,
		scope         => $scope,
		code          => $all_parameters{code},
		redirect_uri  => $redirect_uri,
		grant_type    => "authorization_code",
		client_secret => $client_secret,
	};

	my $ua            = LWP::UserAgent->new();
	my $response      = $ua->post( $url, $args );
	my $decoded_json  = decode_json( $response->content );
	my $access_token  = $decoded_json->{access_token};
	my $refresh_token = $decoded_json->{refresh_token};

	my $content = get_profile($access_token);
	my $email   = $content->{userPrincipalName};
	my $name    = $content->{displayName};

	session email        => $email;
	session name         => $name;
	session access_token => $access_token;

	redirect '/emails';
};

get '/emails' => sub {
	redirect '/' unless session('access_token');

	my $messages = get_messages( session('access_token') )->{value};

	my $body = "<a href='/logout'>Logout</a><table><tr><th>Read</th><th>Subject</th><th>From</th><th>Preview</th><tr>";
	foreach my $message (@$messages) {
		my $name  = $message->{from}->{emailAddress}->{name};
		my $email = $message->{from}->{emailAddress}->{address};
		$body .= "<tr>";
		$body .= "<td>" . $message->{isRead} . "</td>";
		$body .= "<td>" . $message->{subject} . "</td>";
		$body .= "<td><b>$name</b> ($email)</td>";
		$body .= "<td>" . $message->{bodyPreview} . "</td>";
	}
	$body .= "</table>";
	my $html = "<html><body>$body</body></html>";
	return $html;
};

sub get_profile
{
	my $access_token = shift;
	my $ua           = LWP::UserAgent->new();
	$ua->default_header( Authorization => $access_token );
	my $response = $ua->get("https://graph.microsoft.com/v1.0/me");
	return decode_json( $response->content );
}

sub get_messages
{
	my $access_token = shift;
	my $ua           = LWP::UserAgent->new();
	$ua->default_header( Authorization => $access_token );
	my $response = $ua->get("https://graph.microsoft.com/v1.0/me/messages");
	return decode_json( $response->content );
}

start();
