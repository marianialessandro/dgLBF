:- ['../metrics/routerEnergy.pl', '../metrics/routerCarbon.pl', '../metrics/energyCost.pl', '../metrics/nodeLoad.pl'].
/* :- ['src/utils.pl', 'src/carbon_credit_calc.pl', 'src/state.pl', 'src/carbonAndCostUtils.pl', 'src/solutionCost.pl']. */
:- ['src/carbon_credit_calc.pl', 'src/state.pl', 'src/carbonAndCostUtils.pl', 'src/solutionCost.pl'].
:- ['glbf-plain.pl'].

/* :- set_prolog_flag(answer_write_options,[max_depth(0), spacing(next_argument)]).
:- set_prolog_flag(stack_limit, 64 000 000 000).
:- set_prolog_flag(last_call_optimisation, true). */

:- table flowCandidates/2.

% Predicati Principali

glbfCC(BudgetCost, Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost, Count) :-
    exploreSolutions(Out, Alloc, TotalCarbon, Count),
    !,
    carbonCreditCalculator(TotalCarbon, Solution, CarbonCreditCost),
    allNodes(AllNodes),
    computeNodeLoad(AllNodes, Alloc, NodeLoads),
    computeCarbonFootprintAndCosts(NodeLoads, NodesCarbonFootprintAndCosts),
    sumRouterCosts(NodesCarbonFootprintAndCosts, EnergyCost),
    TotalCost is EnergyCost + CarbonCreditCost,
    TotalCost < BudgetCost.

glbfCC(Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost, Count) :-
    glbfCC(1.0Inf, Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost, Count).

idleCarbon(InitialCarbon) :-
    allNodes(Nodes),
    idleCarbonRec(Nodes, InitialCarbon).

idleCarbonRec([Node | Tail], Carbon) :-
    idleCarbonRec(Tail, TmpCarbon),
    routerCarbon(Node, 0, RouterCarbon),
    Carbon is TmpCarbon + RouterCarbon.
idleCarbonRec([], 0).


exploreSolutions(Out, Alloc, Carbon, Count) :-
    allFlows(Flows),
    initScores(Flows, [], [], CandidateScoresByFlow),

    upperBound(OutU, AllocU, NodeLoads, UpperBound, UpperCost),

    % format('Upper Bound Calcolato ~wkg ~w€ ~n', [UpperBound, UpperCost]),
    format('Soluzione GREEDY PER UPPER:~n'),
    format('  Out        = ~w~n', [OutU]),
    format('  Alloc      = ~w~n', [AllocU]),
    format('  NodeLoad   = ~w~n', [NodeLoads]),
    format('  TotalCarbon= ~w~n', [UpperBound]),
    format('  Cost       = ~w~n~n~n', [UpperCost]),

    idleCarbon(InitialCarbon),

    % Prova la ricerca; se fallisce o non produce soluzioni,
    % usa direttamente l'upper bound come risultato finale.
    (   searchBest(
            state([], [], [], InitialCarbon, CandidateScoresByFlow),
            bestState(UpperBound, UpperCost, [(OutU, AllocU)], 1),
            FinalState0
        )
    ->  true
    ;   FinalState0 = bestState(UpperBound, UpperCost, [(OutU, AllocU)], 1),
        format('Nessun miglioramento trovato: uso la soluzione UPPER BOUND.~n')
    ),

    FinalState0 = bestState(Carbon, _, Solutions, Count),

    member((Out, Alloc), Solutions).


searchBest(state(Alloc, Out, NodeMetrics, Carbon, []), BestState, NewBestState) :-
    hasAllFlowsRouted(Out),
    findall((F, CandidateId, Path), member((F, CandidateId, Path, _, _), Out), Paths),
    compatiblePaths(Out, Paths, TransformedOut),
    updateBestState(TransformedOut, Alloc, NodeMetrics, Carbon, BestState, NewBestState).

searchBest(state(OldAlloc, OldOut, OldNodeMetrics, OldCarbon, [(FlowId, SortedCandidateScores)|CandidateScoresByFlowTail]), BestState, NewBestState) :-
    member((CandidateId, _), SortedCandidateScores),
    candidate(CandidateId, _, _, Path),

    format('Provo ~w per ~w~n', [CandidateId, FlowId]),

    processPathPerFlow(FlowId, CandidateId, OldCarbon, OldAlloc, OldNodeMetrics, NewMinB, NewAlloc, NewNodeMetrics, Delay, NewCarbon),
    CarbonCeil is ceiling(NewCarbon),
    solutionCost(NewNodeMetrics, Cost),
    \+ shouldPrune(CarbonCeil, Cost, BestState),
    
    lowerBound(CandidateScoresByFlowTail, NewCarbon, NewAlloc, NewNodeMetrics, LowerBoundCarbon, LowerBoundCost),
    \+ shouldPrune(LowerBoundCarbon, LowerBoundCost, BestState),
    
    list_to_set(Path, UpdatedNodes),
    updateScores(CandidateScoresByFlowTail, NewAlloc, UpdatedNodes, NewNodeMetrics, UpdatedTail),


    searchBest(state(NewAlloc, [(FlowId, CandidateId, Path, NewMinB, Delay)|OldOut], NewNodeMetrics, NewCarbon, UpdatedTail), BestState, NewBestState).

updateBestState(Out, Alloc, NodeMetrics, Carbon, bestState(BestCarbon, _, _, BCount), bestState(CarbonCeil, NewCostEnergy, [(Out,Alloc)], NewCount)) :-
    CarbonCeil is ceiling(Carbon),
    CarbonCeil < BestCarbon,
    solutionCost(NodeMetrics, NewCostEnergy),

    format('Soluzione Trovata:~n'),
    format('  Out        = ~w~n', [Out]),
    format('  Alloc      = ~w~n', [Alloc]),
    format('  TotalCarbon= ~w~n', [Carbon]),
    format('  Cost= ~w~n~n~n~n~n~n~n', [NewCostEnergy]),

    NewCount  is BCount + 1.

updateBestState(Out, Alloc, NodeMetrics, Carbon, bestState(BestCarbon, BCost, _, BCount), bestState(CarbonCeil, Cost, [(Out,Alloc)], NewCount)) :-
    CarbonCeil is ceiling(Carbon),
    CarbonCeil =:= BestCarbon,
    solutionCost(NodeMetrics, Cost),
    Cost < BCost,

    format('Soluzione Trovata:~n'),
    format('  Out        = ~w~n', [Out]),
    format('  Alloc      = ~w~n', [Alloc]),
    format('  TotalCarbon= ~w~n', [Carbon]),
    format('  Cost= ~w~n~n~n~n~n~n~n', [Cost]),

    NewCount   is BCount + 1.

updateBestState(Out, Alloc, NodeMetrics, Carbon, bestState(BestCarbon, BCost, BSolutions, BCount), bestState(CarbonCeil, BCost, [(Out,Alloc)|BSolutions], NewCount)) :-
    CarbonCeil is ceiling(Carbon),
    CarbonCeil =:= BestCarbon,
    solutionCost(NodeMetrics, Cost),
    Cost =:= BCost,

    format('Soluzione Trovata:~n'),
    format('  Out        = ~w~n', [Out]),
    format('  Alloc      = ~w~n', [Alloc]),
    format('  TotalCarbon= ~w~n', [Carbon]),
    format('  Cost= ~w~n~n~n~n~n~n~n', [Cost]),

    NewCount   is BCount + 1.


shouldPrune(Carbon, Cost, bestState(BestCarbon, BCost, _, _)) :-
    (   Carbon > BestCarbon
    ;   Carbon =:= BestCarbon, Cost >= BCost
    ),
    format('Pruning ~n').

processPathPerFlow(FlowId, CandidateId, OldCarbon, OldAlloc, OldNodeMetrics, NewMinB, NewAlloc, NewNodeMetrics, Delay, NewCarbon) :-
    candidate(CandidateId, _, _, Path),
    flowDetails(FlowId, _, _, PacketSize, BitRate, Budget, Th),
    MinB is Budget - Th,
    updateState(Path, OldCarbon, MinB, BitRate, PacketSize, OldAlloc, OldNodeMetrics, NewCarbon, NewAlloc, NewNodeMetrics, NewMinB),
    delay(NewMinB, Path, Delay).

lowerBound(CandidateScoresByFlow, OldCarbon, OldAlloc, OldNodeMetrics, LowerBoundCarbon, LowerBoundCost):-
    lowerBound(CandidateScoresByFlow, OldCarbon, OldAlloc, OldNodeMetrics, _, NewNodeMetrics, NewCarbon),
    solutionCost(NewNodeMetrics, LowerBoundCost),
    LowerBoundCarbon is ceiling(NewCarbon).

lowerBound([], OldCarbon, _, OldNodeMetrics, _, OldNodeMetrics, OldCarbon).
lowerBound([(FlowId, [(CandidateId, _) | _])|CandidateScoresByFlowTail], OldCarbon, OldAlloc, OldNodeMetrics, NewAlloc, NewNodeMetrics, NewCarbon) :-
    processPathPerFlow(FlowId, CandidateId, OldCarbon, OldAlloc, OldNodeMetrics, _, TmpAlloc, TmpNodeMetrics, _, TmpCarbon),
    lowerBound(CandidateScoresByFlowTail, TmpCarbon, TmpAlloc, TmpNodeMetrics, NewAlloc, NewNodeMetrics, NewCarbon).




upperBound(Out, Alloc, NodeLoads, TotalCarbon, TotalCost) :-
    once(glbf(Out, Alloc)),
    allNodes(AllNodes),
    computeNodeLoad(AllNodes, Alloc, NodeLoads),
    computeCarbonFootprintAndCosts(NodeLoads, CarbonAndCosts),
    sumCarbon(CarbonAndCosts, TotalCarbonFloat),
    TotalCarbon is ceiling(TotalCarbonFloat),
    sumRouterCosts(CarbonAndCosts, EnergyCost),
    TotalCost is EnergyCost.






hasAllFlowsRouted(Out) :-
    allFlows(AllFlows),
    findall(F, member((F,_,_,_,_), Out), RoutedFlows),
    sort(RoutedFlows, SortedRouted),
    sort(AllFlows, SortedAll),
    SortedRouted == SortedAll.


initScores([], _, _, []).
initScores([FlowId | FlowsTail], Alloc, NodeMetrics, [(FlowId, ScoreSorted) | CandidateScoresByFlowTail]) :-
    flowDetails(FlowId, _, _, _, BitRate, _, _),
    flowCandidates(FlowId, Candidates),
    candidatesMetrics(Candidates, Alloc, NodeMetrics, CandidatesMetrics),
    filterCandidatesByBandwidth(CandidatesMetrics, BitRate, FilteredCandidatesMetrics),
    minMaxCarbon(FilteredCandidatesMetrics, MinCarbon, MaxCarbon),
    minMaxCandidateLength(FilteredCandidatesMetrics, MinLen, MaxLen),
    minMaxCost(FilteredCandidatesMetrics, MinCost, MaxCost),
    candidatesScores(FilteredCandidatesMetrics, BitRate, MinCarbon, MaxCarbon, MinLen, MaxLen, MinCost, MaxCost, ScoresUnsorted),
    sortScores(ScoresUnsorted, ScoreSorted),
    initScores(FlowsTail, Alloc, NodeMetrics, CandidateScoresByFlowTail).

sortScores(List, Sorted) :-
    sort(2, @=<, List, Sorted).

minMaxCandidateLength([], 0, 0).
minMaxCandidateLength([(Id, _, _)|Ids], Min, Max) :-
    candidate_length(Id, L0),
    minMaxLenRec(Ids, L0, L0, Min, Max).
minMaxLenRec([], CurMin, CurMax, CurMin, CurMax).
minMaxLenRec([(Id, _, _)|Ids], CurMin, CurMax, Min, Max) :-
    candidate_length(Id, L),
    NewMin is min(CurMin, L),
    NewMax is max(CurMax, L),
    minMaxLenRec(Ids, NewMin, NewMax, Min, Max).

minMaxCarbon([], 0, 0).
minMaxCarbon([(_, C0, _, _) | Ts], Min, Max) :-
    minMaxCarbonRec(Ts, C0, C0, Min, Max).
minMaxCarbonRec([], AccMin, AccMax, AccMin, AccMax).
minMaxCarbonRec([(_, C, _, _) | Ts], AccMin, AccMax, Min, Max) :-
    NewMin is min(AccMin, C),
    NewMax is max(AccMax, C),
    minMaxCarbonRec(Ts, NewMin, NewMax, Min, Max).

minMaxCost([], 0, 0).
minMaxCost([(_, _, Cost, _) | Tail], Min, Max) :-
    minMaxCostRec(Tail, Cost, Cost, Min, Max).

minMaxCostRec([], Min, Max, Min, Max).
minMaxCostRec([(_, _, Cost, _) | Tail], CurrMin, CurrMax, Min, Max) :-
    NewMin is min(CurrMin, Cost),
    NewMax is max(CurrMax, Cost),
    minMaxCostRec(Tail, NewMin, NewMax, Min, Max).

filterCandidatesByBandwidth([], _, []).
filterCandidatesByBandwidth([(CandidateId, Carbon, CostEnergyPath, Bandwidth) | CandidatesMetricsTail], BitRate, [(CandidateId, Carbon, CostEnergyPath, Bandwidth) | FilteredTail]) :-
    Bandwidth >= BitRate,
    filterCandidatesByBandwidth(CandidatesMetricsTail, BitRate, FilteredTail).
filterCandidatesByBandwidth([_ | CandidatesMetricsTail], BitRate, FilteredTail) :-
    filterCandidatesByBandwidth(CandidatesMetricsTail, BitRate, FilteredTail).

flowCandidates(FlowId, CandidateIds) :-
    findall(CandidateId,
        (flow(FlowId, S, D),
            candidate(CandidateId, S, D, _)),
        CandidateIds).

candidatesMetrics([], _, _, []).
candidatesMetrics([CandidateId | CandidatesTail], Alloc, NodeMetrics, [(CandidateId, Carbon, CostEnergyPath, Bandwidth)|CandidatesMetricTail]) :-
    candidate(CandidateId, _, _, Path),
    candidateMetrics(Path, Alloc, NodeMetrics, Carbon, CostEnergyPath, Bandwidth),
    candidatesMetrics(CandidatesTail, Alloc, NodeMetrics, CandidatesMetricTail).



candidateMetrics(Path, Alloc, NodeMetrics, NewCarbon, NewCostEnergy, NewBandwidth) :-
    candidateMetrics(Path, Alloc, NodeMetrics, 0, 0, 1.0Inf, NewCarbon, NewCostEnergy, NewBandwidth).

candidateMetrics([], _, _, OldCarbon, CostEnergyOld, OldBandwidth, NewCarbon, NewCostEnergy, NewBandwidth) :-
    NewCarbon    = OldCarbon,
    NewCostEnergy      = CostEnergyOld,
    NewBandwidth = OldBandwidth.

candidateMetrics([S], _, NodeMetrics, OldCarbon, CostEnergyOld, OldBandwidth, NewCarbon, NewCostEnergy, NewBandwidth) :-
    routerLoad(S, NodeMetrics, RouterLoad),
    routerCarbon(S, RouterLoad, RouterCarbon),
    routerCost(S, RouterLoad, RouterEnergyCost),
    NewCarbon is OldCarbon + RouterCarbon,
    NewCostEnergy   is CostEnergyOld   + RouterEnergyCost,
    NewBandwidth = OldBandwidth.

candidateMetrics([S, N | Rest], Alloc, NodeMetrics, OldCarbon, CostEnergyOld, OldBandwidth, NewCarbon, NewCostEnergy, NewBandwidth) :-
    link(S, N, _, LinkBandwidth, _),
    usedBandwidth(S, N, Alloc, UsedBW),
    Diff         is LinkBandwidth - UsedBW,
    TmpBandwidth is min(OldBandwidth, Diff),
    routerLoad(S, NodeMetrics, RouterLoad),
    routerCarbon(S, RouterLoad, RouterCarbon),
    routerCost(S, RouterLoad, RouterEnergyCost),
    TmpCarbon is OldCarbon + RouterCarbon,
    CostEnergyTmp   is CostEnergyOld   + RouterEnergyCost,
    candidateMetrics([N|Rest], Alloc, NodeMetrics, TmpCarbon, CostEnergyTmp, TmpBandwidth, NewCarbon, NewCostEnergy, NewBandwidth).

candidatesScores([], _, _, _, _, _, _, _, []).
candidatesScores([(CandidateId, Carbon, CostEnergyPath, _) | CandidatesMetricsTail], BitRate, MinCarbon, MaxCarbon, MinLen, MaxLen, MinCost, MaxCost, [(CandidateId, Score) | TailScores]) :-
    candidate_length(CandidateId, Len),
    normalize(Len,  MinLen, MaxLen, LenNorm),
    normalize(Carbon, MinCarbon, MaxCarbon, CarbonNorm),
    normalize(CostEnergyPath, MinCost, MaxCost, EnergyCostNorm),
    Score is LenNorm + CarbonNorm + EnergyCostNorm,
    candidatesScores(CandidatesMetricsTail, BitRate, MinCarbon, MaxCarbon, MinLen, MaxLen, MinCost, MaxCost, TailScores).

normalize(_, Min, Max, 0) :-
    Max =:= Min, !.
normalize(X, Min, Max, Norm) :-
    Max =\= Min,
    Norm is (X - Min) / (Max - Min).

flowUsesUpdatedNodes(UpdatedNodes, CandidateIds) :-
    member(CandidateId, CandidateIds),
    candidate(CandidateId, _, _, Path),
    intersection(Path, UpdatedNodes, SharedNodes),
    SharedNodes \= [].

updateScores([], _, _, _, []).
updateScores([(FlowId, OldCandidatesScores)|CandidateScoresByFlowTail], Alloc, UpdatedNodes, NodeMetrics, [(FlowId, ScoreSorted)|NewCandidateScoresByFlowTail]) :-
    findall(CandidateId, member((CandidateId, _), OldCandidatesScores), Candidates),
    flowUsesUpdatedNodes(UpdatedNodes, Candidates),
    candidatesMetrics(Candidates, Alloc, NodeMetrics, CandidatesMetrics),
    flowDetails(FlowId, _, _, _, BitRate, _, _),
    filterCandidatesByBandwidth(CandidatesMetrics, BitRate, FilteredCandidatesMetrics),
    minMaxCarbon(FilteredCandidatesMetrics, MinCarbon, MaxCarbon),
    minMaxCandidateLength(FilteredCandidatesMetrics, MinLen, MaxLen),
    minMaxCost(FilteredCandidatesMetrics, MinCost, MaxCost),
    candidatesScores(FilteredCandidatesMetrics, BitRate, MinCarbon, MaxCarbon, MinLen, MaxLen, MinCost, MaxCost, ScoresUnsorted),
    sortScores(ScoresUnsorted, ScoreSorted),
    updateScores(CandidateScoresByFlowTail, Alloc, UpdatedNodes, NodeMetrics, NewCandidateScoresByFlowTail).
updateScores([(FlowId, OldCandidatesScores)|CandidateScoresByFlowTail], Alloc, UpdatedNodes, NodeMetrics, [(FlowId, OldCandidatesScores)|NewCandidateScoresByFlowTail]) :-
    findall(CandidateId, member((CandidateId, _), OldCandidatesScores), Candidates),
    \+ flowUsesUpdatedNodes(UpdatedNodes, Candidates),
    updateScores(CandidateScoresByFlowTail, Alloc, UpdatedNodes, NodeMetrics, NewCandidateScoresByFlowTail).