:- ['../metrics/routerEnergy.pl', '../metrics/routerCarbon.pl', '../metrics/energyCost.pl', '../metrics/nodeLoad.pl'].
:- ['src/utils.pl', 'src/pprint.pl', 'src/carbon_credit_calc.pl', 'src/carbonAndCostUtils.pl', 'src/getter.pl', 'src/bandwidths.pl'].
:- ['glbf-plain.pl'].

:- dynamic bestCarbon/1, bestSolutions/1.

glbfCC(BudgetCost, Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost) :-
    solve_bnb_refine(Out, Alloc, _),
    computeNodeLoad(Alloc, NodeLoads),
    computeCarbonFootprintAndCosts(NodeLoads, NodesCarbonFootprintAndCosts),
    sumCarbon(NodesCarbonFootprintAndCosts, TotalCarbonFloat),
    TotalCarbon is ceiling(TotalCarbonFloat),
    carbonCreditCalculator(TotalCarbon, Solution, CarbonCreditCost),
    sumRouterCosts(NodesCarbonFootprintAndCosts, EnergyCost),
    TotalCost is EnergyCost + CarbonCreditCost,
    TotalCost < BudgetCost.

glbfCC(Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost) :-
    glbfCC(1.0Inf, Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost).

initState(Out, Alloc, NodeLoads, TotalCarbon) :-
    once(glbf(Out, Alloc)),
    computeNodeLoad(Alloc, NodeLoads),
    computeCarbonFootprintAndCosts(NodeLoads, CarbonAndCosts),
    sumCarbon(CarbonAndCosts, TotalCarbonFloat),
    TotalCarbon is ceiling(TotalCarbonFloat).

initBestGreedy :-
    initState(Out0, Alloc0, _, Carbon0),
    retractall(bestCarbon(_)),
    retractall(bestSolutions(_)),
    assertz(bestCarbon(Carbon0)),
    assertz(bestSolutions([(Out0, Alloc0)])).

updateBest(Out, Alloc, Carbon) :-
    bestCarbon(BestCarbon),
    (   Carbon < BestCarbon
    ->  retractall(bestCarbon(_)),
        retractall(bestSolutions(_)),
        assertz(bestCarbon(Carbon)),
        assertz(bestSolutions([(Out, Alloc)]))
        % , format('New best carbon: ~w~n', [Carbon])
    ;   Carbon =:= BestCarbon
    ->  retract(bestSolutions(Solutions)),
        assertz(bestSolutions([(Out, Alloc)|Solutions]))
        /* , format('Added equivalent solution: ~w~n', [Carbon]) */
    ;   true
    ).

solve_bnb_refine(Out, Alloc, TotalCarbon) :-
    initBestGreedy,
    allFlows(Flows),
    (   bnb(state([], [], [], 0, Flows)),
        fail  % Force backtracking to find all solutions
    ;   true  % Continue after all solutions are explored
    ),
    !,  % Commit to the best solutions found
    bestCarbon(TotalCarbon),
    bestSolutions(Solutions),
    member((Out, Alloc), Solutions).

flowDetails(FlowId, S, D, PacketSize, BitRate, Budget, Th) :-
    flow(FlowId, S, D),
    dataReqs(FlowId, PacketSize, _, BitRate, Budget, Th).

processPath(Path, MinB0, Alloc, PacketSize, BitRate, NewMinB, Delay, NewAlloc, NodeLoads2, CarbonInt) :-
    pathOk(Path, MinB0, Alloc, PacketSize, BitRate, NewMinB),
    delay(NewMinB, Path, Delay),
    updateCapacities(Path, BitRate, Alloc, NewAlloc),
    computeNodeLoad(NewAlloc, NodeLoads2),
    computeCarbonFootprintAndCosts(NodeLoads2, NodesCFC),
    sumCarbon(NodesCFC, CarbonFloat),
    CarbonInt is ceiling(CarbonFloat).

commitSolution(FlowId, PId, Path, NewMinB, Delay, Out, NewAlloc, NodeLoads2, CarbonInt, Flows) :-
    bnb(state(NewAlloc, [(FlowId, PId, Path, NewMinB, Delay)|Out], NodeLoads2, CarbonInt, Flows)).

% Modifica il caso base di bnb
bnb(state(Alloc, Out, _, Carbon, [])) :-
    allFlows(AllFlows),
    findall(F, member((F,_,_,_,_), Out), RoutedFlows),
    sort(RoutedFlows, SortedRouted),
    sort(AllFlows, SortedAll),
    SortedRouted == SortedAll,
    
    findall((F, PId, Path), member((F, PId, Path, _, _), Out), Paths),
    compatiblePaths(Out, Paths, TransformedOut),

    % format('Found complete solution: Carbon=~w~n', [Carbon]),
    
    updateBest(TransformedOut, Alloc, Carbon),
    fail.

% Pruning condition
bnb(State) :-
    State = state(_, _, _, CurrentCarbon, _),
    bestCarbon(BestCarbon),
    CurrentCarbon > BestCarbon,
    !,
    /* format('Pruning branch with carbon ~w (best: ~w)~n', [CurrentCarbon, BestCarbon]), */
    fail.

% Main recursive processing
bnb(state(Alloc, Out, NodeLoads, Carbon, [FlowId|Flows])) :-
    flowDetails(FlowId, S, D, PacketSize, BitRate, Budget, Th),
    MinB0 is Budget - Th,
    candidate(PId, S, D, Path),
    processPath(Path, MinB0, Alloc, PacketSize, BitRate, NewMinB, Delay, NewAlloc, NodeLoads2, CarbonInt),
    commitSolution(FlowId, PId, Path, NewMinB, Delay, Out, NewAlloc, NodeLoads2, CarbonInt, Flows).

bnb(_) :- 
    /* format('Continuing search...~n'), */
    fail.
