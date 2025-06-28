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
