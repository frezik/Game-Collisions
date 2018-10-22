#!perl
# Copyright (c) 2018  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use v5.14;
use warnings;
use Time::HiRes qw( gettimeofday tv_interval );
use Game::Collisions;

use constant FPS => 60;
use constant ITERATION_COUNT => FPS / 3;
use constant OBJECT_COUNT => 1000;


my $collide = Game::Collisions->new;
$collide->make_aabb({
    x => int rand(100),
    y => int rand(100),
    length => int rand(10),
    height => int rand(10),
}) for 1 .. OBJECT_COUNT;

my $start = [gettimeofday()];
$collide->get_collisions for 1 .. ITERATION_COUNT;
my $elapsed = tv_interval( $start );

my $checks_per_sec = (ITERATION_COUNT * OBJECT_COUNT) / $elapsed;
my $checks_per_frame = $checks_per_sec / FPS;
say "Ran " . OBJECT_COUNT . " objects " . ITERATION_COUNT . " times"
    . " in $elapsed sec";
say "$checks_per_sec objects/sec";
say "$checks_per_frame per frame @" . FPS . " fps";
