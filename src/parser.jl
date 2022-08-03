# Temporary dummy alphabet
alphabet = string.(collect('a':'z'))

# Could be an ImmutableDict instead
const operators_precedence = Dict{Union{AbstractOperator,Symbol}, Int}(
    :¬ => 30,
    Symbol("⟨◊⟩") => 20,
    Symbol("[□]") => 20,
    Symbol("[L]") => 20,
    Symbol("⟨L⟩") => 20,
    :∧ => 10,
    :∨ => 10,
)
function precedence(op::Symbol)
    return operators_precedence[op]
end
function precedence(op::Union{AbstractOperator, String})
    return operators_precedence[Symbol(op)]
end

# The following operators pool will change based on the selected logic
operators_pool = [NEGATION, DIAMOND, BOX, CONJUNCTION, DISJUNCTION]
append!(operators_pool, (@modaloperators HSRELATIONS 1).ops)

# Given a symbol check if it's associated with an operator.
const operators = Dict{Symbol,AbstractOperator}()
for op in operators_pool
    operators[Symbol(op)] = op
end

# A simple lexer capable of distinguish operators in a string
function tokenizer(expression::String)
    tokens = Union{AbstractOperator, String}[]

    # Classical operators such as ∧ are represented by one character
    # but "expression" is splitted (after whitespaces removal) in order to
    # recognize multicharacter-operators such as [L] or ⟨My_123_cus7om_456_0p3r4!or⟩.
    expression = filter(x -> !isspace(x), expression)
    slices = string.(split(expression, r"((?<=\])|(?=\[))|((?<=⟩)|(?=⟨))"))

    # Multicharacter-operators are recognized,
    # while the rest of the expression is expanded.
    for slice in slices
        if slice[1] == '[' || slice[1] == '⟨'
            push!(tokens, operators[Symbol(slice)])
        else
            append!(tokens, string.(split(slice, "")))
        end
    end

    # Other operators are recognized
    for i in eachindex(tokens)
        if tokens[i] isa String && haskey(operators, Symbol(tokens[i]))
            tokens[i] = operators[Symbol(tokens[i])]
        end
    end

    return tokens
end

#=
Shunting yard algorithm explanation.

Goal:
translate an infix expression to postfix notation. (also called Reverse Polish Notation)
e.g. "□c∧◊d" becomes "c□d◊∧"
This preprocessing is useful to simplify formula (syntax) trees generations.

Data structures involved:
* `postfix`: vector of tokens (String or AbstractOperator) in RPN; this is returned
* `opstack`: stack of tokens (AbstractOperators except for the "(" string)

Algorithm:
given a certain token `tok`, 1 of 4 possible scenarios may occur:
(regrouped in _shunting_yard function to keep code clean)

1. `tok` is a valid propositional letter
    -> push "p" in `postfix`

2. `tok` is an opening bracket
    -> push "(" in `operators`

3. `tok` is a closing bracket
    -> pop from `opstack`.
    If an operator is popped, then push it into `postfix` and repeat.
    Else, if an opening bracket it's found then process the next token.
    This algorithm step it's the reason why "(" are placed in `opstack`
    and `opstack` content type is Union{AbstractOperator, String}.

4. `tok` has to be an operator
    -> pop `op` from `opstack` and push it into `postfix` if it has an higher precedence
    than `tok` and repeat.
    When the condition is no more satisfied, then it means we have found the correct
    spot where to place `tok` in `opstack`.
=#

"""
    shunting_yard(expression::String)
Return `expression` in postfix notation.
"""
function shunting_yard(expression::String)
    postfix = Union{AbstractOperator, String}[]
    opstack = Stack{Union{AbstractOperator, String}}() # This contains operators or "("

    tokens = tokenizer(expression)
    for tok in tokens
        _shunting_yard(postfix, opstack, tok)
    end

    # Remaining tokens are pushed to postfix
    while !isempty(opstack)
        op = pop!(opstack)
        @assert op != "(" "Mismatching brackets"
        push!(postfix, op)
    end

    return postfix
end

function _shunting_yard(postfix, opstack, tok)
    # 1
    if tok in alphabet
        push!(postfix, tok)
    # 2
    elseif tok == "("
        push!(opstack, tok)
    # 3
    elseif tok == ")"
        while !isempty(opstack) && (op = pop!(opstack)) != "("
            push!(postfix, op)
        end
    # 4 (tok is certainly an operator)
    else
        while !isempty(opstack)
            if first(opstack) == "("
                break
            end

            op = pop!(opstack)  # This is not an "(", so it must be an operator

            if precedence(op) > precedence(tok)
                push!(postfix, op)
            else
                # Last pop is reverted since `tok` has to be pushed in `opstack` now.
                push!(opstack, op)
                break
            end
        end
        push!(opstack, tok)
    end
end

# Regexp to isolate content inside []/⟨⟩ brackets pair
# r"((?<=\])|(?=\[))|((?<=⟩)|(?=⟨))"
# Using this in a split translates to:
# "split here if my left character is a ], or if my right character is a [,
# otherwise split here if my left character is ⟩ or if my right character is a ⟨
# e.g split("[B](s)∧⟨A⟩((¬(s))∧(p))", r"((?<=\])|(?=\[))|((?<=⟩)|(?=⟨))")

# ◊(¬(s)∧(r))
# [LRU](¬(s)∧(r))
