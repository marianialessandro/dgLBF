:- use_module(library(clpfd)).

carbonCreditCalculator(TargetCO2, Solution, MinCost) :-
    allCarbonCredits(Items),
    creditModel(Items, TotalCO2, MinCost, Qs, Solution),
    TotalCO2 #>= TargetCO2,
    labeling([min(MinCost)], [MinCost|Qs]).

allCarbonCredits(Items) :-
    findall(credit(Id,CO2,Cost,MaxQ),
            carbonCredit(Id,CO2,Cost,MaxQ),
            Items).

creditModel([], 0, 0, [], []).
creditModel([credit(Id,CO2,Cost,MaxQ)|T], SumCO2, SumCost, [Q|Qs], [id(Id,Q)|Sol]) :-
    Q in 0..MaxQ,
    SumCO2 #= CO2*Q + RestCO2,
    SumCost #= Cost*Q + RestCost,
    creditModel(T, RestCO2, RestCost, Qs, Sol).
