# Shunting Yard implementation to parse modal logic expressions

# Dummy alphabet
alphabet = string.(collect('a':'z'))

isproposition(s::AbstractString) = s in alphabet
isvalid(s::Symbol) = haskey(operator, s)

#=
shunting_yard(s::String)
Given a certain token, there are 4 possible scenarios
(which are regrouped in _shunting_yard function to keep code clean)

1. It is a valid propositional letter
    -> push "p" in `postfix` ;

2. It is an opening bracket
-> push "(" in `operators` ;

3. It is a closing bracket
    -> pop op ∈ `operators` and push it in `postfix` until
    the corresponding opening bracket is found ;

4. It is an operator
    -> pop op ∈ `operators` and push it in `postfix` if it has higher precedence
    than the current token.
    After that, push the current token in `operators` ;

TODO: add "<" and "[" case for existential and universal HSRELATIONS
=#

function shunting_yard(s::String)
    postfix = Union{String, AbstractOperator}[]
    operators = []
    infix = string.(split(filter(x -> !isspace(x), s), ""))

    for tok in infix
        _shunting_yard(postfix, operators, tok)
    end

    # Last push and check for malformed input
    while !isempty(operators)
        op = pop!(operators)
        @assert op != "(" "Mismatching brackets"
        push!(postfix, operator[Symbol(op)])
    end

    return postfix
end

function _shunting_yard(postfix, operators, tok)
    # 1
    if isproposition(tok)
        push!(postfix, tok)
    # 2
    elseif tok == "("
        push!(operators, tok)
    # 3
    elseif tok == ")"
        while !isempty(operators) && (op = pop!(operators)) != "("
            push!(postfix, operator[Symbol(op)])
        end
    # 4
    else
        while !isempty(operators)
            op = pop!(operators)
            if op != "(" && operators_precedence[operator[Symbol(op)]] > operators_precedence[operator[Symbol(tok)]]
                push!(postfix, operator[Symbol(op)])
            else
                # pop is reverted, `tok` is about to be pushed in the right spot
                push!(operators, op)
                break
            end
        end
        push!(operators, tok)
    end
end
