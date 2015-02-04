#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: update_cards.pl
#
#        USAGE: ./update_cards.pl  
#
#  DESCRIPTION: update cards dataset from netrunnerdb
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
use File::Slurp;
use Image::Magick;

# Load the existing card database
my $cardsfile = 'app/data/cards.json';
my $existing_cards = from_json(read_file($cardsfile));

# Change the Cards array to a Hash, keyed by card title
my %Cur_Cards = map { $_->{title} => $_ } @{$existing_cards->{cards}};

# Delete the Chronos Protocol cards, they cause problems
for (keys %Cur_Cards) {
	if ($_ =~ m/^Chronos Protocol.*/){
		delete $Cur_Cards{$_};
	}
}

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
	$card->{"nrdb_art"} = delete $card->{"imagesrc"};
	$card->{"imagesrc"} = "/images/cards/" . ImageName($card->{"title"}) . ".png";
	push @$NoAltsList, $card;
}

# Change the Cards array to a Hash, keyed by card title
my %Imp_Cards = map { $_->{title} => $_ } @$NoAltsList;

# Clear out Chronos Protocol Id's here
for (keys %Imp_Cards) {
	if ($_ =~ m/^Chronos Protocol.*/){
		delete $Imp_Cards{$_};
	}
}

for (keys %Cur_Cards) {
	delete $Imp_Cards{$_};
}


# Add in new cards
for (keys %Imp_Cards){

	#Download Images
	my $image = Image::Magick->new(magick=>'png');
	$image->BlobToImage(get ("http://netrunnerdb.com/" . $Imp_Cards{$_}->{nrdb_art}));
	print "Downloading and converting " . $Imp_Cards{$_}->{imagesrc} ." From " . $Imp_Cards{$_}->{nrdb_art} . "\n";
	#Convert Images to the correct format
	$image->Quantize(colors=>256, colorspace=>'RGB', dither=>1);
	my $err = $image->Write("app" . $Imp_Cards{$_}->{imagesrc});
	warn "$err" if $err;

	delete $Imp_Cards{$_}->{nrdb_art};

	#Add Breaker Calc info
	if ($Imp_Cards{$_}->{subtype} =~ m/Icebreaker/) {
		$Imp_Cards{$_}->{text} =~ m/(\d).*(\d*).*subroutine.*(\d*).*(\d*)/;
		my $br_credits;
		my $br_subs;
		my $str_cost;
		my $str_amt;
		if ( $1 ne '' ) {
			$br_credits = int $1;
		}
		else {
			$br_credits = int 1;
		}
		if ( $2 ne '' ) {
			$br_subs = int $2;
		}
		else {
			$br_subs = int 1;
		}
		if ( $3 ne '' ) {
			$str_cost = int $3;
		}
		else {
			$str_cost = int 1;
		}
		if ( $4 ne '' ) {
			$str_amt = int $4;
		}
		else {
			$str_amt = int 1;
		}
		if ($str_amt == 1) {
			$Imp_Cards{$_}->{strengthcost} = $str_cost;
		}
		else {
			$Imp_Cards{$_}->{strengthcost} = {credits=> $str_cost, strength=> $str_amt};
		}
		$Imp_Cards{$_}->{breakcost} = {credits=> $br_credits, subroutines=> $br_subs};
	}
	push @{$existing_cards->{cards}}, $Imp_Cards{$_};
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
	$set->{"title"} = delete $set->{"name"};
	delete $set->{"cyclenumber"};
	push @$sets_proper, $set;
}

@$sets_proper = sort {$a->{released} cmp $b->{released}} @$sets_proper;

# Update the Datestamp
$dataset->{"last-modified"} = modifiedDate();
$dataset->{"cards"} = $existing_cards->{cards};
$dataset->{"sets"} = $sets_proper;

my $json_text = to_json($dataset, {utf8 => 1, pretty => 1, canonical => 1});

open my $cards_out, '>', "app/data/cards.json";
print $cards_out $json_text;
close $cards_out;

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
