#!/usr/bin/env raku
#t/01-sanity.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
#plan 21;

use Physics::Navigation;
use Physics::Measure;


$Physics::Navigation::variation = Variation.new( value => 7, compass => <W> );

my \ϕ1 = ♓️<45°0′N>;
is ϕ1, <45°0′N>,                        'lat1';

my \λ1 = ♓️<045°0′E>;
is λ1, <045°0′E>,                       'long1';

my \ϕ2 = ♓️<43°30′30″S>;
is ϕ2, <43°30.5′S>,                     'lat2';

my \λ2 = ♓️<022°0′W>;
is λ2, <022°0′W>,                       'long2';

$Physics::Measure::round-val = 10;

my $start  = Position.new( ϕ1, λ1 );
is $start, '(45°0′N, 045°0′E)',         'start';

my $finish = Position.new( ϕ2, λ2 );
is $finish, '(43°30′S, 022°0′W)',         'finish';

is $start.haversine-dist($finish).in('km'), '11860km',  'haversine';
is $start.forward-azimuth($finish),         '224°SW (T)', 'azimuth';

my $vector  = $start.diff($finish);
is $vector, '(224°SW (T), 6400nmile)',     'vector';

my $finish2 = $start.move($vector);
is $finish2, '(43°30′S, 022°0′W)',          'finish2';

my $dur     = ♓️'3 weeks';
#dd $dur;
ok +$dur == 3,                              'duration';
#is ~$dur, '3week',                           'duration';

my $vel     = $vector.divide: $dur;
is $vel, '(224°SW (T), 10knot)',           'velocity';

my $vector2 = $vel.multiply: $dur;
is $vector2, '(224°SW (T), 6400nmile)',    'vector2';

my $vn = ♓️<7°0′Vw>;
is $vn, <07°0′Vw>,                          'Variation';

my $pos-A = Position.new( ♓️<51.5072°N>, ♓️<0.1276°W> );
my $pos-B = Position.new( ♓️<51.5072°N>, ♓️<0.1110°W> );
my $pos-C = Position.new( ♓️<51.5072°N>, ♓️<0.1100°W> );

my $fix-A = Fix.new( direction => ♓️<112°T>, location  => $pos-A );
my $fix-B = Fix.new( direction => ♓️<25°T>,  location  => $pos-B );
is $fix-B, 'Fix on Bearing 025°NNE (T) to Position (51°30′N, 000°10′W)',    'Fix';

$Physics::Measure::round-val = 0.1;

my $ep = Estimate.new( :$fix-A, :$fix-B );
is $ep, 'Estimated Position: (51°30.2′N, 000°6.8′W)',                       'Estimate';

my $tr = Transit.new( :$pos-A, :$pos-B );
is $tr.aligned( $pos-C ), 'Same',                                           'Transit';

%course-info<boat-speed> =  ♓️'6.5 knots';
%course-info<leeway> = ♓️<1°Pt>;
my $tidal-flow = Velocity.new( θ => ♓️<112°T>, s => ♓️'2.2 knots' );
is $tidal-flow, '(112°ESE (T), 2.2knot)',                                   'tidal-flow';

my Course $course .= new( over-ground => ♓️<22°T>, :$tidal-flow );
is $course, 'Course to steer: 002°N (T)',                                   'Course';

is $course.speed-over-ground.in('knots'), '6.2knot',                        'speed-over-ground';

$IALA = A;
my $plm = PortLateral.new( position => $pos-A );
is $plm.light-defn, 'Fl.R5s',                                               'light-defn';
ok $plm.light-svg.pattern eq <#f00 #000 #000 #000 #000 #000>,               'light-svg';

done-testing;

