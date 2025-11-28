:- ['../metrics/routerEnergy.pl', '../metrics/routerCarbon.pl', '../metrics/energyCost.pl', '../metrics/nodeLoad.pl'].
:- ['src/carbon_credit_calc.pl', 'src/carbonAndCostUtils.pl', 'src/solutionCost.pl'].
:- ['glbf-ccg.pl'].

glbfCCBNB(BudgetCost, Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, EnergyCost, TotalCost) :-
    glbfCCBNB(Out, Alloc, TotalCarbon, EnergyCost),
    TotalCarbonInt is ceiling(TotalCarbon),
    carbonCreditCalculator(TotalCarbonInt, Solution, CarbonCreditCost),
    allNodes(AllNodes),
    computeNodeLoad(AllNodes, Alloc, NodeLoads),
    computeCarbonFootprintAndCosts(NodeLoads, NodesCarbonFootprintAndCosts),
    TotalCost is EnergyCost + CarbonCreditCost,
    TotalCost < BudgetCost.

glbfCCBNB(Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, EnergyCost, TotalCost):-
    glbfCCBNB(1.0Inf, Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, EnergyCost, TotalCost).

round2(N, R) :-
    R is round(N*100) / 100.

init(OrderedFlows, InitialCarbon, InitialCost) :-
    initGlobals,
    flowOrdered(OrderedFlows),
    upperBound(OutU, AllocU, _, UpperBound, UpperCost),
    setGlobalSolution(OutU, AllocU, UpperBound, UpperCost),
    init(InitialCarbon, InitialCost),
    nb_setval(solutions_explored, 1).

glbfCCBNB(Out, Alloc, Carbon, BestCost) :-
    once(init(OrderedFlows, InitialCarbon, InitialCost)),
    (   searchBest(state([], [], [], InitialCarbon, InitialCost, OrderedFlows)),
        fail
    ;   true
    ),
    !,
    nb_getval(best, best(Carbon, BestCost, Solutions, _)),
    member(solution(Out, Alloc), Solutions),
    (Out \== [] ; Alloc \== []).

searchBest(state(Alloc, Out, NodeLoads, Carbon, Cost, [])) :-
    once(validPaths(Out, TransformedOut)),
    updateBest(TransformedOut, Alloc, NodeLoads, Carbon, Cost),
    fail.

searchBest(state(Alloc, Out, NodeLoads, Carbon, Cost, [FlowId | RestFlows])) :-
    flowCandidates(FlowId, Candidates),
    bestCandidateForFlow(FlowId, Candidates, Alloc, NodeLoads, Carbon, Cost, NewAlloc, NewNodeLoads, NewCarbon, NewCost, FOut),
    bestCarbon(BestCarbon), bestCost(BestCost),
    checkBranch(BestCarbon, BestCost, NewCarbon, NewCost, RestFlows, NewNodeLoads),
    searchBest(state(NewAlloc, [FOut|Out], NewNodeLoads, NewCarbon, NewCost, RestFlows)).

checkBranch(BestCarbon, BestCost, Carbon, Cost, RestFlows, NodeLoads) :-
    pruneGuard(BestCarbon, BestCost, Carbon, Cost),
    !,
    once(lowerBound(RestFlows, Carbon, Cost, NodeLoads, LBCarbon, LBCost)),
    pruneGuard(BestCarbon, BestCost, LBCarbon, LBCost).

pruneGuard(BestCarbon, _, Carbon, _) :-
    Carbon > BestCarbon, !,
    fail.
pruneGuard(BestCarbon, BestCost, Carbon, Cost) :-
    Carbon =:= BestCarbon,
    Cost >= BestCost, !,
    fail.
pruneGuard(_, _, _, _).


upperBound(Out, Alloc, NodeLoads, TotalCarbon, EnergyCost) :-
    once(glbfCCG(Out, Alloc, NodeLoads, TotalCarbon, EnergyCost)).

updateInLoads(Node, Load, Old, New) :- incLoad(Node, Load, Old, New).
incLoad(Node, Delta, [], [(Node,Delta)]).
incLoad(Node, Delta, [(Node,Old)|T], [(Node,New)|T]) :- !, New is Old + Delta.
incLoad(Node, Delta, [(N1,V1)|T], [(N1,V1)|T2]) :- N1 @< Node, !, incLoad(Node, Delta, T, T2).
incLoad(Node, Delta, L, [(Node,Delta)|L]).

initGlobals :-
    infinity(Inf),
    nb_setval(best, best(Inf, Inf, [], [])),
    nb_setval(solutions_explored, 0).

setGlobalSolution(Out, Alloc, Carbon, Cost) :-
    nb_setval(best, best(Carbon, Cost, [solution(Out,Alloc)], [])).

setGlobalSolution(Out, Alloc, Carbon, Cost, NodeMetrics) :-
    nb_setval(best, best(Carbon, Cost, [solution(Out,Alloc)], NodeMetrics)).

updateBest(Out, Alloc, NodeMetrics, Carbon, NewCost) :-
    bestCarbon(BCarbon),
    bestCost(BCost),
    (   Carbon < BCarbon
    ;   Carbon =:= BCarbon, NewCost =< BCost
    ),
    !,
    setGlobalSolution(Out, Alloc, Carbon, NewCost, NodeMetrics).
updateBest(_,_,_,_,_).

evaluateFlowCandidates(FlowId, AllocIn, NodeLoads, CarbonIn, CostIn, Candidates) :-
    flowCandidates(FlowId, CandIds),
    evaluateCandidates(CandIds, FlowId, AllocIn, NodeLoads, CarbonIn, CostIn, Bests),
    predsort(bestCompare, Bests, SortedBests),
    findall((CandidateAlloc, CandidateLoads, CandidateCarbon, CandidateCost, CandidateFlow),
        member((CandidateCarbon, CandidateCost, CandidateAlloc, CandidateLoads, CandidateFlow), SortedBests),
        Candidates).

lowerBound(FlowIds, OldCarbon, OldCost, Loads, LBCarbon, LBCost) :-
    lowerbound(FlowIds, Loads, OldCarbon, OldCost, _, LBCarbon, LBCost).

lowerbound([FlowId|FlowIds], NodeLoads, Carbon, Cost, NewNodeLoads, NewCarbon, NewCost) :-
    bestCandidateLb(FlowId, NodeLoads, Carbon, Cost, TmpLoads, TmpCarbon, TmpCost),
    lowerbound(FlowIds, TmpLoads, TmpCarbon, TmpCost, NewNodeLoads, NewCarbon, NewCost).
lowerbound([], NodeLoads, Carbon, Cost, NodeLoads, Carbon, Cost).

bestCandidateLb(FlowId, NodeLoads, Carbon, Cost, NewNodeLoads, NewCarbon, NewCost) :-
    flowCandidates(FlowId, CandidateIds),
    CandidateIds \= [],
    dataReqs(FlowId, _, _, BitRate, _, _),
    evaluateCandidatesLB(CandidateIds, BitRate, NodeLoads, Carbon, Cost, (NewCarbon, NewCost, NewNodeLoads)).

evaluateCandidatesLB([First|Rest], BitRate, NodeLoads, Carbon, Cost, Best) :-
    evaluateCandidateLB(First, BitRate, NodeLoads, Carbon, Cost, Best0),
    evaluateCandidatesLB(Rest, BitRate, NodeLoads, Carbon, Cost, Best0, Best).
evaluateCandidatesLB([Cid|Rest], BitRate, NodeLoads, Carbon, Cost, AccBest, Best) :-
    evaluateCandidateLB(Cid, BitRate, NodeLoads, Carbon, Cost, Triple),
    better(Triple, AccBest, TmpBest),
    evaluateCandidatesLB(Rest, BitRate, NodeLoads, Carbon, Cost, TmpBest, Best).
evaluateCandidatesLB([], _, _, _, _, Best, Best).

evaluateCandidateLB(CandidateId, BitRate, NodeLoads, Carbon, Cost, (CandCarbon, CandCost, CandNodeLoads)) :-
    candidate(CandidateId, _, _, Path),
    update(Path, BitRate, [], _, NodeLoads, CandNodeLoads, Carbon, CandCarbon, Cost, CandCost).

better((C,K,L), (CB,KB,_), (C,K,L)) :-
    ( C < CB ; (C =:= CB, K < KB) ), !.
better(_, Best, Best).

bestCarbon(BCarbon) :-
    nb_getval(best, best(BCarbon, _, _, _)).
bestCost(BCost) :-
    nb_getval(best, best(_, BCost, _, _)).
