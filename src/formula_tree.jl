# Use postfix notation to generate formula-trees

#=
Given a certain token, there are 3 possible scenarios
(which are regrouped in _tree function to keep code clean)

1. It is a proposition, hence a leaf in the formula tree
    -> push a new Node(token) in the nodestack;

2. It is an unary operator
    -> make a new Node(token), then pop the top node from the nodestack
    -> link the new node and the one popped
    -> push the new node in the nodestack;

3. It is a binary operator
    -> similarly to 2. , but pop and link two nodes from the nodestack
    -> then push the new Node(token) in the nodestack;

The only remaining node in `nodestack` is the root of the formula tree.
=#

function tree(expression::Vector{Union{String, AbstractOperator}})
    nodestack = Node[]

    for tok in expression
        _tree(tok, nodestack)
    end

    SoleLogics.size(nodestack[1])
    return Formula(nodestack[1])
end

function _tree(tok, nodestack)
    newnode = Node(tok)

    if tok in alphabet
        newnode.formula = string(tok)
        push!(nodestack, newnode)

    elseif tok in unary_operators.ops
        children = pop!(nodestack)

        parent!(children, newnode)
        rightchild!(newnode, children)

        newnode.formula = string(tok, children.formula)
        push!(nodestack, newnode)

    elseif tok in binary_operators.ops
        rightchild = pop!(nodestack)
        leftchild = pop!(nodestack)

        parent!(rightchild, newnode)
        parent!(leftchild, newnode)

        rightchild!(newnode, rightchild)
        leftchild!(newnode, leftchild)

        newnode.formula = string("(", leftchild.formula, tok, rightchild.formula, ")")
        push!(nodestack, newnode)

    else
        throw(error("Unknown token"))
    end
end

function subformulas(node::Node)
    phi = Node[]
    _subformulas(node, phi)
    sort!(phi, by = n -> n.size)
    return phi
end

function _subformulas(node::Node, phi::Vector{Node})
    if isdefined(node, :leftchild)
        _subformulas(node.leftchild, phi)
    end

    if isdefined(node, :rightchild)
        _subformulas(node.rightchild, phi)
    end

    push!(phi, node)
end
