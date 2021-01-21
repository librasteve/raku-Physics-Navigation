#!/usr/bin/env raku 
use lib '../lib';   #REMOVE ME
use Physics::Navigation;
use Physics::Measure;

$Physics::Measure::round-to = 0.05;

my Distance $d1   .=new( value => 42,  units => 'nmile' );	say ~$d1;
my Time     $t1   .=new( value => 1.5, units => 'hr' );		say ~$t1;
my Latitude $lat1 .=new( value => 45, compass => <N> );		say ~$lat1;

my $d2 ♓️ '42 nmile';							say ~$d2,	 ' ... ',  $d2.WHAT;
my $t2 ♓️ '1.5 hr';								say ~$t2,    ' ... ',  $t2.WHAT;
my $s2 = $d2 / $t2;								say ~$s2.in('knots'), ' ... ',  $s2.WHAT;

my $lat2 ♓️ <43°30′30″S>;						say ~$lat2,  ' ... ', $lat2.WHAT;
my $lat3 = in-lat( $d1 );						say ~$lat3,  ' ... ', $lat3.WHAT;

my $d3 = $lat2.in('nmiles');					say ~$d3,    ' ... ', $d3.WHAT;
my $d4 = $d3 * 2;								say ~$d4;

my $long1 ♓️ <45°W>;							say ~$long1, ' ... ', $long1.WHAT;
my $long2 ♓️ <22°E>;							say ~$long2, ' ... ', $long2.WHAT;

my Position $start .=new( $lat1, $long1 );		say ~$start, ' ... ', $start.WHAT;
my Position $dest  .=new( $lat2, $long2 );		say ~$dest,  ' ... ', $dest.WHAT;

#say ~$start.haversine-dist($dest).in('km'); 
#say ~$start.forward-azimuth($dest); 

my $diff = $start.diff($dest);						say ~$diff,  ' ... ', $diff.WHAT;
my $dest2 = $start.move($diff);						say ~$dest2,  ' ... ', $dest2.WHAT;





#[   #test1
my $lat4 = $lat2 - $lat1;
say ~$lat4, ' ... ', $lat4.WHAT;

$lat1 ♓️ $lat3;
say ~$lat1, ' ... ', $lat1.WHAT;

$lat2 = $lat4;
say ~$lat2, ' ... ', $lat2.WHAT;

$Physics::Navigation::variation = Variation.new( value => 7, compass => <W> );
say ~$Physics::Navigation::variation;

my $bear1 ♓️ <80°T>;
say ~$bear1, ' ... ', $bear1.WHAT;

my $bear2 ♓️ <43°30′30″M>;
say ~$bear2, ' ... ', $bear2.WHAT;

my $bear3 = $bear2 + $bear1.M;
say ~$bear3, ' ... ', $bear3.WHAT;

my $steer = CourseAdj.new( value => 45, compass => <Pt> );
say ~$steer, ' ... ', $steer.WHAT;

my $bear4 = $bear2 + $steer;
say ~$bear4, ' ... ', $bear4.WHAT;

my $bear5 = $bear4.back;
say ~$bear5, ' ... ', $bear5.WHAT;

try {
	my $bear-nope = $bear2 + $bear1;
}
if $! { say "Something failed ... $!" }
#]
