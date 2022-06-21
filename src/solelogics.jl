# I took a piece of SoleLogics and copy-pasted here.
# I need this script to write SoleModelChecking but at the moment there are no exports
# defined in SoleLogics.

mutable struct Node{T}
    token::T            # token (e.g., Proposition)
    parent::Node        # parent node
    leftchild::Node     # left child node
    rightchild::Node    # right child node
    formula::String     # human-readable string of the formula

    Node{T}(token::T) where T = new{T}(token)
end

Node(token::T) where T = Node{T}(token)

_token(ν::Node)      = ν.token
_parent(ν::Node)     = ν.parent
_leftchild(ν::Node)  = ν.leftchild
_rightchild(ν::Node) = ν.rightchild
_formula(ν::Node)    = ν.formula

_parent!(ν::Node, ν′::Node)     = ν.parent = ν′
_leftchild!(ν::Node, ν′::Node)  = ν.leftchild = ν′
_rightchild!(ν::Node, ν′::Node) = ν.rightchild = ν′
_formula!(ν::Node, ν′::Node)    = ν.formula = ν′

function _size(ν::Node)
    leftchild_size = isdefined(ν, :leftchild) ? _size(_leftchild(ν)) : 0
    rightchild_size = isdefined(ν, :rightchild) ? _size(_rightchild(ν)) : 0
    return 1 + leftchild_size + rightchild_size
end

function _isleaf(ν::Node)
    return !(isdefined(ν, :leftchild) || isdefined(ν, :rightchild)) ? true : false
end

function _height(ν::Node)
    return _isleaf(ν) ? 1 : 1 + max(
        (isdefined(ν, :leftchild) ? _height(_leftchild(ν)) : 0),
        (isdefined(ν, :rightchild) ? _height(_rightchild(ν)) : 0))
end

# TODO: add modaldepth() function (hint: use traits such as ismodal() function)

# not working properly
function _printnode(io::IO, ν::Node)
    if isdefined(ν, :leftchild)
        print(io, "$(_printnode(io, _leftchild(ν)))")
    end
    print(io, _token(ν))
    if isdefined(ν, :rightchild)
        print(io, "$(_printnode(io, _rightchild(ν)))")
    end
end

show(io::IO, ν::Node) = _printnode(io, ν)

struct Formula
    tree::Node # syntax tree
end
