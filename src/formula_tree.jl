# Use postfix notation to generate formula-trees

#=
Formula (syntax) tree generation

Given a certain token `tok`, 1 of 3 possible scenarios may occur:
(regrouped in _tree function to keep code clean)

1. `tok` is a propositional letter, hence a leaf in the formula tree
    -> push a new Node(tok) in the nodestack;

2. `tok` is an unary operator
    -> make a new Node(tok), then link it with the node popped from `nodestack` top.
    Then push the new node into `nodestack`.

3. It is a binary operator
    -> analogue to step 2., but 2 nodes are popped and linked to the new node.

At the end, the only remaining node in `nodestack` is the root of the formula (syntax) tree.
=#

function tree(expression::Vector{Union{String, AbstractOperator}})
    nodestack = Stack{Node}()

    for tok in expression
        _tree(tok, nodestack)
    end

    SoleLogics.size!(first(nodestack))
    return Formula(first(nodestack))
end

function _tree(tok, nodestack)
    newnode = Node(tok)
    # 1
    if tok in alphabet
        newnode.formula = string(tok)
        push!(nodestack, newnode)
    # 2
    elseif typeof(tok) <: AbstractUnaryOperator
        children = pop!(nodestack)

        parent!(children, newnode)
        rightchild!(newnode, children)
        newnode.formula = string(tok, children.formula)

        push!(nodestack, newnode)
    # 3
    elseif typeof(tok) <: AbstractBinaryOperator
        right_child = pop!(nodestack)
        left_child = pop!(nodestack)

        parent!(right_child, newnode)
        parent!(left_child, newnode)
        rightchild!(newnode, right_child)
        leftchild!(newnode, left_child)
        newnode.formula = string("(", left_child.formula, tok, right_child.formula, ")")

        push!(nodestack, newnode)
    else
        throw(error("Unknown token"))
    end
end

# Collect each node in a tree, then sort them by size.
function subformulas(root::Node; sorted=true)
    nodes = Node[]
    _subformulas(root, nodes)
    if sorted
        sort!(nodes, by = n -> n.size)
    end
    return nodes
end

function _subformulas(node::Node, nodes::Vector{Node})
    if isdefined(node, :leftchild)
        _subformulas(node.leftchild, nodes)
    end

    push!(nodes, node)

    if isdefined(node, :rightchild)
        _subformulas(node.rightchild, nodes)
    end
end
