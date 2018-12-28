# Microsoft Graph API with Perl

Simple OAuth2 example with Microsoft Graph API using Perl with the Dancer2 module.

Error handling, paging and refreshing tokens have been omitted to keep example simple.

## Getting Started

Required Perl module installation
```
$ cpanm Dancer2 LWP::UserAgent URI::Escape URI::Query
```

The code is based on the details given here https://docs.microsoft.com/en-us/graph/auth-v2-user?view=graph-rest-1.0

You will need to register your own application to have valid `client_id`, `client_secret`, and `redirect_uri`. You may also want to set your own scope in case you want to use other Graph endpoints.

## Run Server

To start the application
`$ perl appl.pl`

open browser and direct to
`http://localhost:3000`

## Endpoints

Dancer2 endpoints used.

```
/         # Displays link to login
/login    # Redirects to MS login page
/callback # Handles the callback from MS login
/emails   # Displays last 10 emails
/logout   # Logs out of current session
```
