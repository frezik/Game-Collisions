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

use utf8;
use v5.14;
use warnings;
use List::Util ();
use Scalar::Util ();

use constant _X => 0;
use constant _Y => 1;
use constant _LENGTH => 2;
use constant _HEIGHT => 3;
use constant _MAX_X => 4;
use constant _MAX_Y => 5;
use constant _PARENT_NODE => 6;
use constant _LEFT_NODE => 7;
use constant _RIGHT_NODE => 8;


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
        undef, # parent node
        undef, # left node
        undef, # right node
    ];

    bless $self => $class;
}


sub x { $_[0]->[_X] }
sub y { $_[0]->[_Y] }
sub length { $_[0]->[_LENGTH] }
sub height { $_[0]->[_HEIGHT] }
sub left_node { $_[0]->[_LEFT_NODE] }
sub right_node { $_[0]->[_RIGHT_NODE] }
sub parent { $_[0]->[_PARENT_NODE] }


sub set_left_node
{
    my ($self, $node) = @_;
    return $self->_set_node( $node, _LEFT_NODE );
}

sub set_right_node
{
    my ($self, $node) = @_;
    return $self->_set_node( $node, _RIGHT_NODE );
}

sub set_parent
{
    my ($self, $parent) = @_;
    my $current_parent = $self->[_PARENT_NODE];
    $self->[_PARENT_NODE] = $parent;
    return $current_parent;
}

sub resize_all_parents
{
    my ($self) = @_;

    my @nodes_to_resize = ($self);
    while( @nodes_to_resize ) {
        my $next_node = shift @nodes_to_resize;
        push @nodes_to_resize, $next_node->parent
            if defined $next_node->parent;
        $next_node->_resize_to_fit_children;
    }

    return;
}

sub does_collide
{
    my ($self, $other_object) = @_;
    return 0 if $self == $other_object; # Does not collide with itself
    my ($minx1, $miny1, $length1, $height1, $maxx1, $maxy1) = @$self;
    my ($minx2, $miny2, $length2, $height2, $maxx2, $maxy2) = @$other_object;

    return $maxx1 >= $minx2
        && $minx1 <= $maxx2 
        && $maxy1 >= $miny1 
        && $miny1 <= $maxy2;
}

sub find_best_sibling_node
{
    my ($self, $new_node) = @_;

    my @nodes_to_check = ($self);
    while( @nodes_to_check ) {
        my $check_node = shift @nodes_to_check;
        my $left_node = $check_node->[_LEFT_NODE];
        my $right_node = $check_node->[_RIGHT_NODE];
        return $check_node
            if (! defined $left_node) || (! defined $right_node);

        my (undef, undef, $left_length, $left_height)
            = $self->_calculate_bounding_box_for_nodes( $left_node, $new_node );
        my (undef, undef, $right_length, $right_height)
            = $self->_calculate_bounding_box_for_nodes( $right_node, $new_node);

        my $left_surface = $left_length * $left_height;
        my $right_surface = $right_length * $right_height;
        push @nodes_to_check,
            ($left_surface > $right_surface) ? $right_node : $left_node;
    }

    # How did we get here? It should have descended the tree until it 
    # came to the leaf and returned that. Just in case, return ourselves.
    return $self;
}

sub is_branch_node
{
    my ($self) = @_;
    return (defined $self->[_LEFT_NODE]) || (defined $self->[_RIGHT_NODE]);
}

sub dump_tree
{
    my ($self, $spacing) = @_;
    $spacing //= '';

    my $draw_chars = $self->is_branch_node
        ? '├┐'
        : '│├';
    my $str = "$spacing├┤ " . join( ', ',
        "$self",
        $self->x,
        $self->y,
        $self->length,
        $self->height,
    );
    $str .= "\n";
    $str .= $self->left_node->dump_tree( $spacing . '┼' )
        if defined $self->left_node;
    $str .= $self->right_node->dump_tree( $spacing . '┼' )
        if defined $self->right_node;

    return $str;
}


sub _set_node
{
    my ($self, $node, $index) = @_;
    Scalar::Util::unweaken( $self->[$index] )
        if defined $self->[$index];
    $self->[$index] = $node;
    Scalar::Util::weaken( $self->[$index] );
    my $former_parent = $node->set_parent( $self );
    return $former_parent;
}

sub _resize_to_fit_children
{
    my ($self) = @_;
    my ($x, $y, $length, $height) = $self->_calculate_bounding_box_for_nodes(
        $self->[_LEFT_NODE],
        $self->[_RIGHT_NODE],
    );

    $self->[_X] = $x;
    $self->[_Y] = $y;
    $self->[_LENGTH] = $length;
    $self->[_HEIGHT] = $height;
    $self->[_MAX_X] = $x + $length;
    $self->[_MAX_Y] = $y + $height;

    return;
}

sub _calculate_bounding_box_for_nodes
{
    my ($self, $node1, $node2) = @_;
    my $min_x = List::Util::min( $node1->x, $node2->x );
    my $min_y = List::Util::min( $node1->y, $node2->y );
    my $max_x = List::Util::max(
        $node1->length + $node1->x,
        $node2->length + $node2->x,
    );
    my $max_y = List::Util::max(
        $node1->height + $node1->y,
        $node2->height + $node2->y,
    );

    my $length = $max_x - $min_x;
    my $height = $max_y - $min_y;
    return ($min_x, $min_y, $length, $height);
}


1;
__END__

