unit module Physics::Navigation:ver<0.0.3>:auth<Steve Roe (p6steve@furnival.net)>;
use Physics::Unit;
use Physics::Measure;

## Provides extensions to Physics::Measure and Physics::Unit for nautical navigation...
##  - NavAngle classes for Latitude, Longitude, Bearing and Course
##  - NavAngle math (addition, subtraction)
##  - replace ♎️ with ♓️ (pisces) as declaration shorthand
#TODOs...
##  - application of Variation, Deviation to Bearings
##  - Course class and Leeway
##  - override Speed (Log) to have default in knots where Distance is nmiles
##  - implement nmiles <=> Latitude arcmin identity
##  - Fixes (transits, bearings)
##  - Position class (Fixes) DR and EP
##  - Tracks (vectors) with addition - COG, CTS, COW, Tide, Leeway, Fix vectors
##  - Tide ladders
##  - Buoys (grammar)
##  - Lights (grammar) 

my $db = 0;                 #debug

our $round-to;				#optional rounding of output methods.. Str etc. e.g. 0.01

class CompassAdjustment { ... }

our $variation = CompassAdjustment.new( value => 0, compass => <W> );
our $deviation = CompassAdjustment.new( value => 0, compass => <W> );

class NavAngle is Angle {
	has Unit  $.units is rw where *.name eq '°';

	#overriding some Measure methods to handle NavAngle special cases 
    	multi method new( Str:D $s ) {						say "NA new from Str" if $db; 
        my ($nominal, $compass) = NavAngle.defn-extract( $s );
		my $type;
		given $compass {
			when <N S>.any   { $type = 'Latitude' }
			when <E W>.any   { $type = 'Longitude' }
			when <M T S>.any { $type = 'Bearing' }
			default			 { nextsame }
		}
        ::($type).new( value => $nominal, compass => $compass );
    }    
    multi method new( :$value!, :$units, :$compass ) {	say "NA new from attrs" if $db; 
		warn "NavAngle units are forced to degrees" if $units.defined;

		my $nao = self.bless( value => $value, units => GetUnit('°') );
		$nao.compass( $compass );
		return $nao
    }

    method raku {
        return qq:to/END/;
        NavAngle.new( value => $.value, units => $.units, compass => $.compass );  
        END  
    }    

    multi method assign( Str:D $r ) {					say "NA assign from Str" if $db; 
        my ($nominal, $compass) = NavAngle.defn-extract( $r );   
        $.value = $nominal;
		$.compass = $compass;
    }   
	multi method assign( NavAngle:D $r ) {				say "NA assign from NavAngle" if $db;
        $.value = $r.value;
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
		given $.value {
			when * >= 0 { return <N> }
			when * < 0  { return <S> }
		}
	}
	multi method compass( Str $compass ) {				#set compass
		given $compass {
			when <N>   { }		#no-op
			when <S>   { $.value = -$.value }
			default    { die "Latitude must be <N S>.any" }
		}
	}
    method Str {
		my $com = self.compass;
		my $neg = $com eq <N> ?? 0 !! 1;
		my ( $deg, $min ) = self.dms( :no-secs, :negate($neg) ); 
		$deg = sprintf( "%02d", $deg );
		$min = $round-to ?? $min.round($round-to) !! $min;
		qq{$deg°$min′$com}
	}
}

class Longitude is NavAngle is export {
	has Real  $.value is rw where -180 < * <= 180; 

	multi method compass {								#get compass
		given $.value {
			when * >= 0 { return <W> }
			when * < 0  { return <E> }
		}
	}
	multi method compass( Str $compass ) {				#set compass
		given $compass {
			when <W>   { }		#no-op
			when <E>   { $.value = -$.value }
			default    { die "Longitude must be <W E>.any" }
		}
	}
    method Str {
		my $com = self.compass;
		my $neg = $com eq <W> ?? 0 !! 1;
		my ( $deg, $min ) = self.dms( :no-secs, :negate($neg) ); 
		$deg = sprintf( "%03d", $deg );
		$min = $round-to ?? $min.round($round-to) !! $min;
		qq{$deg°$min′$com}
	}
}

#| Bearing embodies the identity 'M = T + Vw', so...
#| Magnetic = True + Variation-West [+ Deviation-West]
class Bearing is NavAngle is export {
	has Real  $.value is rw where 0 <= * <= 360; 
	has Str   $!compass where <M T>.any;

	multi method compass {								#get compass
		return $!compass;
	}
	multi method compass( Str $compass ) {				#set compass
		$!compass = $compass;
	}
    method Str {
		my $deg = $round-to ?? $.value.round($round-to) !! $.value;
		$deg = sprintf( "%03d", $deg );
		qq{$deg° ($.compass)}
	}

	method M {
		if self.compass eq <M> {
			return( self ) 
		} else {
			return( self + ( $variation + $deviation ) )
		}
	}
	method T {
		if self.compass eq <T> {
			return( self ) 
		} else {
#iamerejh
dd self;
dd $variation;
dd $deviation;
			my $res = self;
			$res.compass: <T>;
			return( $res - ( $variation + $deviation ) )
		}
	}

   sub check-same( $l, $r ) {
		if $r ~~ CompassAdjustment { 
			return 
		}
        if ! $l.compass eq $r.compass {
            die "Cannot combine Bearings of different Types!"
        }    
    }  
    method add( $r is rw ) {
        my $l = self;
        check-same( $l, $r );
        $l.value += $r.value;
		##$l.compass( $r.compass );
        return $l
    }    
    method subtract( $r is rw ) {
        my $l = self;
        check-same( $l, $r );
        $l.value -= $r.value; 
		##$l.compass( $r.compass );
        return $l
    }
}

class CompassAdjustment is Bearing is export {
	has Real  $.value is rw where -180 <= * <= 180; 

	multi method compass {								#get compass
		given $.value {
			when * >= 0 { return <W> }
			when * < 0  { return <E> }
		}
	}
	multi method compass( Str $compass ) {				#set compass
		given $compass {
			when <W>   { }		#no-op
			when <E>   { $.value = -$.value }
			default    { die "Compass-Adjustment must be <W E>.any" }
		}
	}
    method Str {
		my $com = self.compass;
		my $neg = $com eq <W> ?? 0 !! 1;
		my ( $deg, $min ) = self.dms( :no-secs, :negate($neg) ); 
		$deg = sprintf( "%02d", $deg );
		$min = $round-to ?? $min.round($round-to) !! $min;
		qq{$deg°$min′$com}
	}
}

class CourseAdjustment is Bearing is export {
	has Real  $.value is rw where -180 <= * <= 180; 

	multi method compass {								#get compass
		given $.value {
			when * >= 0 { return <P> }
			when * < 0  { return <S> }
		}
	}
	multi method compass( Str $compass ) {				#set compass
		given $compass {
			when <P>   { }		#no-op
			when <S>   { $.value = -$.value }
			default    { die "Course-Adjustment must be <P S>.any" }
		}
	}
    method Str {
		my $com = self.compass;
		my $neg = $com eq <P> ?? 0 !! 1;
		my ( $deg, $min ) = self.dms( :no-secs, :negate($neg) ); 
		$deg = sprintf( "%02d", $deg );
		$min = $round-to ?? $min.round($round-to) !! $min;
		qq{$deg°$min′$com}
	}
}

#| Course embodies the vector identity - CTS = COG + TAV + CAB [+Leeway]
#| Course To Steer, Course Over Ground, Tide Average Vector?, Course Adjustment Bearing
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

