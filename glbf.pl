:-['src/utils.pl'].
%:-['sim/data/flows/flows10.pl', 'sim/data/infrastructures/infr64.pl'].


:- set_prolog_flag(answer_write_options,[max_depth(0), spacing(next_argument)]).
:- set_prolog_flag(stack_limit, 64 000 000 000).
:- set_prolog_flag(last_call_optimisation, true).

glbf(Out, Alloc) :- 
    findall(FlowId, flow(FlowId, _, _, _, _, _, _, _), FlowIds), 
    placeFlows(FlowIds, Alloc, TmpOut),
    findall((F,Path), member((F,(Path,_,_)),TmpOut), Paths),
    queuingTimesOk(TmpOut, Paths, Out).

placeFlows(FlowIds, Alloc, Out) :- placeFlows(FlowIds, [], Alloc, [], Out).
placeFlows([FlowId|FlowIds], Alloc, NewAlloc, OldOut, Out) :-
    placeFlow(FlowId, Alloc, TmpAlloc, FOut),
    placeFlows(FlowIds, TmpAlloc, NewAlloc, [(FlowId, FOut)|OldOut], Out).
placeFlows([], Alloc, Alloc, Out, Out).

placeFlow(FlowId, Alloc, NewAlloc, (Path, NewMinB, Delay)) :-
    flow(FlowId, S, D, PacketSize, BurstSize, BitRate, Budget, Th),
    MinB is Budget - Th,
    path(S, D, MinB, Alloc, PacketSize, BurstSize, BitRate, [], (NewMinB,Path)),
    delay(NewMinB, Path, Delay), updateCapacities(Path, BitRate, Alloc, NewAlloc).

path(S, D, MinB, Alloc, PacketSize, BurstSize, BitRate, OldPath, NewPath) :-
    dif(S, D), rankedLinks(S, RankedLinks), 
    member(link(S, N, TProp, Bandwidth), RankedLinks), \+ member(N, OldPath), 
    node(S, MinNodeBudget), usedBandwidth(S, N, Alloc, UsedBW), Bandwidth > UsedBW + BitRate,
    transmissionTime(PacketSize, Bandwidth, TTime),
    NewMinB is MinB - MinNodeBudget - TProp - TTime, 
    path(N, D, NewMinB, Alloc, PacketSize, BurstSize, BitRate, [S|OldPath], NewPath).
path(D, D, Budget, _, _, _, _, P, (Budget,FP)) :- reverse([D|P],FP).

transmissionTime(PacketSize, Bandwidth, TTime) :- TTime is PacketSize/Bandwidth.

delay(PathMinB, Path, Delay) :- PathMinB > 0, length(Path, L), Hops is L-1, Delay is PathMinB/Hops.
delay(PathMinB, _, 0) :- PathMinB < 0.

queuingTimesOk([(FlowId, (P, MinB, D))|Fs], Paths, [(FlowId, (P, (MinB,MaxB), D))|NewFs]) :-
    flow(FlowId, _, _, PacketSize, BurstSize, _, _, Th), 
    totQTime(P, FlowId, PacketSize, BurstSize, Paths, TotQTime),
    MaxB is MinB + 2*Th - TotQTime, MaxB >= 0,
    queuingTimesOk(Fs, Paths, NewFs).
queuingTimesOk([], _, []).

totQTime([S,D|Path], FId, PacketSize, BurstSize, Paths, TotQTime) :-
    link(S, D, _, Bandwidth),
    findall(PB, relevantFlow(FId, S, Paths, PB), PBs), sumlist(PBs, Sum),
    QTime is (((BurstSize - 1) * PacketSize) + Sum)/Bandwidth,
    totQTime([D|Path], FId, PacketSize, BurstSize, Paths, TmpQTime),
    TotQTime is QTime + TmpQTime.
totQTime([_], _, _, _, _, 0).

relevantFlow(CurrF, N, Paths, PB) :-
    dif(F, CurrF), member((F,Path),Paths), member(N, Path),
    flow(F,_,_,P,B,_,_,_), PB is P * B.