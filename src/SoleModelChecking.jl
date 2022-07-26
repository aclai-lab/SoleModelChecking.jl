module SoleModelChecking

using Reexport

export shunting_yard
export tree, inorder, subformulas
export KripkeFrame, KripkeModel, check
export isnumber, isproposition

@reexport using SoleLogics

include("parser.jl")
include("formula_tree.jl")
include("checker.jl")

end

#=
Nota temporanea, considerazioni sparse sul codice. Puoi non leggere

Sarebbe bello mettere un controllo sulla proprietà height di un nodo dell'albero
tipo un assert per cui height sia 1 + (altezza massima dei figli), ogni volta che si
modifica l'height (da cambiare in sole logics).

Da guardare una funzione che ri-assegna tutte le altezze all'albero (con memoizzazione,
o comunque assegnamenti durante la ricorsione) e che calcoli anche la profondità modale.
Aggiungere ad ogni nodo proprietà "profondità modale" (vedi Todo di eduard in Logic).

Bisogna spostare l'inizio di parser in SoleLogics e fare delle scelte definitive
su alfabeto e operatori, poi cambiare tutto il resto del codice di conseguenza
=#
