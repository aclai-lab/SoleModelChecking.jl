#!/bin/bash
#
exec_repetitions=(10)
exec_n_models=(10)
exec_n_worlds_per_model=(20)
exec_n_letters=(2)
exec_n_formulas=(1000)
exec_max_formula_height=(3)
exec_n_threads=(1 2)

for repetitions in "${exec_repetitions[@]}"; do
for n_models in "${exec_n_models[@]}"; do
for n_worlds_per_model in "${exec_n_worlds_per_model[@]}"; do
for n_letters in "${exec_n_letters[@]}"; do
for n_formulas in "${exec_n_formulas[@]}"; do
for max_formula_height in "${exec_max_formula_height[@]}"; do
for n_threads in "${exec_n_threads[@]}"; do
	julia -t$n_threads --project=. test/experiments.jl $n_models $n_worlds_per_model $n_letters $max_formula_height $n_formulas $repetitions
done
done
done
done
done
done
done
