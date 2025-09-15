:- ['../metrics/routerEnergy.pl', '../metrics/routerCarbon.pl', '../metrics/energyCost.pl', '../metrics/nodeLoad.pl'].
:- ['src/utils.pl', 'src/pprint.pl', 'src/carbon_credit_calc.pl', 'src/carbonAndCostUtils.pl'].

:- set_prolog_flag(answer_write_options,[max_depth(0), spacing(next_argument)]).
:- set_prolog_flag(stack_limit, 64 000 000 000).
:- set_prolog_flag(last_call_optimisation, true).

glbfCCG(BudgetCost, Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost) :-
    glbfCCG(Out, Alloc, NodeLoads, TotalCarbonFloat, EnergyCost),
    computeCarbonFootprintAndCosts(NodeLoads, NodesCarbonFootprintAndCosts),
    TotalCarbon is ceiling(TotalCarbonFloat),
    carbonCreditCalculator(TotalCarbon, Solution, CarbonCreditCost),
    TotalCost is EnergyCost + CarbonCreditCost,
    TotalCost < BudgetCost.

glbfCCG(Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost) :-
    glbfCCG(1.0Inf, Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, TotalCost).

glbfCCG(SPaths, Capacities, Loads, Carbon, Cost) :-
    possiblePaths(PPaths, Capacities, Loads, Carbon, Cost),
    validPaths(PPaths, SPaths).
    
validPaths(PPaths, Paths) :-
    findall((F,P,Path), member((F,P,Path,_,_),PPaths), Paths2),
    compatiblePaths(PPaths, Paths2, Paths).

flowCandidates(FlowId, Candidates):-
    flow_candidates(FlowId, Candidates).

flowOrdered(FlowIds) :-
    allFlows(F0),
    predsort(byBitrateDesc, F0, FlowIds).

byBitrateDesc(Order, F1, F2) :-
    dataReqs(F1, _, _, B1, _, _),
    dataReqs(F2, _, _, B2, _, _),
    NB1 is -B1,
    NB2 is -B2,
    compare(Order, key(NB1, F1), key(NB2, F2)).

possiblePaths(Paths, Capacities, Loads, Carbon, Cost) :-
    flowOrdered(FlowIds),
    init(InitCarbon, InitCost),
    possiblePaths(FlowIds, [], Capacities, [], Loads, InitCarbon, Carbon, InitCost, Cost, [], Paths).

possiblePaths([FlowId|FlowIds], AllocIn, AllocOut, LoadsIn, LoadsOut, CarbonIn, CarbonOut, CostIn, CostOut, OldOut, Out) :-
    flowCandidates(FlowId, Candidates),
    bestCandidateForFlow(FlowId, Candidates, AllocIn, LoadsIn, CarbonIn, CostIn, TmpAlloc, TmpLoads, TmpCarbon, TmpCost, FOut),
    possiblePaths(FlowIds, TmpAlloc, AllocOut, TmpLoads, LoadsOut, TmpCarbon, CarbonOut, TmpCost, CostOut, [FOut|OldOut], Out).
possiblePaths([], Alloc, Alloc, Loads, Loads, Carbon, Carbon, Cost, Cost, Out, Out).

bestCandidateForFlow(FlowId, Candidates, AllocIn, LoadsIn, CarbonIn, CostIn, AllocOut, LoadsOut, CarbonOut, CostOut, BestOut) :-
    bestsCandidates(Candidates, FlowId, AllocIn, LoadsIn, CarbonIn, CostIn, Bests),
    Bests = [_|_],
    predsort(bestCompare, Bests, Sorted),
    member(best(CarbonOut, CostOut, AllocOut, LoadsOut, BestOut), Sorted).

bestsCandidates([], _, _, _, _, _, []) .
bestsCandidates([PId|Ps], FlowId, AllocIn, LoadsIn, CarbonIn, CostIn, [best(Carbon, Cost, Alloc, Loads, Out)|Rest]) :-
    path(FlowId, PId, AllocIn, LoadsIn, CarbonIn, CostIn, Alloc, Loads, Carbon, Cost, Out),
    bestsCandidates(Ps, FlowId, AllocIn, LoadsIn, CarbonIn, CostIn, Rest).
bestsCandidates([PId|Ps], FlowId, AllocIn, LoadsIn, CarbonIn, CostIn, Rest) :-
    \+ path(FlowId, PId, AllocIn, LoadsIn, CarbonIn, CostIn, _Alloc, _Loads, _Carbon, _Cost, _Out),
    bestsCandidates(Ps, FlowId, AllocIn, LoadsIn, CarbonIn, CostIn, Rest).

bestCompare(Order, best(Carbon, Cost1, _, _, _), best(Carbon, Cost2, _, _, _)) :-
    compare(Order, Cost1, Cost2).
bestCompare(Order, best(Carbon1, _, _, _, _), best(Carbon2, _, _, _, _)) :-
    Carbon1 \= Carbon2,
    compare(Order, Carbon1, Carbon2).

path(FlowId, PId, AllocIn, LoadsIn, CarbonIn, CostIn, AllocOut, LoadsOut, CarbonOut, CostOut, (FlowId, PId, Path, NewMinB, Delay)) :-
    flow(FlowId, S, D),
    dataReqs(FlowId, PacketSize, _, BitRate, Budget, Th),
    MinB is Budget - Th,
    candidate(PId, S, D, Path),
    pathOk(Path, MinB, AllocIn, PacketSize, BitRate, NewMinB),
    delay(NewMinB, Path, Delay),
    update(Path, BitRate, AllocIn, AllocOut, LoadsIn, LoadsOut, CarbonIn, CarbonOut, CostIn, CostOut).

pathOk([S,N|Rest], OldMinB, Alloc, PacketSize, BitRate, NewMinB) :-
    link(S, N, TProp, Bandwidth, _),
    hopOk(S, N, TProp, Bandwidth, Alloc, PacketSize, BitRate, OldMinB, TmpMinB),
    pathOk([N|Rest], TmpMinB, Alloc, PacketSize, BitRate, NewMinB).
pathOk([_], MinB, _, _, _, MinB).

hopOk(S, N, TProp, Bandwidth, Alloc, PacketSize, BitRate, MinB, NewMinB) :- 
    node(N, MinNodeBudget), usedBandwidth(S, N, Alloc, UsedBW), Bandwidth > UsedBW + BitRate,
    transmissionTime(PacketSize, Bandwidth, TTime),
    NewMinB is MinB - MinNodeBudget - TProp - TTime.

transmissionTime(PacketSize, Bandwidth, TTime) :- TTime is PacketSize/Bandwidth.

delay(PathMinB, [_,_], Delay) :- Delay is PathMinB, !.
delay(PathMinB, Path, Delay) :- PathMinB > 0, length(Path, L), Hops is L-1, Delay is PathMinB/Hops.
delay(PathMinB, _, 0) :- PathMinB < 0.

compatiblePaths([(FlowId, PId, P, MinB, D)|Fs], Paths, [(FlowId, PId, P, (MinB,MaxB), D)|NewFs]) :-
    dataReqs(FlowId, PacketSize, BurstSize, _, _, Th), 
    totQTime(P, FlowId, PId, PacketSize, BurstSize, Paths, TotQTime),
    MaxB is MinB + 2*Th - TotQTime, MaxB >= 0,
    compatiblePaths(Fs, Paths, NewFs).
compatiblePaths([], _, []).

totQTime([S,D|Path], FId, PId, PacketSize, BurstSize, Paths, TotQTime) :-
    link(S, D, _, Bandwidth, _),
    findall(PB, relevantFlow(FId, PId, S, Paths, PB), PBs), sumlist(PBs, Sum),
    QTime is (((BurstSize - 1) * PacketSize) + Sum)/Bandwidth,
    totQTime([D|Path], FId, PId, PacketSize, BurstSize, Paths, TmpQTime),
    TotQTime is QTime + TmpQTime.
totQTime([_], _, _, _, _, _, 0).

relevantFlow(CurrF, CurrP, N, Paths, PB) :-
    dif((F,P), (CurrF,CurrP)), member((F,P,Path),Paths), member(N, Path),
    dataReqs(F,PS,BR,_,_,_), PB is PS * BR.

update([_], _, Alloc, Alloc, Loads, Loads, Carbon, Carbon, Cost, Cost).
update([S,N|Rest], BW, AllocIn, AllocOut, LoadsIn, LoadsOut, CarbonIn, CarbonOut, CostIn, CostOut) :-
    routerLoad(S, LoadsIn, LS0),
    routerLoad(N, LoadsIn, LN0),
    routerCarbonCost(S, LS0, CS0, KS0),
    routerCarbonCost(N, LN0, CN0, KN0),
    updateEdge(S, N, BW, AllocIn, Alloc1),
    updateLoad(S, BW, LoadsIn, L1),
    updateLoad(N, BW, L1, L2),
    routerLoad(S, L2, LS1),
    routerLoad(N, L2, LN1),
    routerCarbonCost(S, LS1, CS1, KS1),
    routerCarbonCost(N, LN1, CN1, KN1),
    CarbonStep is CarbonIn - CS0 - CN0 + CS1 + CN1,
    CostStep   is CostIn   - KS0 - KN0 + KS1 + KN1,
    update([N|Rest], BW, Alloc1, AllocOut, L2, LoadsOut, CarbonStep, CarbonOut, CostStep, CostOut).

updateEdge(S, N, BW, AllocIn, [(S,N,NewC)|Rest]) :-
    select((S,N,OldC), AllocIn, Rest), !,
    NewC is OldC + BW.
updateEdge(S, N, BW, AllocIn, [(S,N,BW)|AllocIn]).

updateLoad(Node, Delta, [], [(Node, Delta)]).
updateLoad(Node, Delta, [(Node,L)|T], [(Node,L1)|T]) :- !,
    L1 is L + Delta.
updateLoad(Node, Delta, [H|T], [H|T1]) :-
    H = (N,_), N \= Node,
    updateLoad(Node, Delta, T, T1).

init(InitCarbon, InitCost) :-
    allNodes(Nodes),
    init(Nodes, 0, 0, InitCarbon, InitCost).
init([], Carbon, Cost, Carbon, Cost).
init([Node|Nodes], Carbon, Cost, NewCarbon, NewCost) :-
    routerLoad(Node, [], NodeLoad),
    routerCarbon(Node, NodeLoad, RouterCarbon),
    routerCost(Node, NodeLoad, RouterCost),
    TmpCarbon is Carbon + RouterCarbon,
    TmpCost is Cost + RouterCost,
    init(Nodes, TmpCarbon, TmpCost, NewCarbon, NewCost).