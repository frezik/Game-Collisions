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
package Game::Collisions;
use v5.14;
use warnings;

use Game::Collisions::AABB;

# ABSTRACT: Collision detection in 2D space


sub new
{
    my ($class) = @_;
    my $self = {
        aabbs => [],
    };
    bless $self => $class;
}


sub make_aabb
{
    my ($self, $args) = @_;
    my $aabb = Game::Collisions::AABB->new( $args );
    push @{ $self->{aabbs} }, $aabb;
    return $aabb;
}

sub get_collisions
{
    my ($self) = @_;
    my @collisions;
    my @aabbs = @{ $self->{aabbs} };

    foreach my $i (0 .. $#aabbs) {
        my $aabb = $aabbs[$i];

        foreach my $other_aabb (@aabbs[$i+1 .. $#aabbs]) {
            push @collisions, [ $aabb, $other_aabb ]
                if $aabb->does_collide( $other_aabb );
        }
    }

    return @collisions;
}


1;
__END__


=head1 NAME

  Game::Collisions - Collision detection

=cut
