# Use postfix notation to generate formula-trees

#=
Formula (syntax) tree generation

Given a certain token `tok`, 1 of 3 possible scenarios may occur:
(regrouped in _tree function to keep code clean)

1. `tok` is a propositional letter, hence a leaf in the formula tree
    -> push a new Node(token) in the nodestack;

2. `tok` is an unary operator
    -> wrap `tok` in a Node struct.
    Link the new node with `nodestack` top node and push it back into the stack.

3. It is a binary operator
    -> analogue to step 2., but 2 nodes are popped and linked to the new node.

At the end, the only remaining node in `nodestack` is the root of the formula (syntax) tree.
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
    # 1
    if tok in alphabet
        newnode.formula = string(tok)
        push!(nodestack, newnode)
    # 2
    elseif tok in unary_operators.ops
        children = pop!(nodestack)
        parent!(children, newnode)
        rightchild!(newnode, children)
        newnode.formula = string(tok, children.formula)
        push!(nodestack, newnode)
    # 3
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

# Collect each node in a tree, then sort them by size.
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
    push!(phi, node)
    if isdefined(node, :rightchild)
        _subformulas(node.rightchild, phi)
    end
end
