:-['data.pl'].

:- set_prolog_flag(answer_write_options,[max_depth(0), spacing(next_argument)]).
:- set_prolog_flag(stack_limit, 64 000 000 000).
:- set_prolog_flag(last_call_optimisation, true).

placeFlow(FlowId, (Path, B, Delay)) :-
    flow(FlowId, S, D, PacketSize, BurstSize, BitRate, Budget, Th),
    MinB is Budget - Th, MaxB is Budget + Th,
    path(S, D, (MinB,MaxB), PacketSize, BurstSize, BitRate, [], (B,Path)),
    delay((B,Path), Delay), updateFlows(Path, FlowId), !.

updateFlows([N|Ns], FlowId) :- flowsAt(N, Flows), retract(flowsAt(N, Flows)), assert(flowsAt(N, [FlowId|Flows])), updateFlows(Ns, FlowId).
updateFlows([], _).

delay((B,Path), Delay) :-
    B = (PathMinB, _), PathMinB > 0, length(Path, L), Hops is L-1,
    Delay is PathMinB/Hops.
delay((B,_), 0) :- B = (PathMinB, _), PathMinB < 0.

path(S, D, (MinB,MaxB), PacketSize, BurstSize, BitRate, OldPath, NewPath) :-
    dif(S, D), link(S, N, TProp, Bandwidth), \+ member(N, OldPath), 
    node(N, MinNodeBudget), Bandwidth > BitRate,
    transmissionTime(PacketSize, Bandwidth, TTime),
    queuingTime(N, PacketSize, BurstSize, Bandwidth, QTime), writeln(QTime),
    NewMinB is MinB - MinNodeBudget - TProp - TTime, 
    NewMaxB is MaxB - MinNodeBudget - QTime - TProp - TTime, NewMaxB > 0,
    path(N, D, (NewMinB,NewMaxB), PacketSize, BurstSize, BitRate, [S|OldPath], NewPath).
path(D, D, Budget, _, _, _, P, (Budget,FP)) :- reverse([D|P],FP).

/* maximum queuing time is the time taken to serialize the sum of the bursts of all flows
   except for one packet of the current flow */
/* minimum queuing time is 0. */
queuingTime(N, PacketSize, BurstSize, Bandwidth, QTime) :-
    flowsAt(N, Flows), dif(Flows, []),
    findall(PB, (member(F,Flows), flow(F,_,_,_,P,B,_,_), PB is P * B ), PBs), sumlist(PBs, Sum),
    QTime is (((BurstSize - 1) * PacketSize) + Sum)/Bandwidth.
queuingTime(N, _, _, _, 0) :- flowsAt(N, []).

transmissionTime(PacketSize, Bandwidth, TTime) :-
    TTime is PacketSize/Bandwidth.


    