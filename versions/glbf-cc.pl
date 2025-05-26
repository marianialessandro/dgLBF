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
    findall((Node, Load),
        ( member(Node, AllNodes),
          nodeBandwidths(Node, Alloc, BWs),
          sum_list(BWs, Load)
        ),
        NodeLoads).

nodeBandwidths(Node, Alloc, BWs) :-
    findall(BW,
        ( member((Node,_,BW), Alloc)
        ; member((_,Node,BW), Alloc)
        ),
        BWs).

computeCarbonFootprintAndCosts(NodeLoads, NodesCarbonFootprintAndCosts) :-
    findall((Node, LoadMb, Carbon, Cost),
        (
            member((Node, LoadMb), NodeLoads),
            routerEnergy(Node, LoadMb, EnergyUsed),
            routerCarbon(Node, EnergyUsed, Carbon),
            energyCost(Node, EnergyUsed, Cost)
        ),
        NodesCarbonFootprintAndCosts
    ).

sumCarbon([], 0).
sumCarbon([(_, _, C, _)|Tail], TotalCarbon) :-
    sumCarbon(Tail, RestCarbon),
    TotalCarbon is RestCarbon + C.

sumRouterCosts([], 0).
sumRouterCosts([(_,_,_,Cost)|Tail], Total) :-
    sumRouterCosts(Tail, Rest),
    Total is Rest + Cost.