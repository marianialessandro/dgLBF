% :-['../glbf.pl'].


:- set_prolog_flag(stack_limit, 128 000 000 000).
:- set_prolog_flag(last_call_optimisation, true).

sim_glbf(Out, Alloc, Infs, Time) :-
    statistics(inferences, I1),
        statistics(cputime, T1),
            wrap(Out, Alloc), 
        statistics(cputime, T2),
    statistics(inferences, I2), 

	Infs is I2 - I1 - 5,
	Time is T2 - T1.

wrap(Out, Alloc) :- glbf(Out, Alloc).
wrap([], []) :- \+ glbf(_, _).

sim_greenglbf(Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost, Infs, Time) :-
    statistics(inferences, I1),
        statistics(cputime, T1),
            wrap_greenglbf(Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost),
        statistics(cputime, T2),
    statistics(inferences, I2),
    Infs is I2 - I1 - 5,
    Time  is T2 - T1.

wrap_greenglbf(Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost) :-
    glbfCC(Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost).
wrap_greenglbf([], [], []) :-
    \+ glbfCC(_, _, _).

loadInfrastructure(Path) :-
    open(Path, read, Str),
    (retractall(node(_,_)), retractall(link(_,_,_,_,_)); true),
    readAndAssert(Str).

loadFlows(Path) :-
    open(Path, read, Str),
    (retractall(flow(_, _, _, _, _, _, _, _)); true),
    readAndAssert(Str).

loadEnergyProfiles(Path) :-
    open(Path, read, Str),
    (   retractall(energyProfile(_,_,_,_)); true),
    readAndAssert(Str).

loadCarbonCredits(Path) :-
    open(Path, read, Str),
    (retractall(carbonCredit(_,_,_,_)); true),
    readAndAssert(Str).

readAndAssert(Str) :-
    read(Str, X), (X == end_of_file -> close(Str) ; assert(X), readAndAssert(Str)).