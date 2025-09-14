computeCarbonFootprintAndCosts([], Result) :- !,
    allNodes(AllNodes),
    computeCarbonFootprintAndCostsEmpty(AllNodes, Result).
computeCarbonFootprintAndCosts(NodesLoad, NodesCarbonFootprintAndCosts) :-
    allNodes(Nodes),
    computeCarbonFootprintAndCosts(Nodes, NodesLoad, [], NodesCarbonFootprintAndCosts).

computeCarbonFootprintAndCosts([], _, NodesCarbonFootprintAndCosts, NodesCarbonFootprintAndCosts).
computeCarbonFootprintAndCosts([Node | Nodes], NodesLoad, NodesCarbonFootprintAndCostsIn, NodesCarbonFootprintAndCosts) :-
    routerLoad(Node, NodesLoad, Load),
    routerCarbonCost(Node, Load, Carbon, Cost),
    computeCarbonFootprintAndCosts(Nodes, NodesLoad, [(Node,Load,Carbon,Cost)|NodesCarbonFootprintAndCostsIn], NodesCarbonFootprintAndCosts).

computeCarbonFootprintAndCostsEmpty([], []).
computeCarbonFootprintAndCostsEmpty([Node | Tail], [(Node,LoadMb,Carbon,Cost)|Rest]) :-
    routerLoad(Node, [], LoadMb),
    routerCarbonCost(Node, LoadMb, Carbon, Cost),
    computeCarbonFootprintAndCostsEmpty(Tail, Rest).


routerCarbonCost(N, Load, Carbon, Cost) :-
    timePeriod(T),
    energyProfile(N, IdlePower, P, MaxPower, CostkWh),
    routerEnergy(Load, IdlePower, MaxPower, P, T, Energy_kWh),
    alpha(N, Alpha),
    Carbon is Energy_kWh * Alpha,
    Cost is Energy_kWh * CostkWh.

sumCarbon([(_, _, C, _)|Tail], TotalCarbon) :-
    sumCarbon(Tail, RestCarbon),
    TotalCarbon is RestCarbon + C.
sumCarbon([], 0).

sumRouterCosts([(_,_,_,Cost)|Tail], Total) :-
    sumRouterCosts(Tail, Rest),
    Total is Rest + Cost.
sumRouterCosts([], 0).