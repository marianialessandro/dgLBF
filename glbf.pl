:- set_prolog_flag(answer_write_options,[max_depth(0), spacing(next_argument)]).
:- set_prolog_flag(stack_limit, 64 000 000 000).
:- set_prolog_flag(last_call_optimisation, true).

placeFlow(FlowId, Path) :-
    flow(FlowId, S, D, PacketSize, BurstSize, BitRate, Budget, _),
    % MinLat = E2ELat - Th, MaxLat = E2ELat + Th,
    goodPath(S, D, Budget, PacketSize, BurstSize, BitRate, [], Path).

goodPath(S, D, OldBudget, PacketSize, BurstSize, BitRate, OldPath, NewPath) :-
    dif(S, D), link(S, N, TProp, Bandwidth), \+ member(N, OldPath), 
    node(N, MinNodeBudget), Bandwidth > BitRate,
    transmissionTime(PacketSize, Bandwidth, TTime),
    queuingTime(N, PacketSize, BurstSize, Bandwidth, QTime),
    NewBudget is OldBudget - MinNodeBudget - QTime - TProp - TTime, NewBudget > 0,
    goodPath(N, D, NewBudget, PacketSize, BurstSize, BitRate, [S|OldPath], NewPath).
goodPath(D, D, _, _, _, _, P, FP) :- reverse([D|P],FP).

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


    