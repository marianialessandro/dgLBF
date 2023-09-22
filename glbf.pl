:-['utils.pl', 'data.pl'].

:- set_prolog_flag(answer_write_options,[max_depth(0), spacing(next_argument)]).
:- set_prolog_flag(stack_limit, 64 000 000 000).
:- set_prolog_flag(last_call_optimisation, true).

glbf(Out, Alloc) :- 
    findall(FlowId, flow(FlowId, _, _, _, _, _, _, _), FlowIds),
    placeFlows(FlowIds, [], Alloc, [], Out).

placeFlows([FlowId|FlowIds], Alloc, NewAlloc, OldOut, Out) :-
    placeFlow(FlowId, Alloc, TmpAlloc, FOut), !,
    placeFlows(FlowIds, TmpAlloc, NewAlloc, [(FlowId, FOut)|OldOut], Out).
placeFlows([], Alloc, Alloc, Out, Out).

placeFlow(FlowId, Alloc, NewAlloc, (Path, B, Delay)) :-
    flow(FlowId, S, D, PacketSize, BurstSize, BitRate, Budget, Th),
    MinB is Budget - Th, MaxB is Budget + Th,
    path(S, D, (MinB,MaxB), Alloc, PacketSize, BurstSize, BitRate, [], (B,Path)),
    delay((B,Path), Delay), updateFlows(Path, FlowId), updateCapacities(Path, BitRate, Alloc, NewAlloc).

path(S, D, (MinB,MaxB), Alloc, PacketSize, BurstSize, BitRate, OldPath, NewPath) :-
    dif(S, D), link(S, N, TProp, Bandwidth), \+ member(N, OldPath), 
    node(N, MinNodeBudget), capacity(S, N, Alloc, Capacity), Bandwidth > Capacity + BitRate,
    transmissionTime(PacketSize, Bandwidth, TTime),
    queuingTime(N, PacketSize, BurstSize, Bandwidth, QTime),
    NewMinB is MinB - MinNodeBudget - TProp - TTime, 
    NewMaxB is MaxB - MinNodeBudget - QTime - TProp - TTime, NewMaxB > 0,
    path(N, D, (NewMinB,NewMaxB), Alloc, PacketSize, BurstSize, BitRate, [S|OldPath], NewPath).
path(D, D, Budget, _, _, _, _, P, (Budget,FP)) :- reverse([D|P],FP).

/* maximum queuing time is the time taken to serialize the sum of the bursts of all flows
   except for one packet of the current flow */
/* minimum queuing time is 0. */ % TODO: check this, now removed
queuingTime(N, PacketSize, BurstSize, Bandwidth, QTime) :-
    flowsAt(N, Flows), % dif(Flows, []),
    findall(PB, (member(F,Flows), flow(F,_,_,_,P,B,_,_), PB is P * B ), PBs), sumlist(PBs, Sum),
    QTime is (((BurstSize - 1) * PacketSize) + Sum)/Bandwidth.
% queuingTime(N, _, _, _, 0) :- flowsAt(N, []).

transmissionTime(PacketSize, Bandwidth, TTime) :-
    TTime is PacketSize/Bandwidth.


    