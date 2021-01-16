unit module Physics::Navigation:ver<0.0.3>:auth<Steve Roe (p6steve@furnival.net)>;
use Physics::Measure;

## Provides extensions to Physics::Measure and Physics::Unit for nautical navigation...
##  - NavAngle classes for Latitude, Longitude, Bearing and Course
##  - NavAngle math (addition, subtraction)
##  - replace ♎️ with ♓️ (pisces) as declaration shorthand
##  - application of Variation, Deviation to Bearings
#TODOs...
##  - Course and Leeway
##  - override Speed (Log) to have default in knots where Distance is nmiles
##  - implement nmiles <=> Latitude arcmin identity
##  - Fixes (transits, bearings)
##  - Position class (Fixes) DR and EP
##  - Tracks (vectors) with addition - COG, CTS, COW, Tide, Leeway, Fix vectors
##  - Tide ladders
##  - Buoys (grammar)
##  - Lights (grammar) 
##  - gps

my $db = 0;                 #debug

our $round-to = 0.01;		#default rounding of output methods.. Str etc. e.g. 0.01
#NB. Bearings round to 1 degree

class BearingTrue { ...}
class BearingMag  { ...}
class CourseAdj { ... }
class Variation { ... }
class Deviation { ... }

our $variation = Variation.new( value => 0, compass => <Vw> );
our $deviation = Deviation.new( value => 0, compass => <Dw> );

class NavAngle is Angle {
	has $.units where *.name eq '°';

	multi method new( Str:D $s ) {						say "NA new from Str" if $db; 
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
		$nao.compass( $compass );
		return $nao
    }

    multi method assign( Str:D $r ) {					say "NA assign from Str" if $db; 
        ($.value, $.compass) = NavAngle.defn-extract( $r );   
    }   
	multi method assign( NavAngle:D $r ) {				say "NA assign from NavAngle" if $db;
        $.value = $r.value;
    }

    method raku {
        q|\qq[{self.^name}].new( value => \qq[{$.value}], compass => \qq[{$.compass}] )|;
    }    

    method Str ( :$rev, :$fmt ) {
        my $neg = $.compass eq $rev ?? 1 !! 0;			#negate value if reverse pole
        my ( $deg, $min ) = self.dms( :no-secs, :negate($neg) );    
        $deg = sprintf( $fmt, $deg );
        $min = $round-to ?? $min.round($round-to) !! $min;
        qq|$deg°$min′$.compass|
    }

    #class method baby Grammar for initial extraction of definition from Str (value/unit/error)
    method defn-extract( NavAngle:U: Str:D $s ) {

        #handle degrees-minutes-seconds <°> is U+00B0 <′> is U+2032 <″> is U+2033
		#NB different to Measure.rakumod, here arcmin ′? is optional as want eg. <45°N> to parse 

        unless $s ~~ /(\d*)\°(\d*)\′?(\d*)\″?\w*(<[NSEWMT]>)/ { return 0 };
		my $deg where 0 <= * < 360 = $0 % 360;
		my $min where 0 <= * <  60 = $1 // 0;
		my $sec where 0 <= * <  60 = $2 // 0;
		my $nominal = ( ($deg * 3600) + ($min * 60) + $sec ) / 3600;
		my $compass = ~$3;

		say "NA extracting «$s»: value is $deg°$min′$sec″, compass is $compass" if $db;
		return($nominal, $compass)
	}
}

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
		self.value = -90 if self.value < -90;			#clamp to 90°
        return self 
    }    
}

class Longitude is NavAngle is export {
	has Real  $.value is rw where -180 < * <= 180; 

	multi method compass {								#get compass
		$.value >= 0 ?? <W> !! <E>
	}
	multi method compass( Str $_ ) {					#set compass
		$.value = -$.value if $_ eq <E> 
	}

    method Str {
        nextwith( :rev<E>, :fmt<%03d> );
	}

    multi method add( Longitude $l ) {
        self.value += $l.value;
		self.value -= 360 if self.value > 180;			#overflow from +180 to -180
        return self 
    }    
    multi method subtract( Longitude $l ) {
        self.value -= $l.value;
		self.value += 360 if self.value <= -180;		#underflow from -180 to +180
        return self 
    }    
}

#| Bearing embodies the identity 'M = T + Vw', so...
#| Magnetic = True + Variation-West [+ Deviation-West]

sub err-msg { die "Cannot combine Bearings of different Types!" }

class Bearing is NavAngle {
	has Real  $.value is rw where 0 <= * <= 360; 

    method Str( :$fmt )  {
		nextsame if $fmt;								#pass through to NA.Str
		my $deg = $.value.round(1);						#always rounds to whole degs
		$deg = sprintf( "%03d", $deg );
		qq|$deg° ($.compass)|
	}

    multi method add( Bearing $r ) {
        self.value += $r.value % 360;
        return self 
    }
    multi method subtract( Bearing $r ) {
        self.value -= $r.value % 360;
        return self 
    }
}

class BearingTrue is Bearing is export {
	multi method compass { <T> }						#get compass
	multi method compass( Str $_ ) {					#set compass
		die "BearingTrue compass must be <T>" unless $_ eq <T>
	}

	method M {
		my $nv = $.value + ( +$variation + +$deviation );
		BearingMag.new( value => $nv, compass => <M> )
	}

	#| can't combine with Mag 
	multi method add( BearingMag ) { err-msg }
	multi method subtract( BearingMag ) { err-msg }
}

class BearingMag is Bearing is export {
	multi method compass { <M> }						#get compass
	multi method compass( Str $_ ) {					#set compass
		die "BearingMag compass must be <M>" unless $_ eq <M>
	}

	method T {
		my $nv = $.value - ( +$variation + +$deviation );
		BearingTrue.new( value => $nv, compass => <T> )
	}

	#| can't combine with True 
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

#| Course embodies the vector identity - CTS = COG + TAV + CAB [+Leeway]
#| Course To Steer, Course Over Ground, Tide Average Vector?, Course Adj Bearing
class Course is export {
	has Bearing $!b-true where *.compass eq <T>;


}

####### Replace ♎️ with ♓️ #########

sub do-decl( $left is rw, $right ) {
    #declaration with default
    if $left ~~ NavAngle {
        $left .=new( $right );
    } else {
        $left = NavAngle.new( $right );
    }
}

#declaration with default
multi infix:<♓️> ( Any:U $left is rw, NavAngle:D $right ) is equiv( &infix:<=> ) is export {
    do-decl( $left, $right );
}
multi infix:<♓️> ( Any:U $left is rw, Str:D $right ) is equiv( &infix:<=> ) is export {
    do-decl( $left, $right );
}

#assignment
multi infix:<♓️> ( NavAngle:D $left, NavAngle:D $right ) is equiv( &infix:<=> ) is export {
    $left.assign( $right );
}
multi infix:<♓️> ( NavAngle:D $left, Str:D $right ) is equiv( &infix:<=> ) is export {
    $left.assign( $right );
}

