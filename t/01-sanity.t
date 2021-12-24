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

is $start.haversine-dist($finish).in('km'), '10080km',  'haversine';
is $start.forward-azimuth($finish),         '196°SSW (T)', 'azimuth';

done-testing;

#
#my Length $c .= new: $b;
#ok $c.value == 1e1,         '$c.value';
#is $c.units,  'm',          '$c.units';