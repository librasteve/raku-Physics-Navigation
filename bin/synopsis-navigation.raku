#!/usr/bin/env raku 
use lib '../lib';   #REMOVE ME
use Physics::Navigation;
use Physics::Measure;

#round-to variable is applied to Str output if defined
$Physics::Navigation::round-to = 0.01;

my $lat1 = Latitude.new( value => 45, compass => <N> );
say ~$lat1; say $lat1.WHAT;

my $lat2 ♓️ <43°30′30″S>;
say ~$lat2; say $lat2.WHAT;

my $nmiles ♓️ "7 nmiles";
say ~$nmiles;

my $nm2 = $nmiles + $nmiles;
say ~$nm2;

my $lat3 = $lat2 + $lat1;
say ~$lat3;

my $lat4 = $lat2 - $lat1;
say ~$lat4; say $lat4.WHAT;

$lat1 ♓️ $lat3;
say ~$lat1; say $lat1.WHAT;

$lat2 = $lat4;
say ~$lat2; say $lat2.WHAT;

my $long1 ♓️ <45°W>;
say ~$long1; say $long1.WHAT;

my $bear1 ♓️ <80°M>;
say ~$bear1; say $bear1.WHAT;

my $bear2 ♓️ <43°30′30″M>;
say ~$bear2; say $bear2.WHAT;

my $bear3 = $bear2 + $bear1;
say ~$bear3; say $bear3.WHAT;

my CompassAdjustment $variation = CompassAdjustment.new( value => 7, compass => <W> );
say ~$variation; say $variation.WHAT;

$Physics::Navigation::variation = $variation;
say ~$bear2.M;
say ~$bear2.T;

#`[[ 
#]]
