#!/usr/bin/env raku 
use lib '../lib';   #REMOVE ME
use Physics::Navigation;
use Physics::Measure;

$Physics::Measure::round-val = 0.1;

my Distance $d1   .=new( value => 42,  units => 'nmile' );	say ~$d1;
my Time     $t1   .=new( value => 1.5, units => 'hr' );		say ~$t1;
my Latitude $lat1 .=new( value => 45, compass => <N> );		say ~$lat1;

my $d2 = ♓️ '42 nmile';							say ~$d2,	 ' ... ',  $d2.^name;
my $t2 = ♓️ '1.5 hr';							say ~$t2,    ' ... ',  $t2.^name;
my $s2 = $d2 / $t2;								say ~$s2.in('knots'), ' ... ',  $s2.^name;

my $lat2 = ♓️ <43°30′30″S>;						say ~$lat2,  ' ... ', $lat2.^name;
my $lat3 = in-lat( $d1 );						say ~$lat3,  ' ... ', $lat3.^name;

my $d3 = $lat2.in('nmiles');					say ~$d3,    ' ... ', $d3.^name;
my $d4 = $d3 * 2;								say ~$d4;

my $long1 = ♓️ <45°W>;							say ~$long1, ' ... ', $long1.^name;
my $long2 = ♓️ <22°E>;							say ~$long2, ' ... ', $long2.^name;

#[   #test1
my $lat4 = $lat2 - $lat1;
say ~$lat4, ' ... ', $lat4.^name;

$lat1 = ♓️ "$lat3";
say ~$lat1, ' ... ', $lat1.^name;

$lat2 = $lat4;
say ~$lat2, ' ... ', $lat2.^name;

$Physics::Navigation::variation = Variation.new( value => 7, compass => <W> );
say ~$Physics::Navigation::variation;

my $bear1 = ♓️ <80°T>;
say ~$bear1, ' ... ', $bear1.^name;

my $bear2 = ♓️ <43°30′30″M>;
say ~$bear2, ' ... ', $bear2.^name;

my $bear3 = $bear2 + $bear1.M;
#my $bear3 = $bear2 + $bear2;
say ~$bear3, ' ... ', $bear3.^name;

my $steer = CourseAdj.new( value => 45, compass => <Pt> );
say ~$steer, ' ... ', $steer.^name;

my $bear4 = $bear2 + $steer;
say ~$bear4, ' ... ', $bear4.^name;

my $bear5 = $bear4.back;
say ~$bear5, ' ... ', $bear5.^name;

try {
	my $bear-nope = $bear2 + $bear1;
}
if $! { say "Something failed ... $!" }
#]

my Position $start .=new( $lat1, $long1 );		say ~$start, ' ... ', $start.^name;
my Position $dest  .=new( $lat2, $long2 );		say ~$dest,  ' ... ', $dest.^name;

say ~$start.haversine-dist($dest).in('km'); 
say ~$start.forward-azimuth($dest); 

my $vect  = $start.diff($dest);					say ~$vect,  ' ... ', $vect.^name;
my $dest2 = $start.move($vect);					say ~$dest2, ' ... ', $dest2.^name;

my $dur   = ♓️ '3 weeks';						say ~$dur,   ' ... ', $dur.^name;
my $vel   = $vect.divide: $dur;					say ~$vel,   ' ... ', $vel.^name;
my $vect2 = $vel.multiply: $dur;				say ~$vect2, ' ... ', $vect.^name;

%course-info<leeway> = CourseAdj.new( value => 1, compass => <Pt> );
my $tide-direction = ♓️<112°T>;
my $tide-speed = ♓️ '2.2 knots';
my $tidal-flow = Velocity.new( θ => $tide-direction, s => $tide-speed );

my Course $course .= new( over-ground => ♓️<22°T>, :$tidal-flow );
say ~$course,  ' ... ', $course.^name;

say $course.to-steer;
say $course.speed-over-ground.in('knots');

my Fix @landmarks;

@landmarks.push: Fix.new( direction => ♓️<112°T>,
                          location  => Position.new( ♓️<51.5072°N>, ♓️<0.1276°W> ) );
@landmarks.push: Fix.new( direction => ♓️<25°T>,
                          location  => Position.new( ♓️<51.6°N>, ♓️<0.1276°W> ) );
@landmarks.push: Fix.new( direction => ♓️<237°T>,
                          location  => Position.new( ♓️<51.5072°N>, ♓️<0.14°W> ) );
say @landmarks.join(', ');

my Estimate $estimated .= new( fixes => @landmarks );
say ~$estimated;







