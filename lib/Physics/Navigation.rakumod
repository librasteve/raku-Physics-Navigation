unit module Physics::Navigation:ver<0.0.3>:auth<Steve Roe (p6steve@furnival.net)>;
use Physics::Measure;

## May want to promote these features to Physics::Measure / Physics::Unit at some point?
## Right now interesting to see what a child module would look like

#| Override sin/cos/tan for Unit type Angle
#| Automatically convert argument to radians
multi sin( Angle:D $a ) is export {
    sin( $a.in('radian').value );
}
multi cos( Angle:D $a ) is export {
    cos( $a.in('radian').value );
}
multi tan( Angle:D $a ) is export {
    tan( $a.in('radian').value );
}

#| Override asin/acos/atan accept unitsof arg and return Angle object
multi asin( Numeric:D $x, Str :$units! ) is export { 
    my $a = Angle.new( value => asin( $x ), units => 'radians' );
    return $a.in( $units );
}
multi acos( Numeric:D $x, Str :$units! ) is export { 
    my $a = Angle.new( value => acos( $x ), units => 'radians' );
    return $a.in( $units );
}
multi atan( Numeric:D $x, Str :$units! ) is export { 
    my $a = Angle.new( value => atan( $x ), units => 'radians' );
    return $a.in( $units );
}

#compound dms Angle type
