#!/usr/bin/env raku 
use lib '../lib';   #REMOVE ME
use Physics::Navigation;
use Physics::Measure;		#<== use Physics::Measure 2nd

#Angles can have units of degrees/minutes/seconds, or radians
    my $angle-in-degrees ♎️ '7 °';  #7 ° U+00B0
	say "My angle in degrees is $angle-in-degrees";
    my $angle-in-minutes ♎️ '7 ′';  #7 ′ U+2032
	say "My angle in minutes is $angle-in-minutes";
    my $angle-in-seconds ♎️ '7 ″';  #7 ″ U+2033
	say "My angle in seconds is $angle-in-seconds";
    my $angle-in-radians = $angle-in-degrees.in('radians'); #0.122173047639603065 radian
	say "My angle in radians is $angle-in-radians";
#NB. The unit name 'rad' is reserved for the unit of radioactive Dose

my $sine-of-angle = sin( $angle-in-degrees );
say "My sine of angle is $sine-of-angle";

my $arc-sine = asin( $sine-of-angle );
say $arc-sine;

