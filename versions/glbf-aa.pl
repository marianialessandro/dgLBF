:-['src/utils.pl', 'src/pprint.pl'].
:- table transmissionTime/3.
:- dynamic antiAffinity/2.

% :-['./src/sample-data.pl'].
:-['../sim/data/flows/flows-cev.pl', '../sim/data/infrastructures/infr-cev.pl'].

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
    possiblePaths(FlowIds, Capacities, Paths), dif(Paths, []).
possiblePaths(_, Capacities) :-
    findall(FlowId, flow(FlowId, _, _), FlowIds),
    possiblePaths(FlowIds, Capacities, []),!,fail.
    
validPaths(PPaths, Paths) :-
    findall((F,P,Path), member((F,P,(Path,_,_,_)),PPaths), Paths2),
    compatiblePaths(PPaths, Paths2, Paths).

possiblePaths(FlowIds, Alloc, Out) :- possiblePaths(FlowIds, [], Alloc, [], Out).
possiblePaths([FlowId|FlowIds], Alloc, NewAlloc, OldOut, Out) :-
    path(FlowId, Alloc, TmpAlloc, OldOut, FOut),
    possiblePaths(FlowIds, TmpAlloc, NewAlloc, FOut, Out).
possiblePaths([], Alloc, Alloc, Out, Out).

enoughCandidatePaths(S, D, 1):- candidate(_, S, D, _), !.
enoughCandidatePaths(S, D, 2) :-
    candidate(PId1, S, D, P1), candidate(PId2, S, D, P2), dif(PId1, PId2),
    intermediateNodes(P1, N1), intermediateNodes(P2, N2), intersection(N1, N2, []), !.

path(FlowId, Alloc, NewAlloc, Out, [(FlowId, PId, (Path, Rel, NewMinB, Delay))|Out]) :-
    flow(FlowId, S, D), reliabilityReqs(FlowId, ReqRel, _),
    dataReqs(FlowId, PacketSize, _, BitRate, Budget, Th),
    validCandidate(FlowId, (S,D), PId, Path, Out),
    MinB is Budget - Th,
    pathOk(Path, MinB, ReqRel, Alloc, PacketSize, BitRate, 1, Rel, NewMinB),
    delay(NewMinB, Path, Delay), updateCapacities(Path, BitRate, Alloc, NewAlloc).

validCandidate(FId, (S,D), PId, CPath, Out) :- 
    candidate(PId, S, D, CPath),
    noFateSharing(FId, CPath, Out).

noFateSharing(FId, CPath, Out) :-
    findall(AFP, (antiAffinity(FId, Fs), member(F, Fs), member((F,_,AFP,_,_), Out)), AFPs),
    noFateSharing(CPath, AFPs).

noFateSharing(CPath, [AFPath|AFPs]) :- 
    sharedFirstAndLast(CPath, AFPath, C, AF), intersection(C, AF, []), 
    noFateSharing(CPath, AFPs).
noFateSharing(_, []).

pathOk([S,N|Rest], OldMinB, ReqRel, Alloc, PacketSize, BitRate, OldRel, NewRel, NewMinB) :-
    link(S, N, TProp, Bandwidth, FeatRel),
    reliabilityOk(OldRel, FeatRel, ReqRel, TmpRel),
    hopOk(N, TProp, Bandwidth, Alloc, PacketSize, BitRate, OldMinB, TmpMinB),
    pathOk([N|Rest], TmpMinB, ReqRel, Alloc, PacketSize, BitRate, TmpRel, NewRel, NewMinB).
pathOk([_], MinB, _, _, _, _, Rel, Rel, MinB).

reliabilityOk(_, _, _, 1).

hopOk(N, TProp, Bandwidth, Alloc, PacketSize, BitRate, MinB, NewMinB) :- 
    node(N, MinNodeBudget), usedBandwidth(N, _, Alloc, UsedBW), Bandwidth > UsedBW + BitRate,
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