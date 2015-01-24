#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: cards_refresh.pl
#
#        USAGE: ./cards_refresh.pl  
#
#  DESCRIPTION: Rebuild the cards.json dataset from netrunnerdb
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Adam Fairbrother (Hegz), adam.faibrother@gmail.com
#      VERSION: 1.0
#      CREATED: 15-01-19 09:59:56 AM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use JSON;
use LWP::Simple;

# Grab the full list of cards from the NRDB Database
my $nrdb_export = get ("http://netrunnerdb.com/api/cards/");

# Remove unicode characters from the export
$nrdb_export =~ s/\\u\d\d\d\d//g;

# These attrs from NRDB are irrelevant 
my @removed_attrs = qw/code set_code side_code faction_code cyclenumber limited faction_letter type_code subtype_code last-modified/;

my $dataset;
my $cards_dataset = decode_json $nrdb_export;
my $AltsList;
my $NoAltsList;

for my $card (@$cards_dataset) {
	if ($card->{setname} eq 'Alternates') {
		$AltsList->{$card->{title}} = $card;
		next;
	}
	for (@removed_attrs) {
		delete $card->{"$_"};
	} 
	for my $altcard (keys %$AltsList) {
		if ($altcard eq $card->{"title"}){
			$card->{"altart"} = { illustrator => $AltsList->{$altcard}->{"illustrator"}, imagesrc => "/images/cards/" . ImageName($card->{"title"}) . "-alt.png"};
		}
	}
	$card->{"nrdb_url"} = delete $card->{"url"};
	$card->{"imagesrc"} = "/images/cards/" . ImageName($card->{"title"}) . ".png";
	push @$NoAltsList, $card;
}

my $setname_export = get ("http://netrunnerdb.com/api/sets/");
my $sets_dataset = decode_json $setname_export;


my @sets_rem_attr = qw/code number known total url/;

my $sets_proper;
for my $set (@$sets_dataset) {
	if ($set->{"name"} eq 'Alternates') {
		next;
	}
	elsif ($set->{"name"} eq 'Special') {
		next;
	}
	for (@sets_rem_attr) {
		delete $set->{"$_"};
	}
	# Couldn't find an atomatic translation of cyclenum to cyclename
	$set->{"released"} = delete $set->{"available"};
	$set->{"released"} = undef if $set->{"released"} eq '';
	$set->{"cycle"} = "Genesis" if ($set->{"cyclenumber"} == 2);
	$set->{"cycle"} = "Spin" if ($set->{"cyclenumber"} == 4);
	$set->{"cycle"} = "Lunar" if ($set->{"cyclenumber"} == 6);
	$set->{"cycle"} = "SanSan" if ($set->{"cyclenumber"} == 8);
	delete $set->{"cyclenumber"};
	push @$sets_proper, $set;
}

# Update the Datestamp
$dataset->{"last-modified"} = modifiedDate();
$dataset->{"cards"} = $NoAltsList;
$dataset->{"sets"} = $sets_proper;

my $json_text = to_json($dataset, {utf8 => 1, pretty => 1, canonical => 1});
print $json_text;

exit 0;

sub modifiedDate {
	my @date = localtime(time);
	$date[5] += 1900;
	$date[4] += 1;
	splice @date, 6;
	return sprintf "%s-%02s-%02sT%02s:%02s:%02s",reverse @date;
}

sub ImageName {
	my ($title) = @_;
	$title =~ tr/ /-/;
	$title = lc $title;
	$title =~ s/[^a-z0-9-]//g;
	return $title;
}
