# raku Physics::Navigation

This module is an abstraction on [Physics::Measure](https://github.com/p6steve/raku-Physics-Measure) that provides Latitude, Longitude, Bearing, Position, Course and Buoy classes.

Provides Measure objects that have value, units and error and can be used in many common physics calculations. Uses [Physics::Unit](https://github.com/p6steve/raku-Physics-Unit) and [Physics::Error](https://github.com/p6steve/raku-Physics-Error).

# Instructions
```zef --verbose install Physics::Navigation```

and, conversely, ```zef uninstall Physics::Navigation```

**For a gentler introduction to and explanation of these features, please refer to [raku Yacht Navigation](https://github.com/p6steve/raku-Yacht-Navigation) for a descriptive Jupyter notebook**

# Synopsis

```perl6
use lib '../lib';
use Physics::Navigation;
use Physics::Measure;

# objects can be set up longhand as in Physics::Measure, now joined by Latitude, Longitude, etc.
$Physics::Measure::round-val = 0.1;

my Distance $d1   .=new( value => 42,  units => 'nmile' );	  say ~$d1;
my Time     $t1   .=new( value => 1.5, units => 'hr' );		  say ~$t1;
my Latitude $lat1 .=new( value => 45, compass => <N> );		  say ~$lat1;

# the emoji ♓️ <pisces> operator shorthand does all that the Physics::Measure emoji ♎️ <libra> operator does
my $d2 = ♓️'42 nmile';						  say ~$d2;
my $t2 = ♓️'1.5 hr';						  say ~$t2;
my $s2 = $d2 / $t2;						  say ~$s2.in('knots');

# and then some - parses final NEWS letter to determine lat or long
my $lat2 = ♓️<43°30′30″S>;				          say ~$lat2;
my $long1 = ♓️<45°W>;						  say ~$long1;
my $long2 = ♓️<22°E>;						  say ~$long2;

# the .in conversion method works and the identity 1° lat === 1 nautical mile is preserved
my $lat3 = in-lat( $d1 );					  say ~$lat3;
my $d3 = $lat2.in('nmiles');			                  say ~$d3;

# you can do "Measure math" using the standard operators <[+-*/**]>
my $d4 = $d3 * 2;						  say ~$d4;
my $lat4 = $lat2 - $lat1;                                         say ~$lat4;

# Bearings can be True(T) or Magnetic(M), with Variation and Deviation [Vw|Ve|Dw|De]
$Physics::Navigation::variation =  ♓️<7°Vw>;

my $bear1 = ♓️<80°T>;                                             say ~$bear1;
my $bear2 = ♓️<43°30′30″M>;                                       say ~$bear2;
my $bear3 = $bear2 + $bear1.M;                                    say ~$bear3;

# here's how to steer your boat to Port (Pt) or Starboard (Sb)
my $steer = ♓️<50Pt°>;                                            say ~$steer;
my $bear4 = $bear2 + $steer;                                      say ~$bear4;
my $bear5 = $bear4.back;                                          say ~$bear5; #and take a back bearing

try {
	my $bear-nope = $bear2 + $bear1;
}
if $! { say "Can't mix True & Magnetic ... $!" }

my Position $start  .=new( $lat1, $long1 );	                  say ~$start;
my Position $finish .=new( $lat2, $long2 );	                  say ~$finish;

# get great circle distance and initial azimuth bearing
say ~$start.haversine-dist($finish).in('km');
say ~$start.forward-azimuth($finish);

# make a Vector (angle + distance) and move by that amount
my $vector  = $start.diff($finish);			         say ~$vector;
my $finish2 = $start.move($vector);			         say ~$finish2;

# use Measure math to make Velocity objects
my $dur     = ♓️'3 weeks';			                 say ~$dur;
my $vel     = $vector.divide: $dur;			         say ~$vel;
my $vector2 = $vel.multiply: $dur;		                 say ~$vector2;

my $pos-A = Position.new( ♓️<51.5072°N>, ♓️<0.1276°W> );
my $pos-B = Position.new( ♓️<51.5072°N>, ♓️<0.1110°W> );
my $pos-C = Position.new( ♓️<51.5072°N>, ♓️<0.1100°W> );

# there are Fixes, Estimated positions and Transits
my $fix-A = Fix.new( direction => ♓️<112°T>, location  => $pos-A );
my $fix-B = Fix.new( direction => ♓️<25°T>,  location  => $pos-B );

my $ep = Estimate.new( :$fix-A, :$fix-B );                      say ~$ep;

my $tr = Transit.new( :$pos-A, :$pos-B );                       say $tr.aligned( $pos-C );

# Course objects handle Course To Steer, Tidal Flow, Course Over Ground (and leeway)
%course-info<leeway> =  ♓️<112°Pt>;
my $tidal-flow = Velocity.new( θ => ♓️<112°T>, s => ♓️'2.2 knots' );
my Course $course .= new( over-ground => ♓️<22°T>, :$tidal-flow );  say ~$course;
say $course.speed-over-ground.in('knots');

# Buoy objects know their shape, colour, light pattern, etc.
my $scm = SouthCardinal.new( position => $pos-A );               say ~$scm;
my $ncm = NorthCardinal.new( position => $pos-A );               say ~$ncm;

# Lateral Buoys know about IALA standards
$IALA = A;
my $plm = PortLateral.new( position => $pos-B );                 say ~$plm;

# use .light-defn to get an English description
say $plm.light-defn;

# .duration and .patterm methods also support SVG animation
say "SVG-animation: duration is {$plm.light-svg.duration}s, pattern is: [{$plm.light-svg.pattern}];";
```

# Summary

The family of Physics::Navigation, Physics::Measure, Physics::Unit, Physics::Error and Physics::Constants raku modules is a consistent and extensible toolkit intended for science and education. It provides a comprehensive library of both metric (SI) and non-metric units, it is built on a Type Object foundation, it has a unit expression Grammar and implements math, conversion and comparison methods.

# Contribution

You are welcome to contribute in any way - please open a pull request.

Any feedback is welcome to p6steve / via the github Issues above.
