using DataStructures

# Temporary dummy alphabet
alphabet = string.(collect('a':'z'))
isproposition(s::AbstractString) = s in alphabet

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
# TODO: add more flexibility by allowing the user to define a custom set of operators.
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
This preprocessing is useful to simplify formula (syntax) trees generations.

Data structures involved:
* `postfix`: vector of tokens (String or AbstractOperator) in RPN; this is returned
* `ops_stack`: stack of tokens (String, eventually converted to AbstractOperator when pushed to `postfix`)

Algorithm:
given a certain token `tok`, 1 of 4 possible scenarios may occur:
(regrouped in _shunting_yard function to keep code clean)

1. `tok` is a valid propositional letter
    -> push "p" in `postfix`

2. `tok` is an opening bracket
    -> push "(" in `operators`

3. `tok` is a closing bracket
    -> pop from `ops_stack` and interpret the obtained string as an AbstractOperator,
    then push it into `postfix`.
    Repeat the process until an opening bracket is found.

4. `tok` has to be an operator
    -> pop `op` from `ops_stack` and interpret the obtained string as an AbstractOperator
    (named `op_op`, similarly obtain `tok_op`).
    Continue pushing `op_op` into `postfix` if it has higher precedence than `tok_op`,
    otherwise undo this cycle (`op` string is pushed back to `ops_stack`) and push
    `tok_op` in `postfix`.
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

    # Survivor tokens are pushed to postfix
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
        while !isempty(ops_stack) && (op_str = pop!(ops_stack)) != "("
            push!(postfix, operators[Symbol(op_str)])
        end
    # 4
    else
        while !isempty(ops_stack)
            if first(ops_stack) == "("
                break
            end

            op_str = pop!(ops_stack)            # "◊"
            op_op = operators[Symbol(op_str)]   # operators[:◊] -> SoleLogics.DIAMOND
            tok_op = operators[Symbol(tok)]

            if operators_precedence[op_op] > operators_precedence[tok_op]
                push!(postfix, op_op)
            else
                # Last pop is reverted since `tok` has to be pushed in `ops_stack` now.
                push!(ops_stack, op_str)
                break
            end
        end
        push!(ops_stack, tok)
    end
end
