using DataStructures

# Temporary dummy alphabet
alphabet = string.(collect('a':'z'))
isproposition(s::AbstractString) = s in alphabet

#################################
#      Utilities to manage      #
#     operators and parsing     #
#################################

# Could be an ImmutableDict instead
const operators_precedence = Dict{Union{AbstractOperator,Symbol}, Int}(
    NEGATION => 30,
    DIAMOND => 20,
    BOX => 20,
    CONJUNCTION => 10,
    DISJUNCTION => 10,
    Symbol("(") => 0
)

# Given a symbol check if it's associated with an operator.
# TODO: add flexibility by allowing the user to define a custom set of operators
const operators = Dict{Symbol,AbstractOperator}()
for op in [unary_operators.ops..., binary_operators.ops...]
    pair = (reltype(op), op)
    setindex!(operators, pair[2], pair[1])
end

#=
Shunting yard algorithm explanation.

Goal:
translate an infix expression to postfix notation. (also called Reverse Polish Notation)
e.g. "□c∧◊d" becomes "c□d◊∧"
This is useful to generate a syntax/formula tree later.

Data structures:
* `postfix`: vector of tokens (String or AbstractOperator) in RPN; this is returned
* `ops_stack`: stack of tokens (String, eventually converted to AbstractOperator when pushed to `postfix`)

Algorithm:
given a certain token `tok`, 1 of 4 possible scenarios may occur:
(regrouped in _shunting_yard function to keep code clean)

1. `tok` is a valid propositional letter
    -> push "p" in `postfix` ;

2. `tok` is an opening bracket
-> push "(" in `operators` ;

3. `tok` is a closing bracket
    -> pop op ∈ `operators` and push it in `postfix` until
    the corresponding opening bracket is found ;

4. `tok` is an operator
    -> pop op ∈ `operators` and push it in `postfix` if it has higher precedence
    than the current token.
    After that, push the current token in `operators` ;
=#

"""
    shunting_yard(expression::String)
Return `expression` in postfix notation.
"""
function shunting_yard(expression::String)
    postfix = Union{String, AbstractOperator}[]
    ops_stack = Stack{String}()
    infix = string.(split(filter(x -> !isspace(x), expression), ""))

    for tok in infix
        _shunting_yard(postfix, ops_stack, tok)
    end

    # Last push and check for malformed input
    while !isempty(ops_stack)
        op = pop!(ops_stack)
        @assert op != "(" "Mismatching brackets"
        push!(postfix, operators[Symbol(op)])
    end

    return postfix
end

function _shunting_yard(postfix, ops_stack, tok)
    # 1
    if isproposition(tok)
        push!(postfix, tok)
    # 2
    elseif tok == "("
        push!(ops_stack, tok)
    # 3
    elseif tok == ")"
        while !isempty(ops_stack) && (op = pop!(ops_stack)) != "("
            push!(postfix, operators[Symbol(op)])
        end
    # 4
    else
        while !isempty(ops_stack)
            op = pop!(ops_stack)
            if op != "(" && operators_precedence[operators[Symbol(op)]] > operators_precedence[operators[Symbol(tok)]]
                push!(postfix, operators[Symbol(op)])
            else
                # pop is reverted, `tok` is about to be pushed in the right spot
                push!(ops_stack, op)
                break
            end
        end
        push!(ops_stack, tok)
    end
end
