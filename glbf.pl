:-['src/utils.pl'].
:- table transmissionTime/3.
%:-['sim/data/flows/flows20.pl', 'sim/data/infrastructures/infr20.pl'].

:- set_prolog_flag(answer_write_options,[max_depth(0), spacing(next_argument)]).
:- set_prolog_flag(stack_limit, 64 000 000 000).
:- set_prolog_flag(last_call_optimisation, true).

glbf(Paths, Capacities) :-
    possiblePaths(PPaths, Capacities),
    validPaths(PPaths, Paths).
    
possiblePaths(Paths, Capacities) :-
    findall(FlowId, flow(FlowId, _, _, _, _, _, _, _, _, _), FlowIds),
    possiblePaths(FlowIds, Capacities, Paths).
    
validPaths(PPaths, Paths) :-
    findall((F,Path), member((F,(Path,_,_)),PPaths), Paths2),
    compatiblePaths(PPaths, Paths2, Paths).

possiblePaths(FlowIds, Alloc, Out) :- possiblePaths(FlowIds, [], Alloc, [], Out).
possiblePaths([FlowId|FlowIds], Alloc, NewAlloc, OldOut, Out) :-
    flow(FlowId, _, _, _, _, _, _, _, _, Rep),
    findall(1, candidate((FlowId, _), _), Cs), length(Cs, L), L >= Rep, % too few candidates
    replicas(FlowId, Rep, Alloc, TmpAlloc, [], OldOut, FOut),
    possiblePaths(FlowIds, TmpAlloc, NewAlloc, FOut, Out).    
possiblePaths([], Alloc, Alloc, Out, Out).

replicas(FlowId, N, Alloc, NewAlloc, PIds, OldOut, Out) :-
    N > 0, possiblePath(FlowId, Alloc, TmpAlloc, PId, PIds, FOut),
    N1 is N-1, replicas(FlowId, N1, TmpAlloc, NewAlloc, [PId|PIds], [(FlowId, PId, FOut)|OldOut], Out).
replicas(_, 0, Alloc, Alloc, _, Out, Out). % N == 0. 

possiblePath(FlowId, Alloc, NewAlloc, PId, PIds, (Path, NewMinB, Delay)) :-
    flow(FlowId, _, _, PacketSize, _, BitRate, Budget, Th, Rel, _),
    MinB is Budget - Th,
    candidate((FlowId, PId), CPath), \+ member(PId, PIds),
    path(CPath, MinB, Rel, Alloc, PacketSize, BitRate, 1, NewMinB),
    delay(NewMinB, CPath, Delay), updateCapacities(CPath, BitRate, Alloc, NewAlloc),
    flatPath(CPath, Path).
possiblePath(FlowId, _, _, _, _, ([], -1, 0)) :-
    \+ candidate((FlowId, _), _), !.

path([(S, N)|Rest], OldMinB, ReqRel, Alloc, PacketSize, BitRate, PathRel, NewMinB) :-
    link(S, N, TProp, Bandwidth, FeatRel),
    NewPathRel is PathRel * FeatRel, NewPathRel >= ReqRel,
    hopOK(N, TProp, Bandwidth, Alloc, PacketSize, BitRate, OldMinB, TmpMinB),
    path(Rest, TmpMinB, ReqRel, Alloc, PacketSize, BitRate, NewPathRel, NewMinB).
path([], MinB, _, _, _, _, _, MinB).

hopOK(N, TProp, Bandwidth, Alloc, PacketSize, BitRate, MinB, NewMinB) :- 
    node(N, MinNodeBudget), usedBandwidth(N, _, Alloc, UsedBW), Bandwidth > UsedBW + BitRate,
    transmissionTime(PacketSize, Bandwidth, TTime),
    NewMinB is MinB - MinNodeBudget - TProp - TTime.

transmissionTime(PacketSize, Bandwidth, TTime) :- TTime is PacketSize/Bandwidth.

delay(PathMinB, [(_,_)], Delay) :- Delay is PathMinB, !.
delay(PathMinB, Path, Delay) :- PathMinB > 0, length(Path, L), Hops is L-1, Delay is PathMinB/Hops.
delay(PathMinB, _, 0) :- PathMinB < 0.

compatiblePaths([(FlowId, PId, (P, MinB, D))|Fs], Paths, [(FlowId, PId, (P, (MinB,MaxB), D))|NewFs]) :-
    flow(FlowId, _, _, PacketSize, BurstSize, _, _, Th, _, _), 
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
    dif(F, CurrF), dif(P, CurrP), member((F,P,Path),Paths), member(N, Path),
    flow(F,_,_,P,B,_,_,_,_,_), PB is P * B.