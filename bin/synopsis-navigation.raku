#!/usr/bin/env raku 
use lib '../lib';   #REMOVE ME
use Physics::Navigation;
use Physics::Measure;

my $lat1 = Latitude.new( value => 45, compass => <N> );
say ~$lat1, ' ... ', $lat1.WHAT;

my $lat2 ♓️ <43°30′30″S>;
say ~$lat2, ' ... ', $lat2.WHAT;

my $nmiles ♓️ "7 nmiles";
say ~$nmiles;

my $nm2 = $nmiles * 2;
say ~$nm2;

my $lat3 = $lat2 + $lat1;
say ~$lat3, ' ... ', $lat3.WHAT;

my $lat4 = $lat2 - $lat1;
say ~$lat4, ' ... ', $lat4.WHAT;

$lat1 ♓️ $lat3;
say ~$lat1, ' ... ', $lat1.WHAT;

$lat2 = $lat4;
say ~$lat2, ' ... ', $lat2.WHAT;

my $long1 ♓️ <45°W>;
say ~$long1, ' ... ', $long1.WHAT;

$Physics::Navigation::variation = CompassAdj.new( value => 7, compass => <W> );
say ~$Physics::Navigation::variation;

my $bear1 ♓️ <80°T>;
say ~$bear1, ' ... ', $bear1.WHAT;

my $bear2 ♓️ <43°30′30″M>;
say ~$bear2, ' ... ', $bear2.WHAT;

my $bear3 = $bear2 + $bear1.M;
say ~$bear3, ' ... ', $bear3.WHAT;

my $steer = CourseAdj.new( value => 45, compass => <P> );
say ~$steer, ' ... ', $steer.WHAT;

my $bear4 = $bear2 + $steer;
say ~$bear4, ' ... ', $bear4.WHAT;

try {
	my $bear-nope = $bear2 + $bear1;
}
if $! { say "Something failed ... $!" }

