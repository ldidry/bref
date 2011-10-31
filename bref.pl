#!/usr/bin/perl 
use warnings;
use strict;

# Copyright 2011, Luc Didry <luc@didry.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use LWP::Simple;
use XML::Twig;
use XML::Atom::SimpleFeed;
use POSIX qw( strftime );
use Getopt::Std;

our($opt_o);
getopts('o:');
$opt_o = 'bref.atom' if(!defined($opt_o));

my $entry_number = 0;

my $feed = XML::Atom::SimpleFeed->new(
    title   => 'Bref',
    link    => 'http://www.canalplus.fr/c-divertissement/pid3848-c-bref.html',
    link    => { rel => 'self', href => 'http://www.fiat-tux.fr/bref.atom', },
    icon    => 'http://www.fiat-tux.fr/favicon.ico',
    author  => 'Bref',
    id      => 'http://www.canalplus.fr/c-divertissement/pid3848-c-bref.html',
);

my $flux_xml = get('http://www.canalplus.fr/rest/bootstrap.php?/bigplayer/search/bref');

my $parser = XML::Twig->new();

$parser->setTwigHandlers(
    {
        'VIDEO/MEDIA' => \&check_rubrique,
    }
);

$parser->parse($flux_xml);

$parser->purge();

open FILE, '>', $opt_o or die 'Unable to open bref.atom : $!';

$feed->print(\*FILE);

close FILE;

sub check_rubrique {
    my ($t, $elt) = @_;
    if($entry_number < 20) {
        my $video = $elt->parent();
        my $rubrique = $video->first_descendant('RUBRIQUE');
        if ($rubrique->text_only() eq 'BREF'){
            my $id    = $video->first_descendant('ID');
            my $date  = $video->first_descendant('DATE');
            my $heure = $video->first_descendant('HEURE');
            my $titre = $video->first_descendant('TITRE');
 
            my $bas_debit  = $elt->first_descendant('BAS_DEBIT');
            my $haut_debit = $elt->first_descendant('HAUT_DEBIT');
            my $hd         = $elt->first_descendant('HD');
 
            my $content = 'Bas d&eacute;bit        : <a href="'.$bas_debit->text_only().'">'.$bas_debit->text_only().'</a><br/>'.
                          'Haut d&eacute;bit       : <a href="'.$haut_debit->text_only().'">'.$haut_debit->text_only().'</a><br/>'.
                          'Haute d&eacute;finition : <a href="'.$hd->text_only().'">'.$hd->text_only().'</a>';
 
            $date = $date->text_only();
            $date =~ s#(\d{2})/(\d{2})/(\d{4})#$3-$2-$1#;
            $date = $date.'T'.$heure->text_only.'+01:00';
 
            $feed->add_entry(
                title    => $titre->text_only(),
                link     => 'http://www.canalplus.fr/c-divertissement/pid3848-c-bref.html?vid='.$id->text_only(),
                id       => 'http://www.canalplus.fr/c-divertissement/pid3848-c-bref.html?vid='.$id->text_only(),
                updated  => $date,
                category => 'Atom',
                content  => $content,
            );
            $entry_number++;
        }
    }
}
