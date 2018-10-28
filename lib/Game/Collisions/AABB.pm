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

sub does_fully_enclose
{
    my ($self, $other_object) = @_;
    return 0 if $self == $other_object; # Does not collide with itself
    my ($minx1, $miny1, $length1, $height1, $maxx1, $maxy1) = @$self;
    my ($minx2, $miny2, $length2, $height2, $maxx2, $maxy2) = @$other_object;

    return $maxx1 >= $maxx2
        && $minx1 <= $minx2 
        && $maxy1 >= $maxy1 
        && $miny1 <= $miny2;
}



sub find_best_sibling_node
{
    my ($self, $new_node) = @_;

    my @nodes_to_check = ($self);
    while( @nodes_to_check ) {
        my $check_node = shift @nodes_to_check;
        return $check_node if ! $check_node->is_branch_node;

        my $left_node = $check_node->left_node;
        my $right_node = $check_node->right_node;

        if(! defined $left_node ) {
            if(! $right_node->does_fully_enclose( $new_node ) ) {
                # No left node, and we don't enclose the right, so 
                # the right should be our sibling
                return $right_node;
            }
            elsif( $right_node->is_branch_node ) {
                # Since right node is a branch node, and we enclose it,
                # descend further without doing anything else.
                push @nodes_to_check, $right_node;
                next;
            }
            else {
                # Right node is a leaf and we enclose it, so it's our 
                # sibling now
                return $right_node;
            }
        }
        elsif(! defined $right_node ) {
            if(! $left_node->does_fully_enclose( $new_node ) ) {
                # No right node, and we don't enclose the left, so 
                # the left should be our sibling
                return $left_node;
            }
            elsif( $left_node->is_branch_node ) {
                # Since left node is a branch node, and we enclose it,
                # descend further without doing anything else
                push @nodes_to_check, $left_node;
                next;
            }
            else {
                # Left node is a leaf and we enclose it, so it's our 
                # sibling now
                return $left_node;
            }
        }

        # If we have both left and right nodes, then we have to decide which 
        # direction to go
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

sub move
{
    my ($self, $args) = @_;
    my $add_x = $args->{add_x} // 0;
    my $add_y = $args->{add_y} // 0;

    $self->[_X] = $self->[_X] + $add_x;
    $self->[_Y] = $self->[_Y] + $add_y;
    $self->[_MAX_X] = $self->[_MAX_X] + $add_x;
    $self->[_MAX_Y] = $self->[_MAX_Y] + $add_y;

    $self->_reinsert;
    return;
}

sub insert_new_aabb
{
    my ($self, $new_node) = @_;
    my $best_sibling = $self->find_best_sibling_node( $new_node );

    my $min_x = List::Util::min( $new_node->x, $best_sibling->x );
    my $min_y = List::Util::min( $new_node->y, $best_sibling->y );

    my $new_branch = Game::Collisions::AABB->new({
        x => $min_x,
        y => $min_y,
        length => 1,
        height => 1,
    });

    my $old_parent = $best_sibling->parent;
    $new_branch->set_left_node( $new_node );
    $new_branch->set_right_node( $best_sibling );

    my $new_root;
    if(! defined $old_parent ) {
        # Happens when the root is going to be the new sibling. In this case, 
        # create a new node for the root.
        $new_root = $new_branch;
    }
    else {
        my $set_method = $best_sibling == $old_parent->left_node
            ? "set_left_node"
            : "set_right_node";
        $old_parent->$set_method( $new_branch );
    }

    $new_branch->resize_all_parents;
    return $new_root;
}

sub suggested_rotation
{
    my ($self) = @_;
    my $left_depth = $self->left_node->_depth(0);
    my $right_depth = $self->right_node->_depth(0);
    my $difference = abs( $left_depth - $right_depth );

    return $difference <= 1 ? 0 :
        ($left_depth > $right_depth) ? -1 :
        1;
}


sub _depth
{
    my ($self, $depth_so_far) = @_;
    # TODO reimplement in iterative way
    return $depth_so_far + 1 if ! $self->is_branch_node;
    my $left_depth = $self->left_node->_depth( $depth_so_far + 1 );
    my $right_depth = $self->right_node->_depth( $depth_so_far + 1 );

    return $left_depth > $right_depth
        ? $left_depth
        : $right_depth;
}

sub _reinsert
{
    my ($self) = @_;
    my $current_parent = $self->parent;
    $self->_detach_from_parent;

    while( defined( my $possible_root = $current_parent->parent ) ) {
        $current_parent = $possible_root;
    }

    # $current_parent will now be the root of the tree
    $current_parent->insert_new_aabb( $self );
    return;
}

sub _detach_from_parent
{
    my ($self) = @_;
    my $current_parent = $self->parent;
    return unless defined $current_parent;

    my $current_grandparent = $current_parent->parent;
    my $is_left = ($current_parent->left_node() == $self);
    if(! defined $current_grandparent ) {
        # Parent must have been root. Just detach ourselves.
        if( $is_left ) {
            $current_parent->set_left_node( undef );
        }
        else {
            $current_parent->set_right_node( undef );
        }
    }
    else {
        # Our parent is removed, and our sibling takes its place in the 
        # grandparent
        my $sibling = $is_left
            ? $current_parent->right_node
            : $current_parent->left_node;
        my $is_parent_left
            = ($current_grandparent->left_node == $current_parent);

        if( $is_parent_left ) {
            $current_grandparent->set_left_node( $sibling );
        }
        else {
            $current_grandparent->set_right_node( $sibling );
        }
    }
    
    $self->set_parent( undef );
    return;
}



sub _set_node
{
    my ($self, $node, $index) = @_;
    Scalar::Util::unweaken( $self->[$index] )
        if defined $self->[$index];
    $self->[$index] = $node;
    Scalar::Util::weaken( $self->[$index] );
    my $former_parent = defined $node
        ? $node->set_parent( $self )
        : undef;
    return $former_parent;
}

sub _resize_to_fit_children
{
    my ($self) = @_;
    return if ! $self->is_branch_node;
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
    return @$node1[_X, _Y, _LENGTH, _HEIGHT] if ! defined $node2;
    return @$node2[_X, _Y, _LENGTH, _HEIGHT] if ! defined $node1;

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

