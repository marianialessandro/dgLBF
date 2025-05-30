:- use_module(library(clpfd)).

carbonCreditCalculator(TargetCO2, Solution, MinCost) :-
    init(Ids, CO2s, Costs, MaxQs),

    length(Ids, N),
    length(Qs, N),
    Qs ins 0..sup,
    constrain_max(Qs, MaxQs),

    scalar_product(CO2s, Qs, #=, TotalCO2),
    TotalCO2 #>= TargetCO2,
    scalar_product(Costs, Qs, #=, TotalCost),

    append(Qs, [TotalCost], Vars),
    labeling([min(TotalCost)], Vars),

    MinCost = TotalCost,
    pair_ids_q(Ids, Qs, Solution).

init(Ids, CO2s, Costs, MaxQs) :-
    findall(carbonCredit(Id,CO2,Cost,MaxQ), carbonCredit(Id,CO2,Cost,MaxQ), Credits),
    unzip(Credits, Ids, CO2s, Costs, MaxQs).

unzip([carbonCredit(I,CO2,C,Cap)|T], [I | Is], [CO2 | CO2s], [C | Cs], [Cap | Caps]) :-
    unzip(T, Is, CO2s, Cs, Caps).
unzip([], [], [], [], []).

constrain_max([Q|Qs], [MaxQ|MaxQs]) :-
    Q #=< MaxQ,
    constrain_max(Qs, MaxQs).
constrain_max([], []).

pair_ids_q([I|Is], [Q|Qs], [id(I,Q)|Rest]) :-
    pair_ids_q(Is, Qs, Rest).
pair_ids_q([], [], []).
