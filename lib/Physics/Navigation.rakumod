unit module Physics::Navigation:ver<0.0.3>:auth<Steve Roe (p6steve@furnival.net)>;
use Physics::Measure;

#| Override sin/cos/tan for Unit type Angle
#| Automatically convert argument to radians
multi sin( Angle:D $a ) is export {
	samewith: $a.in('radian').value
}
multi cos( Angle:D $a ) is export {
	samewith: $a.in('radian').value
}
multi tan( Angle:D $a ) is export {
	samewith: $a.in('radian').value
}


