:-['src/utils.pl', 'src/pprint.pl'].
:- table transmissionTime/3.

:- set_prolog_flag(answer_write_options,[max_depth(0), spacing(next_argument)]).
:- set_prolog_flag(stack_limit, 64 000 000 000).
:- set_prolog_flag(last_call_optimisation, true).

glbf :- glbf(Paths, _), prettyPrint(Paths).

glbf(SPaths, Capacities) :-
    possiblePaths(PPaths, Capacities),
    validPaths(PPaths, Paths),
    predsort(sortPaths, Paths, SPaths). % sort by FlowId, then by Reliability

possiblePaths(Paths, Capacities) :-
    findall(FlowId, flow(FlowId, _, _), FlowIds),
    possiblePaths(FlowIds, Capacities, Paths).
    
validPaths(PPaths, Paths) :-
    findall((F,P,Path), member((F,P,(Path,_,_,_)),PPaths), Paths2),
    compatiblePaths(PPaths, Paths2, Paths).

possiblePaths(FlowIds, Alloc, Out) :- possiblePaths(FlowIds, [], Alloc, [], Out).
possiblePaths([FlowId|FlowIds], Alloc, NewAlloc, OldOut, Out) :-
    path(FlowId, Alloc, TmpAlloc, FOut),
    possiblePaths(FlowIds, TmpAlloc, NewAlloc, [FOut|OldOut], Out).
possiblePaths([], A, A, O, O).

path(FlowId, Alloc, NewAlloc, (FlowId, PId, (Path, Rel, NewMinB, Delay))) :-
    flow(FlowId, S, D), reliabilityReqs(FlowId, ReqRel, _),
    dataReqs(FlowId, PacketSize, _, BitRate, Budget, Th),
    MinB is Budget - Th,
    candidate(PId, S, D, Path),
    pathOk(Path, MinB, ReqRel, Alloc, PacketSize, BitRate, 1, Rel, NewMinB),
    delay(NewMinB, Path, Delay), updateCapacities(Path, BitRate, Alloc, NewAlloc).

pathOk([S,N|Rest], OldMinB, ReqRel, Alloc, PacketSize, BitRate, OldRel, NewRel, NewMinB) :-
    link(S, N, TProp, Bandwidth, FeatRel),
    reliabilityOk(OldRel, FeatRel, ReqRel, TmpRel),
    hopOk(S, N, TProp, Bandwidth, Alloc, PacketSize, BitRate, OldMinB, TmpMinB),
    pathOk([N|Rest], TmpMinB, ReqRel, Alloc, PacketSize, BitRate, TmpRel, NewRel, NewMinB).
pathOk([_], MinB, _, _, _, _, Rel, Rel, MinB).

reliabilityOk(PathRel, FeatRel, ReqRel, NewPathRel) :- NewPathRel is PathRel * FeatRel, NewPathRel >= ReqRel.

hopOk(S, N, TProp, Bandwidth, Alloc, PacketSize, BitRate, MinB, NewMinB) :- 
    node(N, MinNodeBudget), usedBandwidth(S, N, Alloc, UsedBW), Bandwidth > UsedBW + BitRate,
    transmissionTime(PacketSize, Bandwidth, TTime),
    NewMinB is MinB - MinNodeBudget - TProp - TTime.

transmissionTime(PacketSize, Bandwidth, TTime) :- TTime is PacketSize/Bandwidth.

delay(PathMinB, [_,_], Delay) :- Delay is PathMinB, !.
delay(PathMinB, Path, Delay) :- PathMinB > 0, length(Path, L), Hops is L-1, Delay is PathMinB/Hops.
delay(PathMinB, _, 0) :- PathMinB < 0.

compatiblePaths([(FlowId, PId, (P, R, MinB, D))|Fs], Paths, [(FlowId, PId, (P, R, (MinB,MaxB), D))|NewFs]) :-
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