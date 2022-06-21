# Use postfix notation to generate the formula tree
# This code is UGLY and should be refactored.
# Please don't read, this is just my stream of consciousness

# SoleLogics - formulas.jl
# Copy-pasted for testing purposes
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
# End of SoleLogics - formulas.jl

include("parser.jl")

formula = "( ¬ ( a ∧ b ) ) ∨ ( ( □ c ) ∧ ◇ d )"
formula = shunting_yard(formula)
println( "Starting formula tokens are: $formula" )

function make_tree(formula::Vector{Any})
    nodestack = []

    for tok in formula
        if tok in alphabet
            newnode = Node(tok)
            newnode.formula = tok
            push!(nodestack, newnode)

        elseif Symbol(tok) in unary_operator
            topnode = pop!(nodestack)
            newnode = Node(tok)
            _parent!(topnode, newnode)
            _leftchild!(newnode, topnode)
            newnode.formula = tok * topnode.formula
            push!(nodestack, newnode)

        elseif Symbol(tok) in binary_operator
            rightnode = pop!(nodestack)
            leftnode = pop!(nodestack)
            newnode = Node(tok)
            _parent!(rightnode, newnode)
            _parent!(leftnode, newnode)
            _rightchild!(newnode, rightnode)
            _leftchild!(newnode, leftnode)
            newnode.formula = "( " * leftnode.formula * " " * tok * " " * rightnode.formula * " )"
            push!(nodestack, newnode)

        else
            @assert 1==0 "Unknown token"
        end
    end

    ans = Formula(nodestack[1])
    return ans
end

prova = make_tree(formula)

function postorder(node::Node)
    if isdefined(node, :leftchild)
        postorder(node.leftchild)
    end
    if isdefined(node, :rightchild)
        postorder(node.rightchild)
    end
    println(node.formula)
end

println("Sottoformule da usare poi nella funzione check di cui parlavamo in laboratorio:")
postorder(prova.tree)

"""
println("Root left child formula: ")
@show prova.tree.leftchild.formula
println("Root right child formula: ")
@show prova.tree.rightchild.formula
println("Complete built formula")
@show prova.tree.formula
"""
