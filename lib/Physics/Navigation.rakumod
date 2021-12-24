unit module Physics::Navigation:ver<0.0.3>:auth<Steve Roe (p6steve@furnival.net)>;
use Physics::Measure;

## Provides extensions to Physics::Measure and Physics::Unit for nautical navigation...
##  - NavAngle math (add, subtract)
##  - replace ♎️ with ♓️ (pisces) for NavAngle defn-extract
##  - apply Variation, Deviation, CourseAdj to Bearing
##  - nmiles <=> Latitude arcmin identity
##  - Position class
##  - ESE
##  - Course class - COG, CTS, COW, Tide, Leeway
##  - my Position $p3 .=new( $lat2, ♓️<22°E> ); [Position as 2 Str]
##  - Fixes
##  - EP with 2 Fixes
##  - Buoys
##  - Lights (grammar)

## version 2 backlog
##  - Transits
##  - Estimates with 3 Fixes (cocked hat)
##  - Uncertainty
##  - Passages - Milestones and Legs
##  - Tide ladders (rule of 12ths)
##  - Beaufort scale
##  - Sea state scale
##  - Visibility scale
##  - Vessels


my $db = 0;                 #debug

our $round-val := $Physics::Measure::round-val;     #NB. Bearings always round to 1 degree

class Variation { ... }
class Deviation { ... }

our $variation = Variation.new( value => 0, compass => <Vw> );
our $deviation = Deviation.new( value => 0, compass => <Dw> );

class NavAngle is Angle {
	has $.units where *.name eq '°';

	multi method new( Str:D $s ) {						say "NA new from Str ", $s if $db;
        my ($value, $compass) = NavAngle.defn-extract( $s );
		my $type;
		given $compass {
			when <N S>.any   { $type = 'Latitude' }
			when <E W>.any   { $type = 'Longitude' }
			when <T>.any	 { $type = 'BearingTrue' }
			when <M>.any	 { $type = 'BearingMag' }
			when <Ve Vw>.any { $type = 'Variation' }
			when <De Dw>.any { $type = 'Deviation' }
			when <Pt Sb>.any { $type = 'CourseAdj' }
			default			 { nextsame }
		}
        ::($type).new( :$value, :$compass );
    }
    multi method new( :$value!, :$units, :$compass ) {	say "NA new from attrs" if $db; 
		warn "NavAngles always use degrees!" if $units.defined && ~$units ne '°'; 

		my $nao = self.bless( :$value, units => GetMeaUnit('°') );
		$nao.compass( $compass ) if $compass;
		return $nao
    }
	method clone( ::T: ) {							    say "NA cloning " ~ T.^name if $db;
		::T.new: :$.value
	}

    method raku {
        q|\qq[{self.^name}].new( value => \qq[{$.value}], compass => \qq[{$.compass}] )|;
    }    

    method Str ( :$rev, :$fmt ) {
        my $neg = $.compass eq $rev ?? 1 !! 0;			#negate value if reverse pole
        my ( $deg, $min ) = self.dms( :no-secs, :negate($neg) );    
        $deg = sprintf( $fmt, $deg );
        $min = $round-val ?? $min.round($round-val) !! $min;
        qq|$deg°$min′$.compass|
    }

    #| class method baby Grammar for initial extraction of definition from Str (value/unit/error)
    method defn-extract( NavAngle:U: Str:D $s ) {

        #handle degrees-minutes-seconds <°> is U+00B0 <′> is U+2032 <″> is U+2033
		#NB different to Measure.rakumod, here arcmin ′? is optional as want eg. <45°N> to parse 

        unless $s ~~ /(<[\d.]>*)\°(<[\d.]>*)\′?(<[\d.]>*)\″?\w*(<[NSEWMT]>)/ { return 0 };

		my $deg where 0 <= * < 360 = $0 % 360;
		my $min where 0 <= * <  60 = $1 // 0;
		my $sec where 0 <= * <  60 = $2 // 0;
		my $value = ( ($deg * 3600) + ($min * 60) + $sec ) / 3600;
		my $compass = ~$3;

		say "NA extracting «$s»: value is $deg°$min′$sec″, compass is $compass" if $db;
		return( $value, $compass )
	}
}

######## Replace ♎️ with ♓️ #########
#to do NavAngle specific defn-extract!
multi prefix:<♓️>    ( Str:D $new )      is export { NavAngle.new: $new }

class Latitude is NavAngle is export {
	has Real  $.value is rw where -90 <= * <= 90; 

	multi method compass {								#get compass
		$.value >= 0 ?? <N> !! <S>
	}
	multi method compass( Str $_ ) {					#set compass
		$.value = -$.value if $_ eq <S> 
	}

	method Str {
		nextwith( :rev<S>, :fmt<%02d> )
	}

	multi method add( Latitude $l ) {
		self.value += $l.value;
		self.value = 90 if self.value > 90;				#clamp to 90°
		return self
	}    
	multi method subtract( Latitude $l ) {
		self.value -= $l.value;
		self.value = -90 if self.value < -90;			#clamp to -90°
		return self
	}

	#| override .in to perform identity 1' (Latitude) == 1 nmile
	method in( Str $s where * eq <nmile nmiles nm>.any ) {
		my $nv = $.value * 60;
		Distance.new( "$nv nmile" )
	}
}

sub in-lat( Length $l ) is export {
	#| ad-hoc sub to perform identity 1' (Latitude) == 1 nmile
		my $nv = $l.value / 60;
		Latitude.new( value => $nv, compass => <N> )
}

class Longitude is NavAngle is export {
	has Real  $.value is rw where -180 < * <= 180; 

	multi method compass {								#get compass
		$.value >= 0 ?? <E> !! <W>
	}
	multi method compass( Str $_ ) {					#set compass
		$.value = -$.value if $_ eq <W> 
	}

	method Str {
		nextwith( :rev<W>, :fmt<%03d> );
	}

	multi method add( Longitude $l ) {
		self.value += $l.value;
		self.value -= 360 if self.value > 180;			#overflow from +180 to -180
		return self
	}    
	multi method subtract( Longitude $l ) {
		self.value += 360 if self.value <= -180;		#underflow from -180 to +180
		return self
	}    
}

#| Bearing embodies the identity 'M = T + Vw', so...
#| Magnetic = True + Variation-West [+ Deviation-West]

class Bearing is NavAngle {
	has Real  $.value is rw where 0 <= * <= 360; 

	#| viz. https://en.wikipedia.org/wiki/Points_of_the_compass
	method points( :$dec ) {
		return '' unless $dec;

		my @all-points = <N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW>;
		my %pnt-count = %( cardinal => 4, ordinal => 8, half-winds => 16 );

		my $iter = %pnt-count{$dec};
		my $step = 360 / $iter;
		my $rvc = ( $.value + $step/2 ) % 360;		#rotate value clockwise by half-step
		for 0..^$iter -> $i {
			my $port = $step * $i;
			my $star = $step * ($i+1);
			if $port < $rvc <= $star {				#using slice sequence to sample @all-points
				return @all-points[0,(16/$iter)...*][$i]
			}
		}
	} 

	method Str( :$fmt, :$dec='half-winds' )  {
		nextsame if $fmt;								#pass through to NA.Str
		my $d = sprintf( "%03d", $.value.round(1) );	#always rounds to whole degs 
		my $p = $.points( :$dec );						#specify points decoration style
		qq|$d°$p ($.compass)|
	}

	multi method add( Bearing $r ) {
		self.value = ( self.value + $r.value ) % 360;
		return self 
	}
	multi method subtract( Bearing $r ) {
		self.value = ( self.value - $r.value ) % 360;
		return self 
	}

	method back() {										#ie. opposite direction 
		my $res = self.clone;
		$res.value = ( $.value + 180 ) % 360;
		return $res
	}
}

class BearingTrue { ...}
class BearingMag  { ...}

sub err-msg { die "Can't mix BearingTrue and BearingMag for add/subtract!" }

class BearingTrue is Bearing is export {

	multi method compass { <T> }						#get compass

	multi method compass( Str $_ ) {					#set compass
		die "BearingTrue compass must be <T>" unless $_ eq <T> }

	method M {											#coerce to BearingMag
		my $nv = $.value + ( +$variation + +$deviation );
		BearingMag.new( value => $nv, compass => <M> )
	}

	#| can't mix unless BearingMag 
	multi method add( BearingMag ) { err-msg }
	multi method subtract( BearingMag ) { err-msg }
}

class BearingMag is Bearing is export {

	multi method compass { <M> }						#get compass

	multi method compass( Str $_ ) {					#set compass
		die "BearingMag compass must be <M>" unless $_ eq <M>
	}

	method T {											#coerce to BearingTrue
		my $nv = $.value - ( +$variation + +$deviation );
		BearingTrue.new( value => $nv, compass => <T> )
	}

	#| can't mix unless Bearing True 
	multi method add( BearingTrue ) { err-msg }
	multi method subtract( BearingTrue ) { err-msg }
}

class Variation is Bearing is export {
	has Real  $.value is rw where -180 <= * <= 180; 

	multi method compass {								#get compass
		$.value >= 0 ?? <Vw> !! <Ve>
	}
	multi method compass( Str $_ ) {					#set compass
		$.value = -$.value if $_ eq <Ve> 
	}

	method Str {
		nextwith( :rev<Ve>, :fmt<%02d> );
	}
}

class Deviation is Bearing is export {
	has Real  $.value is rw where -180 <= * <= 180;

	multi method compass {								#get compass
		$.value >= 0 ?? <Dw> !! <De>
	}
	multi method compass( Str $_ ) {					#set compass
		$.value = -$.value if $_ eq <De> 
	}

	method Str {
		nextwith( :rev<De>, :fmt<%02d> );
	}
}

class CourseAdj is Bearing is export {
	has Real  $.value is rw where -180 <= * <= 180; 

	multi method compass {								#get compass
		$.value >= 0 ?? <Sb> !! <Pt>
	}
	multi method compass( Str $_ ) {					#set compass
		$.value = -$.value if $_ eq <Pt> 
	}

	method Str {
		nextwith( :rev<Pt>, :fmt<%02d> );
	}
}

####### Position, Vector & Velocity #########

#| using Haversine formula (±0.5%) for great circle distance
#| viz. https://en.wikipedia.org/wiki/Haversine_formula
#| viz. http://rosettacode.org/wiki/Haversine_formula#Raku
#|
#| initial bearing only as bearing changes along great cirlce routes
#| viz. https://www.movable-type.co.uk/scripts/latlong.html

#FIXME v2 - Upgrade to geoid math 
# viz. https://en.wikipedia.org/wiki/Reference_ellipsoid#Coordinates

constant \earth_radius = 6371e3;		# mean earth radius in m

class Fix { ... }
class Vector { ... }

class Position is export {
	has Latitude  $.lat;
	has Longitude $.long;

	#| new from positionals
	multi method new( $lat, $long ) { samewith( :$lat, :$long ) }

	method Str { qq|($.lat, $.long)| }

	# accessors for radians - φ is latitude, λ is longitude 
	method φ { +$.lat  * π / 180 }
	method λ { +$.long * π / 180 }

	# this.delta(that) => (that - this)
	method Δ( $p ) {
		Position.new( ($p.lat - $.lat), ($p.long - $.long) )
	}

	method haversine-dist(Position $p) {
		my \Δ = $.Δ( $p );	Δ.say;

		my $a = sin(Δ.φ / 2)² + 
				sin(Δ.λ / 2)² * cos($.φ) * cos($p.φ);

		Distance.new( 
			value => 2 * earth_radius * $a.sqrt.asin,
			units => 'm',
		 )
	}
	method forward-azimuth(Position $p) {
		my \Δ = $.Δ( $p );

		my $y = sin(Δ.λ) * cos($p.φ);
		my $x = cos($.φ) * sin($p.φ) -
				sin($.φ) * cos($p.φ) * cos(Δ.λ);
		my \θ = atan2( $y, $x );						#radians

		BearingTrue.new(
			value => ( ( θ * 180 / π ) + 360 ) % 360	#degrees 0-360
		) 
	}

	#| Vector-1to2 = Position1.diff( Position2 );
	method diff(Position $p) {
		Vector.new( θ => $.forward-azimuth($p), d => $.haversine-dist($p) )
	}

	#| Position2 = Position1.move( Vector );
	#| along great circle given distance and initial Bearing
	method move(Vector $v) {
		my \θ  = +$v.θ * π / 180;						#bearing 0 - 2π radians
		my \δ  = +$v.d.in('m') / earth_radius;			#angular dist - d/earth_radius
		my \φ1 = $.φ;									#start latitude
		my \λ1 = $.λ;									#start longitude

		#calculate dest latitude (φ2) & longitude (λ2)
		my \φ2 = asin( sin(φ1) * cos(δ) + cos(φ1) * sin(δ) * cos(θ) );
		my \λ2 = λ1 + atan2( ( sin(θ) * sin(δ) * cos(φ1) ), ( cos(δ) − sin(φ1) * sin(φ2) ) );

		Position.new(
			lat  => Latitude.new(  value => ( φ2 * 180 / π ) ),
			long => Longitude.new( value => ( ( λ2 * 180 / π ) + 540 ) % 360 - 180 ),
		)													    #^^^ normalises to 0-360
	}
}

######### Vector and Velocity ###########

#| Velocity = Vector / Time
class Velocity { ... }

class Vector is export   {
	has BearingTrue $.θ;
	has Length      $.d;

	method Str {
		qq|($.θ, {$.d.in('nmile')})|
	}
	method divide( Time $t ) {
		Velocity.new(
			θ => $.θ,
			s => $.d / $t,
			)
	}
}

class Velocity is export {
	has BearingTrue $.θ;
	has Speed       $.s;

	method Str {
		qq|($.θ, {$.s.in('knots')})|
	}
	method multiply( Time $t ) {
		Vector.new(
			θ => $.θ,
			d => $.s * $t,
			)
	}
}

######### Fixes, Estimates, Transits ###########

class Fix is export {
	has BearingTrue $.direction;
	has Position    $.location;

	method Str {
		"Fix on Bearing {~$.direction} to Position {~$.location}"
	}
}

class Estimate is export {
	has Fix $.fix-A;
	has Fix $.fix-B;

	method position( --> Position ) {
		# create and solve as Angle-Side-Angle (ASA), C is the unknown
		# viz. https://www.mathsisfun.com/algebra/trig-solving-asa-triangles.html

		# 1. get Length & Bearing of c with .diff
		my $diff = $.fix-A.location.diff($.fix-B.location);

		my \c     = $diff.d;
		my \AtoB  = $diff.θ; 				say AtoB if $db;

		# 2. work out triangle angles from Bearings
		my \CtoA = $.fix-A.direction;
		my \CtoB = $.fix-B.direction;

		my \BtoA = AtoB.back;
		my \BtoC = CtoB.back;
		my \AtoC = CtoA.back;

		my \A = AtoB - AtoC; 				say A if $db;
		my \B = BtoC - BtoA;				say B if $db;
		my \C = CtoA - CtoB; 				say C if $db;
		die("Estimate Fix angles do not add to 180°") unless (A+B+C) == 180;

		# 3. use sine law to get Length of a
		my \a = c / sin(C) * sin(A);		say a if $db;

		# 4. get Position of C with A.move
		$.fix-B.location.move: Vector.new( θ => BtoC, d => a )
	}

	method Str {
		"Estimated Position: {~$.position}"
	}
}

class Transit is export {
	has Position $.pos-A;
	has Position $.pos-B;

	method aligned( Position:D $pos-C --> Order ) {
		say my \CtoA = $pos-C.diff($.pos-A).θ;
		say my \CtoB = $pos-C.diff($.pos-B).θ;

		CtoA.value.round(1) cmp CtoB.value.round(1)
	}
}

######### Course and Tide ###########

our %course-info is export = %(
	leeway     => CourseAdj.new( value => 0,  compass => <Sb> ),
	interval   => Time.new( value => 1,  units => 'hours' ),
	boat-speed => Speed.new( value => 5, units => 'knots' ),
);

#| Course embodies the vector identity - CTS = COG + TAV [+leeway]
#| Course To Steer, Course Over Ground, Tide Average Velocity
#| there is an implicit time interval since TAV is tide Speed (knots) + Bearing

class Course is export {
	has BearingTrue $.over-ground;
	has Velocity    $.tidal-flow;

	has CourseAdj   $.leeway     = %course-info<leeway>;
	has Time        $.interval   = %course-info<interval>;
	has Speed       $.boat-speed = %course-info<boat-speed>;

	method Str {
		"Course to steer: " ~ self.to-steer
	}

	#calculate via unit vectors (ie. movement over one interval)
	method over-ground-uv( --> Vector ) {
		Vector.new( θ =>  $.over-ground,
					d => ($.boat-speed * $.interval) );
	}
	method tidal-flow-uv( --> Vector ) {
		$.tidal-flow.multiply( $.interval );
	}

	method to-steer-uv( --> Vector ) {
		#solve as triangle of vectors
		my \A = Position.new( ♓️<51.5072°N>, ♓️<0.1276°W> );   #a random start position
		my \B = A.move( $.over-ground-uv );
		my \C = A.move( $.tidal-flow-uv );

		#B-C is the course to steer unit vector
		C.diff(B)
	}

	method to-steer( --> Bearing ) {
		$.to-steer-uv.θ + $.leeway
	}

	method speed-over-ground( --> Speed ) {
		$.boat-speed * ( $.over-ground-uv.d / $.to-steer-uv.d )
	}
}

######### Buoys and Lights ###########

enum IALA     is export <A B>;         					#EMEA, Americas
enum Pattern  is export <Solid Layers Stripey>;
enum Outline  is export <Can Cone None>;
enum Shape    is export <Ball Cross Down Up>;			#[0] is top of Buoy
enum Colour   is export <Black Green Red White Yellow>; #[0] is top of Buoy

our $IALA is export;
our %iala-colours = %( A => [Red, Green], B => [Green, Red] );  #B => red right returning

#for example, this code Fl(4)15s37m28M should produce this sentence...
#"Flashes 4 times every 15 seconds at height of 37m above MHWS range 28Miles in clear visibility."
grammar LightCode {
	token TOP		{ <kind> ['.']? <group>? <colour>? <extra>? <period> <height>? <visibility>? }

	token kind		{ <veryquick> | <quick> | <flashing> | <fixed> | <occulting> | <isophase> }
	token veryquick { 'VQ' }
	token quick		{  'Q' }
	token flashing	{ 'Fl' }
	token fixed		{ 'F'  }
	token occulting { 'Oc' }
	token isophase	{ 'Iso' }

	token group		{ '(' <digits> ')' }
	token colour	{ <[GRW]>+ }
	token extra		{ '+L Fl.' }
	token period	{ <digits> 's' }
	token height	{ <digits> 'm' }
	token visibility {<digits> 'M' }
	token digits	{ \d* }
}

class LightCode-actions {
	method TOP($/)  {
		my @p;
		@p.push: $/<kind>.made;
		@p.push: $/<group>.made;
		@p.push: $/<colour>.made;
		@p.push: $/<extra>.made;
		@p.push: $/<period>.made;
		@p.push: $/<height>.made;
		@p.push: $/<visibility>.made;

		$/.make: @p.grep({.so}).join(' ')
	}
	method kind($/) {
		given $/ {
			when 'VQ'  { $/.make: 'Flashes very quickly' }
			when  'Q'  { $/.make: 'Flashes quickly' }
			when 'Fl'  { $/.make: 'Flashes' }
			when 'F'   { $/.make: 'Fixed' }
			when 'Oc'  { $/.make: 'Occulting' }
			when 'Iso' { $/.make: 'Isophase' }
		}
	}
	method group($/) {
		$/.make: ~$/<digits> ~ ' times'
	}
	method colour($/) {
		my %palette = %( G => 'green', R => 'red', W => 'white' );
		$/.make: %palette{~$/}
	}
	method extra($/) {
		$/.make: 'plus one long'
	}
	method period($/) {
		$/.make: 'every ' ~ ~$/<digits> ~ ' seconds'
	}
	method height($/) {
		$/.make: 'at height of ' ~ ~$/<digits> ~ 'm above MHWS'
	}
	method visibility($/) {
		$/.make: 'range ' ~ ~$/<digits> ~ 'nmiles in clear visibility'
	}
}

role Light is export {
	has Str    $.light-defn = '';

	method light( --> Str ) {
		LightCode.parse($.light-defn, actions => LightCode-actions.new).made
	}
}

class Buoy does Light is export {
	has Position $.position is required;

	has Pattern  $.pattern = Layers;
	has Outline  $.outline = None;
	has Colour   @.colours = [];
	has Shape    @.shapes  = [];

	method Str( --> Str ) {
		my $name = self.^name;
		$name ~~ s/'Physics::Navigation::'//;
		qq:to/END/;
		$name Buoy at {self.position}
		Colours:{@.colours.join(',')}. Shapes:{@.shapes.join(',')}. Outline:{$.outline}. Pattern:{$.pattern}.
		{self.light}
		END
	}
}

class Lateral is Buoy is export {
	has Pattern  $.pattern = Solid;

	multi method colours( Int $i --> Array ) {
		[%iala-colours{$IALA}[$i],]
	}
	method light-defn( --> Str ) {
		my $ci = $.colours[0].substr(0,1).uc;
		"Fl.{$ci}5s"
	}
}
class PortLateral is Lateral is export {
	has Outline  $.outline = Can;
	multi method colours { samewith( 0 ) }
}
class StarboardLateral is Lateral is export {
	has Outline  $.outline = Cone;
	multi method colours { samewith( 1 ) }
}

class NorthCardinal is Buoy is export {
	has Colour   @.colours = ( Black, Yellow, );
	has Shape    @.shapes  = ( Up, Up, );
	has Str      $.light-defn = 'Q';
}
class EastCardinal is Buoy is export {
	has Colour   @.colours = ( Black, Yellow, Black, );
	has Shape    @.shapes  = ( Up, Down, );
	has Str      $.light-defn = 'Q(3)10s';
}
class SouthCardinal is Buoy is export {
	has Colour   @.colours = ( Yellow, Black, );
	has Shape    @.shapes  = ( Down, Down, );
	has Str      $.light-defn = 'Q(6)+L Fl.15s';
}
class WestCardinal is Buoy is export {
	has Colour   @.colours = ( Yellow, Black, Yellow, );
	has Shape    @.shapes  = ( Down, Up, );
	has Str      $.light-defn = 'Q(9)15s';
}

class Danger is Buoy is export {
	has Colour   @.colours = ( Black, Red, Black, Red, );
	has Shape    @.shapes  = ( Ball, Ball, );
}

class Fairway is Buoy is export {
	has Pattern  $.pattern = Stripey;
	has Colour   @.colours = ( Red, White, );
	has Shape    @.shapes  = ( Cross, );
}






#EOF
