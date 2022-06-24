# Shunting Yard implementation to parse modal logic expressions
# This is a coarse standalone prototype

# Other things to do:
# Get operator and Node definition from SoleLogics
# Establish the operators precedence
# Take a look to "operators associativity" (?)
# Implement AST ("Formula tree") generation in another file
# Implement a system to parse this "(□p v □□◇p)" instead of "( □ p v □ □ ◇ p)"
# Write tests

import Base

# Just for prototyping
alphabet = string.(collect('a':'z'))

# To establish the status of a token
isnumber(s::AbstractString) = tryparse(Float64, s) isa Number
isproposition(s::AbstractString) = s in alphabet

# To retrieve info about an operator
unary_operator = [:◇, :□, :¬]       # currently useless, please ignore
binary_operator = [:∧, :∨]  # currently useless, please ignore

const precedence = Dict{Symbol, Int}(
    :¬ => 30,
    :◇ => 20,
    :□ => 20,
    :∧ => 10,
    :∨ => 10,
    Symbol("(") => 0
)

Base.isunaryoperator(s::Symbol) = s in unary_operator               # currently useless, please ignore
Base.isbinaryoperator(s::Symbol) = s in binary_operator             # currently useless, please ignore
isvalid(s::Symbol) = s in unary_operator || s in binary_operator
Base.operator_precedence(s::Symbol) = return precedence[s]

# shunting_yard(s::String)
# Given a certain token, there are 4 possible scenarios
#
# 1. It is a valid propositional letter
#    -> push "p" in `postfix` ;
#
# 2. It is an opening bracket
#    -> push "(" in `operators` ;
#
# 3. It is a closing bracket
#    -> pop op ∈ `operators` and push it in `postfix` until
#       the corresponding opening bracket is found ;
#
# 4. It is an operator
#    -> pop op ∈ `operators` and push it in `postfix` if it has higher precedence
#       than the current token.
#       After that, push the current token in `operators` ;

function shunting_yard(s::String)
    postfix = []
    operators = []
    infix = split(s)

    for tok in infix
        if isproposition(tok)
            push!(postfix, tok)

        elseif tok == "("
            push!(operators, tok)

        elseif tok == ")"
            while !isempty(operators) && (op = pop!(operators)) != "("
               push!(postfix, op)
            end

        # Token is an operator (see 4.)
        else
            while !isempty(operators)
                op = pop!(operators)

                if Base.operator_precedence(Symbol(op)) > Base.operator_precedence(Symbol(tok))
                    push!(postfix, op)
                else
                    # Why is the operator pushed back in the stack?
                    # If clause failed, meaning that `tok` must be
                    # exactly above `op` in the operator stack
                    push!(operators, op)
                    break
                end
            end

            push!(operators, tok)
        end

    end

    # Last push and check for malformed input
    while !isempty(operators)
        op = pop!(operators)
        @assert op != "(" "Mismatching brackets"
        push!(postfix, op)
    end

    return postfix
end

# Testing

# formula = "( ¬ ( a ∧ b ) ) ∨ ( □ c ∧ ◇ d )"
# println( shunting_yard(formula) )

# formula = "( □ c ) ∧ ◇ ( ( □ p ) ∧ ( ◇ q ) )"
# println( shunting_yard(formula) )
