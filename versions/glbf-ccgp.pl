:- ['../metrics/routerEnergy.pl', '../metrics/routerCarbon.pl', '../metrics/energyCost.pl', '../metrics/nodeLoad.pl'].
:- ['src/utils.pl', 'src/pprint.pl', 'src/carbon_credit_calc.pl', 'src/carbonAndCostUtils.pl'].
:- table transmissionTime/3.

:- set_prolog_flag(answer_write_options,[max_depth(0), spacing(next_argument)]).
:- set_prolog_flag(stack_limit, 64 000 000 000).
:- set_prolog_flag(last_call_optimisation, true).

infinity(1.0Inf).

glbfCCG(BudgetCost, Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, EnergyCost, TotalCost) :-
    glbfCCG(Out, Alloc, NodeLoads, TotalCarbon, EnergyCost),
    computeCarbonFootprintAndCosts(NodeLoads, NodesCarbonFootprintAndCosts),
    TotalCarbonInt is ceiling(TotalCarbon),
    carbonCreditCalculator(TotalCarbonInt, Solution, CarbonCreditCost),
    TotalCost is EnergyCost + CarbonCreditCost,
    TotalCost < BudgetCost.

glbfCCG(Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, EnergyCost, TotalCost) :-
    glbfCCG(1.0Inf, Out, Alloc, NodesCarbonFootprintAndCosts, TotalCarbon, Solution, EnergyCost, TotalCost).

glbfCCG(SPaths, Capacities, NodeLoads, Carbon, Cost) :-
    possiblePaths(PPaths, Capacities, NodeLoads, Carbon, Cost),
    validPaths(PPaths, SPaths).
    
possiblePaths(PPaths, Capacities, NodeLoads, Carbon, Cost) :-
    init(InitCarbon, InitCost),
    findall(FlowId, flow(FlowId, _, _), FlowIds),
    possiblePaths(FlowIds, [], Capacities, [], NodeLoads, InitCarbon, Carbon, InitCost, Cost, [], PPaths).
    
validPaths(PPaths, Paths) :-
    findall((F,P,Path), member((F,P,Path,_,_),PPaths), Paths2),
    compatiblePaths(PPaths, Paths2, Paths).

possiblePaths([], Alloc, Alloc, NodeLoads, NodeLoads, Carbon, Carbon, Cost, Cost, Out, Out).
possiblePaths([FlowId|FlowIds], Alloc, NewAlloc, NodeLoads, NewNodeLoads, Carbon, NewCarbon, Cost, NewCost, OldOut, Out) :-
    path(FlowId, Alloc, NodeLoads, Carbon, Cost, TmpAlloc, TmpLoads, TmpCarbon, TmpCost, FOut),
    possiblePaths(FlowIds, TmpAlloc, NewAlloc, TmpLoads, NewNodeLoads, TmpCarbon, NewCarbon, TmpCost, NewCost, [FOut|OldOut], Out).

path(FlowId, Alloc, NodeLoads, Carbon, Cost, NewAlloc, NewNodeLoads, NewCarbon, NewCost, (FlowId, PId, Path, NewMinB, Delay)) :-
    flow(FlowId, S, D),
    dataReqs(FlowId, PacketSize, _, BitRate, Budget, Th),
    MinB is Budget - Th,
    candidate(PId, S, D, Path),
    pathOk(Path, MinB, Alloc, PacketSize, BitRate, NewMinB),
    delay(NewMinB, Path, Delay), 
    update(Path, BitRate, Alloc, NewAlloc, NodeLoads, NewNodeLoads, Carbon, NewCarbon, Cost, NewCost).

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

update([_], _, Alloc, Alloc, NodeLoads, NodeLoads, Carbon, Carbon, Cost, Cost).
update([S, D | Path], Bandwidth, Alloc, NewAlloc, NodeLoads, NewLoads, Carbon, NewCarbon, Cost, NewCost) :-
    updateEdge(S, D, Bandwidth, Alloc, TmpAlloc),
    routerLoad(S, NodeLoads, OldLoad),
    updateLoad(S, Bandwidth, NodeLoads, TmpLoads),
    routerLoad(S, TmpLoads, NewLoad),
    recomputeCarbonAndCostFromLoads(S, Carbon, Cost, OldLoad, NewLoad, TmpCarbon, TmpCost),
    update([D | Path], Bandwidth, TmpAlloc, NewAlloc, TmpLoads, NewLoads, TmpCarbon, NewCarbon, TmpCost, NewCost).

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

recomputeCarbonAndCostFromLoads(Node, Carbon, Cost, L0, L1, NewCarbon, NewCost) :-
    routerCarbonCost(Node, L0, C0, K0),
    routerCarbonCost(Node, L1, C1, K1),
    NewCarbon is Carbon - C0 + C1,
    NewCost   is Cost   - K0 + K1.