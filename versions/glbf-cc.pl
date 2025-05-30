:-['./glbf-plain.pl'].
:-['../metrics/routerEnergy.pl'].
:-['../metrics/routerCarbon.pl'].
:-['../metrics/energyCost.pl'].
:-['./src/carbon_credit_calc.pl'].

glbfCC :-
    glbfCC(Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbonInt, Solution, TotalCost),
    format('~n--- Risultati glbfCC ---~n', []),
    format('Out                           = ~w~n', [Out]),
    format('Alloc                         = ~w~n', [Alloc]),
    format('NodesCarbonFootprintAndCosts = ~w~n', [NodesCarbonFootprintAndCosts]),
    format('Total CO2 (kg)               = ~d~n', [TotalCarbonInt]),
    format('Solution                      = ~w~n', [Solution]),
    format('MinCost (€)                  = ~2f~n~n', [TotalCost]).

glbfCC(Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost) :-
    glbf(Out, Alloc),
    computeNodeLoad(Alloc, NodeLoads),
    computeCarbonFootprintAndCosts(NodeLoads, NodesCarbonFootprintAndCosts),

    sumCarbon(NodesCarbonFootprintAndCosts, TotalCarbonFloat),
    TotalCarbon is ceiling(TotalCarbonFloat),
    carbonCreditCalculator(TotalCarbon, Solution, CarbonCreditCost),
    
    sumRouterCosts(NodesCarbonFootprintAndCosts, EnergyCost),
    TotalCost is EnergyCost + CarbonCreditCost.

glbfCC(Out,Alloc,BudgetCost) :-
    glbfCC(Out,Alloc,_,_,_,TotalCost),
    TotalCost =< BudgetCost.

allNodes(AllNodes) :-
    findall(Node, node(Node, _), AllNodes).

computeNodeLoad(Alloc, NodeLoads) :-
    allNodes(AllNodes),
    computeNodeLoadList(AllNodes, Alloc, NodeLoads).

computeNodeLoadList([Node|Rest], Alloc, [(Node,Load)|NodeLoads]) :-
    nodeBandwidths(Node, Alloc, BWs),
    sum_list(BWs, Load),
    computeNodeLoadList(Rest, Alloc, NodeLoads).
computeNodeLoadList([], _, []).


nodeBandwidths(Node, Alloc, BWs) :-
    findall(BW, inOutBw(Node,Alloc,BW), BWs). 

inOutBw(Node, Alloc, BW) :- 
    member((Node,_,BW), Alloc) ; member((_,Node,BW), Alloc).

computeCarbonFootprintAndCosts([(Node,LoadMb)|Tail], [(Node,LoadMb,Carbon,Cost)|Rest]) :-
    routerEnergy(Node, LoadMb, EnergyUsed),
    routerCarbon(Node, EnergyUsed, Carbon),
    energyCost(Node, EnergyUsed, Cost),
    computeCarbonFootprintAndCosts(Tail, Rest).
computeCarbonFootprintAndCosts([], []).

sumCarbon([(_, _, C, _)|Tail], TotalCarbon) :-
    sumCarbon(Tail, RestCarbon),
    TotalCarbon is RestCarbon + C.
sumCarbon([], 0).

sumRouterCosts([(_,_,_,Cost)|Tail], Total) :-
    sumRouterCosts(Tail, Rest),
    Total is Rest + Cost.
sumRouterCosts([], 0).