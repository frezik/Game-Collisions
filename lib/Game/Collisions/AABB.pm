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
package Game::Collisions::AABB;
use v5.14;
use warnings;

use constant _X => 0;
use constant _Y => 1;
use constant _LENGTH => 2;
use constant _HEIGHT => 3;
use constant _MAX_X => 4;
use constant _MAX_Y => 5;


sub new
{
    my ($class, $args) = @_;
    my $self = [
        $args->{x},
        $args->{y},
        $args->{length},
        $args->{height},
        $args->{x} + $args->{length},
        $args->{y} + $args->{height},
    ];

    bless $self => $class;
}


sub does_collide
{
    my ($self, $other_object) = @_;
    my ($minx1, $miny1, $length1, $height1, $maxx1, $maxy1) = @$self;
    my ($minx2, $miny2, $length2, $height2, $maxx2, $maxy2) = @$other_object;

    return $maxx1 >= $minx2
        && $minx1 <= $maxx2 
        && $maxy1 >= $miny1 
        && $miny1 <= $maxy2;
}


1;
__END__

