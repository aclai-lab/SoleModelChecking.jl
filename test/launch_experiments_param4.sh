#!/bin/bash
#
exec_repetitions=(100)
exec_pruning_factor=(0.2 0.5 0.7)
exec_n_models=(50)
exec_n_worlds_per_model=(20)
exec_n_letters=(16)
exec_max_formula_height=(4)
exec_n_formulas=(4000)
exec_n_threads=(1)

for repetitions in "${exec_repetitions[@]}"; do
for n_formulas in "${exec_n_formulas[@]}"; do
for max_formula_height in "${exec_max_formula_height[@]}"; do
for pruning_factor in "${exec_pruning_factor[@]}"; do
for n_letters in "${exec_n_letters[@]}"; do
for n_models in "${exec_n_models[@]}"; do
for n_worlds_per_model in "${exec_n_worlds_per_model[@]}"; do
for n_threads in "${exec_n_threads[@]}"; do
        echo MODELS: $n_models NLETTERS: $n_letters MAXHEIGHT: $max_formula_height NFORMULAS: $n_formulas PRFACTOR: $pruning_factor REPS: $repetitions
        julia -t$n_threads --project=. test/experiments.jl --nmodels $n_models --nworlds $n_worlds_per_model --nletters $n_letters --fmaxheight $max_formula_height --nformulas $n_formulas --prfactor $pruning_factor --nreps $repetitions
done
done
done
done
done
done
done
done