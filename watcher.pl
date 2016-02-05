#!/usr/bin/perl

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;

my %accounts = ('jan', '', 'other', '');

sub send_message
{
    use Email::Send::SMTP::Gmail;
    my $address = $_[0];
    my $subject = $_[1];
    my $body = $_[2];

    my $mail=Email::Send::SMTP::Gmail->new( -smtp=>'smtp.gmail.com',
               -login=>'mail@gmail.com',
               -pass=>'pass');

    $mail->send(-to=>$address, -subject=>$subject, -body=>$body);
    $mail->bye;
}

sub parse_korepetycje
{
    my $login = $_[0];
    my $passwd = $_[1];
    my $ua = LWP::UserAgent->new;

    my $req = HTTP::Request->new(
        POST => 'http://profil.e-korepetycje.net/skrzynka,odebrane');
    $ua->cookie_jar(HTTP::Cookies->new(file => "lwpcookies.txt",
            autosave => 1));
    push @{ $ua->requests_redirectable }, 'POST';
    $req->content_type('application/x-www-form-urlencoded');
    $req->content("login=$login&passwd=$passwd&logme=1&post_check=login_form");

    my $res = $ua->request($req);
    my $website = $res->as_string;

    my @received = $website =~ m/"(http:\/\/profil.e-korepetycje.net\/skrzynka,odebrane,[0-9]*)"><b>.*?<\/b>/g;
    my @unreadreceived = keys { map { $_ => 1 } @received };

    my $msg_body = "";

    foreach (@unreadreceived)
    {
        $req->uri( $_ );
        my $data = ($ua->request($req))->as_string;
        my ($author) = $data =~ m/<a class="message-author".*?>(.*?)<\/a>/s;
        my ($body) = $data =~ m/<div class="message-body">(.*?)<\/div>/s;
        $body =~ s/<.+?>//g;
        $msg_body .= "$author\n\n";
        $msg_body .= "$body\n\n";
        $msg_body .= "login: $login\n\n";
        $msg_body .= "=====\n\n";
    }

    return $msg_body;
}

foreach my $user (keys %accounts)
{
    my $data = parse_korepetycje( $user, $accounts{$user});

    if($data ne "")
    {
        send_message( 'mail@gmail.com', 'e-korepetycje', "$data" );
    }
}
