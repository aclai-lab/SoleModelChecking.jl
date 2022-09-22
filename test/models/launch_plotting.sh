exec_n_letters=(2 4 8 16)
exec_max_formula_height=(1 2 4 8)
n_models=10
n_worlds=10
for n_letters in "${exec_n_letters[@]}"; do
for fheight in "${exec_max_formula_height[@]}"; do
    julia --project=. test/plotter.jl --directory=test/csv/${n_models}_${n_letters}_${fheight} --title="#Models=${n_models}, #Worlds=${n_worlds}, #Letters=${n_letters}, MaxHeight=${fheight}" --memolabel="no 0 1 2 3 4 8" --prlabel="0.2 0.5 0.8"
done
done

##############################################################

exec_n_letters=(2 4 8 16)
exec_max_formula_height=(1 2 4)
n_models=50
n_worlds=20
for n_letters in "${exec_n_letters[@]}"; do
for fheight in "${exec_max_formula_height[@]}"; do
    julia --project=. test/plotter.jl --directory=test/csv/${n_models}_${n_letters}_${fheight} --title="#Models=${n_models}, #Worlds=${n_worlds}, #Letters=${n_letters}, MaxHeight=${fheight}" --memolabel="no 0 1 2 3 4 8" --prlabel="0.2 0.5 0.8"
done
done

exec_n_letters=(2 4 8 16)
exec_max_formula_height=(8)
n_models=50
n_worlds=20
for n_letters in "${exec_n_letters[@]}"; do
for fheight in "${exec_max_formula_height[@]}"; do
    julia --project=. test/plotter.jl --directory=test/csv/${n_models}_${n_letters}_${fheight} --title="#Models=${n_models}, #Worlds=${n_worlds}, #Letters=${n_letters}, MaxHeight=${fheight}" --memolabel="no 0 1 2 3 4 8" --prlabel="0.4 0.6 0.8"
done
done