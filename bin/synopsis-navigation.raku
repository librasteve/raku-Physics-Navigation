#!/usr/bin/env raku 
use lib '../lib';   #REMOVE ME
use Physics::Navigation;
use Physics::Measure;

$Physics::Measure::round-val = 0.1;

my Distance $d1   .=new( value => 42,  units => 'nmile' );	say ~$d1;
my Time     $t1   .=new( value => 1.5, units => 'hr' );		say ~$t1;
my Latitude $lat1 .=new( value => 45, compass => <N> );		say ~$lat1;

my $d2 = ♓️'42 nmile';						say ~$d2;
my $t2 = ♓️'1.5 hr';						say ~$t2;
my $s2 = $d2 / $t2;						    say ~$s2.in('knots');

my $lat2 = ♓️<43°30′30″S>;					say ~$lat2;
my $lat3 = in-lat( $d1 );					say ~$lat3;

my $d3 = $lat2.in('nmiles');				say ~$d3;
my $d4 = $d3 * 2;						    say ~$d4;

my $long1 = ♓️<45°W>;						say ~$long1;
my $long2 = ♓️<22°E>;						say ~$long2;

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

my Position $start  .=new( $lat1, $long1 );	say ~$start;
my Position $finish .=new( $lat2, $long2 );	say ~$finish;

say ~$start.haversine-dist($finish).in('km');
say ~$start.forward-azimuth($finish);

my $vector  = $start.diff($finish);			say ~$vector;
my $finish2 = $start.move($vector);			say ~$finish2;

my $dur     = ♓️'3 weeks';			        say ~$dur;
my $vel     = $vector.divide: $dur;			say ~$vel;
my $vector2 = $vel.multiply: $dur;		    say ~$vector2;

my $pos-A = Position.new( ♓️<51.5072°N>, ♓️<0.1276°W> );
my $pos-B = Position.new( ♓️<51.5072°N>, ♓️<0.1110°W> );
my $pos-C = Position.new( ♓️<51.5072°N>, ♓️<0.1100°W> );

my $fix-A = Fix.new( direction => ♓️<112°T>, location  => $pos-A );
my $fix-B = Fix.new( direction => ♓️<25°T>,  location  => $pos-B );

my $ep = Estimate.new( :$fix-A, :$fix-B );      say ~$ep;

my $tr = Transit.new( :$pos-A, :$pos-B );       say $tr.aligned( $pos-C );


%course-info<leeway> = CourseAdj.new( value => 1, compass => <Pt> );
my $tidal-flow = Velocity.new( θ => ♓️<112°T>, s => ♓️'2.2 knots' );

my Course $course .= new( over-ground => ♓️<22°T>, :$tidal-flow );  say ~$course;
say $course.speed-over-ground.in('knots');

my $scm = SouthCardinal.new( position => $pos-A );
say $scm.light-defn;
say ~$scm;

$IALA = A;
my $plm = PortLateral.new( position => $pos-B );
say $plm.light-defn;
say ~$plm;
