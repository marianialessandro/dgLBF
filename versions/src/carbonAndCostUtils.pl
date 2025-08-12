:- table routerMetrics/4.

computeCarbonFootprintAndCosts([], Result) :- !,
    allNodes(AllNodes),
    computeCarbonFootprintAndCostsEmpty(AllNodes, Result).
computeCarbonFootprintAndCosts(NodeLoads, NodesCarbonFootprintAndCosts) :-
    computeCarbonFootprintAndCostsRec(NodeLoads, NodesCarbonFootprintAndCosts).

computeCarbonFootprintAndCostsRec([(Node,LoadMb)|Tail], [(Node,LoadMb,Carbon,Cost)|Rest]) :-
    routerMetrics(Node, LoadMb, Carbon, Cost),
    computeCarbonFootprintAndCostsRec(Tail, Rest).
computeCarbonFootprintAndCostsRec([], []).


computeCarbonFootprintAndCostsEmpty([], []).
computeCarbonFootprintAndCostsEmpty([Node | Tail], [(Node,LoadMb,Carbon,Cost)|Rest]) :-
    routerLoad(Node, [], LoadMb),
    routerMetrics(Node, LoadMb, Carbon, Cost),
    computeCarbonFootprintAndCostsEmpty(Tail, Rest).

routerMetrics(Node, LoadMb, Carbon, Cost) :-
    routerEnergy(Node, LoadMb, EnergyUsed),
    routerCarbon(Node, LoadMb, Carbon),
    energyCost(Node, EnergyUsed, Cost).

sumCarbon([(_, _, C, _)|Tail], TotalCarbon) :-
    sumCarbon(Tail, RestCarbon),
    TotalCarbon is RestCarbon + C.
sumCarbon([], 0).

sumRouterCosts([(_,_,_,Cost)|Tail], Total) :-
    sumRouterCosts(Tail, Rest),
    Total is Rest + Cost.
sumRouterCosts([], 0).
