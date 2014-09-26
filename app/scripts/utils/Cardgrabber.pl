#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: Cardgrabber.pl
#
#        USAGE: ./Cardgrabber.pl Cycle_Name Datapack_Name
#
#  DESCRIPTION: Grab Card data from CardgameDB and massage to the appropriate json format.
#
#      OPTIONS: Cycle_Name    -- Name of the cycle, in the same format as the 
#                                cardgamedb URL.
#               Datapack_Name -- Name of the Datapack, in the dame format as 
#                                the cardgamedb URL
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Adam Fairbrother (Hegz), adam.fairbrother@sgmail.com
# ORGANIZATION: School District No. 73
#      VERSION: 1.0
#      CREATED: 14-09-19 11:41:08 AM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use HTML::TreeBuilder;
no warnings qw/experimental/;
my $doc = "http://www.cardgamedb.com/index.php/netrunner/android-netrunner-card-spoilers/_/the-lunar-cycle/first-contact/";

my $tree = HTML::TreeBuilder->new_from_url($doc);

my $table = ($tree->look_down('class','ipb_table topic_list hover_rows') );

my $cards;
my $name;
for my $tr ($table->look_down('_tag', 'tr')){
#$tr->dump;
	for my $td_top ($tr->look_down('_tag', 'td')){
		for my $table2 ($td_top->look_down('_tag', 'table')) {
			for my $tr_in ($table2->look_down('_tag', 'tr')) {
				for my $td ($tr_in->look_down('_tag', 'td')){
					for my $link ($td->look_down('_tag', 'a')) {
						# Get Name, 
						$name = $link->as_text . "\n" if defined $link;
						chomp($name);
						if ( $name =~ m/♦/) {
							$name =~ s/\s*♦\s*//;
							$cards->{$name}->{uniqueness} = 'true';
						}
						else{
							$cards->{$name}->{uniqueness} = 'false';
						}
						$cards->{$name}->{cgdb_url} = $link->attr('href');
					}
#					for my $b ($td->look_down('_tag', 'b')) {
#						print $b->as_text . "\n";
#					}
					my $data = $td->as_HTML . "\n";
					$data =~ s/<br \/>/\n/g;
					$data =~ s/<td.*>/\n/g;
					$data =~ s/\s(<b>)/\n$1/g;
					my @data = split(/\n/,$data);
					for my $d (@data) {
						next if $d =~ m/^$/;
#						print "raw: $d" . "\n";
						my $field;
						my $field_data;
						if ( $d =~ m/<b>([^:]*):<\/b>\s*(.*)$/) {
							$field = $1;
							$field_data = $2;
							$field_data =~ s/\s*$//; 
							$field_data =~ s/\s*<\/td>$//;
							#Exceptions, and further separations.
							if ( $field =~ m/^Faction$/){
								$field_data =~ m/([^ ]*)\s(.*)/;
								my $side = $1;
								my $faction = $2;
								$faction =~ s/^The //;
								$cards->{$name}->{faction} = $faction;
								$cards->{$name}->{side} = $side;
								next;
							}
							elsif ($field =~ m/^Type$/){
								$field_data =~ m/([^:]*):\s*(.*)/;
								my $type = $1;
								my $subtype = $2 if defined $2;
								$cards->{$name}->{type} = $type;
								$cards->{$name}->{subtype} = $subtype if defined $subtype;
								next;
							}
						}
						elsif ( $d =~ m/<i>(.*)<\/i>$/ ){
							$field = 'flavor';
							$field_data = $1;
						}
						elsif ($d !~ m/^</){
							chomp($d);
							$d =~ s/<strong[^>]*>/<strong>/g;
							$d =~ s/\s*$//;
							$d =~ s/^\s*//;
							if (defined $cards->{$name}->{text}) {
								$d = "\\r\\n" . $d;
							}
							$cards->{$name}->{text} .= $d;
							next;
						}
						$cards->{$name}->{$field} = $field_data if defined $field_data;

#						print "field: $field\n";
#						print "data: $field_data\n";

					}
				}
			}
		}
	}
}
#exit 0;

for my $name (keys $cards) {
	print "    {\n";
	print "      \"title\": \"$name\",\n";
	for (keys $cards->{$name}) {
		print"      \"". lc($_) ."\": \"" . $cards->{$name}->{$_} . "\",\n";
	}
	print "    },\n";
}
