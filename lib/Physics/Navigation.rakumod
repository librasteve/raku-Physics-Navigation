unit module Physics::Navigation:ver<0.0.3>:auth<Steve Roe (p6steve@furnival.net)>;
use Physics::Unit;
use Physics::Measure;

my $db = 0;                 #debug

our $round-to;				#optional round for output methods.. Str etc.

#use dms Angle method for custom formats (icl round-to 
#override Speed to have default in knots where dist isnmiles

## Provides extensions to Physics::Measure and Physics::Unit...
## Latitude  isa Angle
## Longitude isa Angle
## Bearing   isa Angle

class NavAngle is Angle {

	#overriding some Measure methods to handle NavAngle special cases 
    multi method new( Str:D $s ) {						say "NA new from Str" if $db; 
        my ($v, $c) = NavAngle.defn-extract( $s );
		my $type;
		given $c {
			when <N S>.any { $type = 'Latitude' }
			when <E W>.any { $type = 'Longitude' }
			when <M T>.any { $type = 'Bearing' }
		}
        ::($type).new( value => $v, compass => $c );
    }    
    multi method new( :$value, :$units, :$compass ) {	say "NA new from attrs" if $db; 
		warn "NavAngle units are always set to degrees" if $units.defined;
        self.bless( value => $value, units => GetUnit('°'), compass => $compass )
	}

    multi method assign( Str:D $r ) {					say "NA assign from Str" if $db; 
        my ($v, $c) = NavAngle.defn-extract( $r );   
        $.value = $v;
		$.compass = $c;
    }   
	multi method assign( NavAngle:D $r ) {				say "NA assign from NavAngle" if $db;
        $.value = $r.value;
        $.compass = $r.compass;
    }

    #class method baby Grammar for initial extraction of definition from Str (value/unit/error)
    method defn-extract( NavAngle:U: Str:D $s ) {
        #handle degrees-minutes-seconds <°> is U+00B0 <′> is U+2032 <″> is U+2033
		#NB different to Measure.rakumod, here arcmin ′? is optional as want eg. <45°N> to parse 

        if $s ~~ /(\d*)\°(\d*)\′?(\d*)\″?\w*(<[NSEWMT]>)/ {
            my $deg where 0 <= * < 360 = $0 % 360;
            my $min where 0 <= * <  60 = $1 // 0;
            my $sec where 0 <= * <  60 = $2 // 0;
            my $v = ( ($deg * 3600) + ($min * 60) + $sec ) / 3600;
			my $c = ~$3;

            say "NA extracting «$s»: value is $deg°$min′$sec″, compass is $c" if $db;
            return($v, $c)
        }
    }

    method add( $r is rw ) {
        my $l .= new( self );
say $l; #iamerejh revert to P::M and change value to abs
		if $l.compass eq $r.compass {
			$l.value += $r.value;
		}
        return $l
    }
    method subtract( $r is rw ) {
        my $l = self;
        $l.value -= $r.value;
        return $l
    }
    method negate {
        $.value *= -1;
        return self
    }

}

class Latitude is NavAngle is export {
	has Real  $.value is rw where 0 <= * <= 90; 
	has Unit  $.units is rw where *.name eq '°';
	has Str   $.compass is rw where <N S>.any;

    method Str {
		my ( $deg, $min ) = self.dms( :no-secs ); 
		$deg = sprintf( "%02d", $deg );
		$min = $round-to ?? $min.round($round-to) !! $min;
		qq{$deg°$min′ $.compass}
	}
}

class Longitude is NavAngle is export {
	has Real  $.value is rw where 0 <= * <= 180; 
	has Unit  $.units is rw where *.name eq '°';
	has Str   $.compass is rw where <E W>.any;

    method Str {
		my ( $deg, $min ) = self.dms( :no-secs ); 
		$deg = sprintf( "%03d", $deg );
		$min = $round-to ?? $min.round($round-to) !! $min;
		qq{$deg°$min′ $.compass}
	}
}

class Bearing is NavAngle is export {
	has Real  $.value is rw where 0 <= * <= 180; 
	has Unit  $.units is rw where *.name eq '°';
	has Str   $.compass is rw where <M T>.any;

    method Str {
		my ( $deg, $min ) = self.dms( :no-secs ); 
		$deg = sprintf( "%03d", $deg );
		qq{$deg° ($.compass)}
	}
}

#supporting subs copied verbatim from Measure.rakumod
#`[[
sub infix-prep( $left, $right ) {
    #clone Measure child object (e.g. Distance) as container for result
    #coerce other arg. to Measure child with new unless already isa
    #don't forget to swap sides back e.g.for intransigent operations

    my ( $result, $argument );
    if $left ~~ Measure && $right ~~ Measure {
        $result   = $left.clone;
        $argument = $right;
    } elsif $left ~~ Measure {
        $result   = $left.clone;
        $argument = $left.clone.new: $right;
    } elsif $right ~~ Measure {
        $result   = $right.clone.new: $left;
        $argument = $right.clone;
    }
    return( $result, $argument );
}
#]]
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

#add / subtract
multi infix:<♓️+> ( NavAngle:D $left, NavAngle:D $right ) is export {
    return $left.add( $right );
}
multi infix:<♓️-> ( NavAngle:D $left, NavAngle:D $right ) is export {
    return $left.subtract( $right );
}
