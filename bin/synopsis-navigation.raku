#!/usr/bin/env raku 
use lib '../lib';   #REMOVE ME
use Physics::Navigation;

#$Physics::Navigation::round-to variable is applied to Str output if defined
$Physics::Navigation::round-to = 0.01;
 
my $lat1 = Latitude.new( value => 45, compass => <N> );
say ~$lat1;
say $lat1.WHAT;

my $lat2 ♓️ <43°N>;
say ~$lat2;
say $lat2.WHAT;

my $lat3 = $lat2 ♓️+ $lat1;
say ~$lat3;

die "yo";

my $lat4 = $lat2 ♓️- $lat1;
say ~$lat4;

$lat2 ♓️ <55°30′30″S>;
say ~$lat2;

$lat2 ♓️ $lat1;
say ~$lat2;

my $long1 ♓️ <45°W>;
say ~$long1;

my $bear1 ♓️ <45°M>;
say ~$bear1;
