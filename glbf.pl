:-['src/utils.pl'].
:- table transmissionTime/3.
:-['sim/data/flows/flows50.pl', 'sim/data/infrastructures/infr100.pl'].

:- set_prolog_flag(answer_write_options,[max_depth(0), spacing(next_argument)]).
:- set_prolog_flag(stack_limit, 64 000 000 000).
:- set_prolog_flag(last_call_optimisation, true).

glbf(Paths, Capacities) :-
    possiblePaths(PPaths, Capacities),
    validPaths(PPaths, Paths).
    
possiblePaths(Paths, Capacities) :-
    findall(FlowId, flow(FlowId, _, _), FlowIds),
    possiblePaths(FlowIds, Capacities, Paths).
    
validPaths(PPaths, Paths) :-
    findall((F,Path), member((F,(Path,_,_)),PPaths), Paths2),
    compatiblePaths(PPaths, Paths2, Paths).

possiblePaths(FlowIds, Alloc, Out) :- possiblePaths(FlowIds, [], Alloc, [], Out).
possiblePaths([FlowId|FlowIds], Alloc, NewAlloc, OldOut, Out) :-
    flow(FlowId, S, D), reliabilityReqs(FlowId, _, Rep),
    findall(1, candidate(_, S, D, _), Cs), length(Cs, L), L >= Rep, % too few candidate paths
    replicas(FlowId, Rep, Alloc, TmpAlloc, [], OldOut, FOut),
    possiblePaths(FlowIds, TmpAlloc, NewAlloc, FOut, Out).    
possiblePaths([], Alloc, Alloc, Out, Out).

replicas(FlowId, N, Alloc, NewAlloc, PIds, OldOut, Out) :-
    N > 0, possiblePath(FlowId, Alloc, TmpAlloc, PId, PIds, OldOut, FOut),
    N1 is N-1, replicas(FlowId, N1, TmpAlloc, NewAlloc, [PId|PIds], [(FlowId, PId, FOut)|OldOut], Out).
replicas(_, 0, Alloc, Alloc, _, Out, Out). % N == 0. 

possiblePath(FlowId, Alloc, NewAlloc, PId, PIds, Out, (Path, NewMinB, Delay)) :-
    flow(FlowId, S, D), reliabilityReqs(FlowId, Rel, _),
    dataReqs(FlowId, PacketSize, _, BitRate, Budget, Th),
    validCandidate(FlowId, (S,D), PId, Path, PIds, Out),
    MinB is Budget - Th,
    path(Path, MinB, Rel, Alloc, PacketSize, BitRate, 1, NewMinB),
    delay(NewMinB, Path, Delay), updateCapacities(Path, BitRate, Alloc, NewAlloc).

validCandidate(FId, (S,D), PId, CPath, PIds, Out) :- 
    candidate(PId, S, D, CPath), \+ member(PId, PIds),
    pathProtection(CPath, PIds), 
    noFateSharing(FId, CPath, Out).

noFateSharing(FId, CPath, Out) :-
    findall(AFP, (antiAffinity(FId, Fs), member(F, Fs), member((F,_,AFP,_,_), Out)), AFPs),
    noFateSharing(CPath, AFPs).

pathProtection(SPD, PIds) :- intermediateNodes(SPD, P), noIntersections(P, PIds).

noIntersections(P, PIds) :- 
    \+ (member(PId, PIds), candidate(PId,_, _, P1), intermediateNodes(P1, FP), 
    intersection(FP, P, [_|_])).

path([S,N|Rest], OldMinB, ReqRel, Alloc, PacketSize, BitRate, PathRel, NewMinB) :-
    link(S, N, TProp, Bandwidth, FeatRel),
    NewPathRel is PathRel * FeatRel, NewPathRel >= ReqRel,
    hopOK(N, TProp, Bandwidth, Alloc, PacketSize, BitRate, OldMinB, TmpMinB),
    path([N|Rest], TmpMinB, ReqRel, Alloc, PacketSize, BitRate, NewPathRel, NewMinB).
path([_], MinB, _, _, _, _, _, MinB).

hopOK(N, TProp, Bandwidth, Alloc, PacketSize, BitRate, MinB, NewMinB) :- 
    node(N, MinNodeBudget), usedBandwidth(N, _, Alloc, UsedBW), Bandwidth > UsedBW + BitRate,
    transmissionTime(PacketSize, Bandwidth, TTime),
    NewMinB is MinB - MinNodeBudget - TProp - TTime.

transmissionTime(PacketSize, Bandwidth, TTime) :- TTime is PacketSize/Bandwidth.

delay(PathMinB, [_,_], Delay) :- Delay is PathMinB, !.
delay(PathMinB, Path, Delay) :- PathMinB > 0, length(Path, L), Hops is L-1, Delay is PathMinB/Hops.
delay(PathMinB, _, 0) :- PathMinB < 0.

compatiblePaths([(FlowId, PId, (P, MinB, D))|Fs], Paths, [(FlowId, PId, (P, (MinB,MaxB), D))|NewFs]) :-
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
    dataReqs(F,P,B,_,_,_), PB is P * B.

noFateSharing(CPath, [AFPath|AFPs]) :- intersection(CPath, AFPath, []), noFateSharing(CPath, AFPs).
noFateSharing(_, []).
    
