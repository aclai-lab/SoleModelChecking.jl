# Use postfix notation to generate formula-trees

# Given a certain token, there are 3 possible scenarios
# (which are regrouped in _tree function to keep code clean)
#
# 1. It is a proposition, hence a leaf in the formula tree
#    -> push a new Node(token) in the nodestack;
#
# 2. It is an unary operator
#    -> make a new Node(token), then pop the top node from the nodestack
#    -> link the new node and the one popped
#    -> push the new node in the nodestack;
#
# 3. It is a binary operator
#    -> similarly to 2. , but pop and link two nodes from the nodestack
#    -> then push the new Node(token) in the nodestack;
#
# The only remaining node in `nodestack` is the root of the formula tree.

function tree(expression::Vector{Any})
    nodestack = []

    for tok in expression
        _tree(tok, nodestack)
    end

    return Formula(nodestack[1])
end

function _tree(tok, nodestack)
    newnode = Node(tok)

    if tok in alphabet
        newnode.formula = tok
        push!(nodestack, newnode)

    elseif Symbol(tok) in unary_operator
        children = pop!(nodestack)

        _parent!(children, newnode)
        _rightchild!(newnode, children)

        newnode.formula = tok * children.formula
        push!(nodestack, newnode)

    elseif Symbol(tok) in binary_operator
        rightchild = pop!(nodestack)
        leftchild = pop!(nodestack)

        _parent!(rightchild, newnode)
        _parent!(leftchild, newnode)

        _rightchild!(newnode, rightchild)
        _leftchild!(newnode, leftchild)

        newnode.formula = "( " * leftchild.formula * " " * tok * " " * rightchild.formula * " )"
        push!(nodestack, newnode)

    else
        throw(error("Unknown token"))
    end
end

function postorder(node::Node)
    if isdefined(node, :leftchild)
        postorder(node.leftchild)
    end

    if isdefined(node, :rightchild)
        postorder(node.rightchild)
    end

    println(node.formula)
end

function inorder(node::Node)
    print("(")
    if isdefined(node, :leftchild)
        inorder(node.leftchild)
    end

    print(node.token)

    if isdefined(node, :rightchild)
        inorder(node.rightchild)
    end
    print(")")
end

# Test

expression = "(¬(a∧b))∨(□c∧◊d)"
println("Starting formula is $expression")
expression = shunting_yard(expression)
println("Starting formula tokens are: $expression" )

formula = tree(expression)

println("Sottoformule da usare poi nella funzione check di cui parlavamo in laboratorio:")
inorder(formula.tree)
println("")

"""
println("Root left child formula: ")
@show prova.tree.leftchild.formula
println("Root right child formula: ")
@show prova.tree.rightchild.formula
println("Complete built formula")
@show prova.tree.formula
"""
