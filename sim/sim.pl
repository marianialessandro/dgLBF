:-['../versions/glbf-cc.pl'].


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

sim_greenglbf(Out, Alloc, NodeCarbonCost, Infs, Time) :-
    statistics(inferences, I1),
        statistics(cputime, T1),
            wrap_greenglbf(Out, Alloc, NodeCarbonCost),
        statistics(cputime, T2),
    statistics(inferences, I2),
    Infs is I2 - I1 - 5,
    Time  is T2 - T1.

wrap_greenglbf(Out, Alloc, NodeCarbonCost) :-
    % qui invochi il tuo predicato a 3 argomenti
    glbf_with_node_carbon_and_costs(Out, Alloc, NodeCarbonCost).
wrap_greenglbf([], [], []) :-
    \+ glbf_with_node_carbon_and_costs(_, _, _).

loadInfrastructure(Path) :-
    open(Path, read, Str),
    (retractall(node(_,_)), retractall(link(_,_,_,_,_)); true),
    readAndAssert(Str).

loadFlows(Path) :-
    open(Path, read, Str),
    (retractall(flow(_, _, _, _, _, _, _, _)); true),
    readAndAssert(Str).

% load all energyProfile/4 facts from Path, replacing any existing ones
loadEnergyProfiles(Path) :-
    open(Path, read, Str),
    % remove any previously loaded energyProfile/4 facts
    (   retractall(energyProfile(_,_,_,_))
    ;   true
    ),
    % read & assert each fact until end_of_file, then close(Str)
    readAndAssert(Str).

readAndAssert(Str) :-
    read(Str, X), (X == end_of_file -> close(Str) ; assert(X), readAndAssert(Str)).