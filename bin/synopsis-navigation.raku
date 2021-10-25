#!/usr/bin/env raku 
use lib '../lib';   #REMOVE ME
use Physics::Navigation;
use Physics::Measure;

$Physics::Measure::round-val = 0.1;

my Distance $d1   .=new( value => 42,  units => 'nmile' );	say ~$d1;
my Time     $t1   .=new( value => 1.5, units => 'hr' );		say ~$t1;
my Latitude $lat1 .=new( value => 45, compass => <N> );		say ~$lat1;

my $d2 = ♓️'42 nmile';							say ~$d2;
my $t2 = ♓️'1.5 hr';							say ~$t2;
my $s2 = $d2 / $t2;								say ~$s2.in('knots');

my $lat2 = ♓️<43°30′30″S>;						say ~$lat2;
my $lat3 = in-lat( $d1 );						say ~$lat3;

my $d3 = $lat2.in('nmiles');					say ~$d3;
my $d4 = $d3 * 2;								say ~$d4;

my $long1 = ♓️<45°W>;							say ~$long1;
my $long2 = ♓️<22°E>;							say ~$long2;

my $lat4 = $lat2 - $lat1;                       say ~$lat4;

$lat1 = ♓️"$lat3";                              say ~$lat1;
$lat2 = $lat4;                                  say ~$lat2;

$Physics::Navigation::variation = Variation.new( value => 7, compass => <W> );

my $bear1 = ♓️<80°T>;                           say ~$bear1;
my $bear2 = ♓️<43°30′30″M>;                     say ~$bear2;
my $bear3 = $bear2 + $bear1.M;                  say ~$bear3;

my $steer = CourseAdj.new( value => 45, compass => <Pt> );      say ~$steer;

my $bear4 = $bear2 + $steer;                    say ~$bear4;
my $bear5 = $bear4.back;                        say ~$bear5;

try {
	my $bear-nope = $bear2 + $bear1;
}
if $! { say "Something failed ... $!" }

my Position $start .=new( $lat1, $long1 );		say ~$start;
my Position $dest  .=new( $lat2, $long2 );		say ~$dest;

say ~$start.haversine-dist($dest).in('km'); 
say ~$start.forward-azimuth($dest); 

my $vect  = $start.diff($dest);					say ~$vect;
my $dest2 = $start.move($vect);					say ~$dest2;

my $dur   = ♓️'3 weeks';						say ~$dur;
my $vel   = $vect.divide: $dur;					say ~$vel;
my $vect2 = $vel.multiply: $dur;				say ~$vect2;

%course-info<leeway> = CourseAdj.new( value => 1, compass => <Pt> );
my $tidal-flow = Velocity.new( θ => ♓️<112°T>, s => ♓️'2.2 knots' );

my Course $course .= new( over-ground => ♓️<22°T>, :$tidal-flow );  say ~$course;
say $course.speed-over-ground.in('knots');


my $fix-A = Fix.new( direction => ♓️<112°T>,
                     location  => Position.new( ♓️<51.5072°N>, ♓️<0.1276°W> ) );
my $fix-B = Fix.new( direction => ♓️<25°T>,
                     location  => Position.new( ♓️<51.6°N>, ♓️<0.1276°W> ) );

my $ep = Estimate.new( :$fix-A, :$fix-B );      say ~$ep;







