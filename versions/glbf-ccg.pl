:- ['../metrics/routerEnergy.pl', '../metrics/routerCarbon.pl', '../metrics/energyCost.pl', '../metrics/nodeLoad.pl'].
:- ['src/utils.pl', 'src/pprint.pl', 'src/carbon_credit_calc.pl', 'src/carbonAndCostUtils.pl'].
:- ['glbf-plain.pl'].

glbfCC :-
    glbfCC(Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbonInt, Solution, TotalCost),
    format('~n--- Risultati glbfCC ---~n', []),
    format('Out                           = ~w~n', [Out]),
    format('Alloc                         = ~w~n', [Alloc]),
    format('NodesCarbonFootprintAndCosts = ~w~n', [NodesCarbonFootprintAndCosts]),
    format('Total CO2 (kg)               = ~d~n', [TotalCarbonInt]),
    format('Solution                      = ~w~n', [Solution]),
    format('MinCost (€)                  = ~2f~n~n', [TotalCost]).

glbfCC(BudgetCost, Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost) :-
    glbf(Out, Alloc),
    allNodes(AllNodes),
    computeNodeLoad(AllNodes, Alloc, NodeLoads),
    computeCarbonFootprintAndCosts(NodeLoads, NodesCarbonFootprintAndCosts),

    sumCarbon(NodesCarbonFootprintAndCosts, TotalCarbonFloat),
    TotalCarbon is ceiling(TotalCarbonFloat),
    carbonCreditCalculator(TotalCarbon, Solution, CarbonCreditCost),
    
    sumRouterCosts(NodesCarbonFootprintAndCosts, EnergyCost),
    TotalCost is EnergyCost + CarbonCreditCost,

    TotalCost < BudgetCost.

glbfCC(Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost) :-
    glbfCC(1.0Inf, Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost).
