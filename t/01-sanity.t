#!/usr/bin/env raku
#t/01-sanity.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
#plan 21;

use Physics::Navigation;
use Physics::Measure;

$Physics::Measure::round-val = 10;
$Physics::Navigation::variation =
        Variation.new( value => 7, compass => <W> );

my \ϕ1 = ♓️<45°0′N>;        say "ϕ1 is {ϕ1}";
my \λ1 = ♓️<045°0′E>;       say "λ1 is {λ1}";
my \ϕ2 = ♓️<43°30′30″S>;    say "ϕ2 is {ϕ2}";
my \λ2 = ♓️<22°W>;          say "λ2 is {λ2}";

my $start  = Position.new( ϕ1, λ1 );        say "$start";
my $finish = Position.new( ϕ2, λ2 );        say "$finish";

done-testing;
