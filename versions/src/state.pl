:- table budget/6.

updateState([S, N | Tail], Carbon, MinB, BitRate, PacketSize, OldAlloc, NodeMetrics, NewCarbon, NewAlloc, NewNodeMetrics, NewMinB) :-
    link(S, N, LinkTProp, LinkBandwidth, _),
    budget(N, MinB, LinkTProp, PacketSize, LinkBandwidth, TmpMinB),
    updateAlloc(S, N, BitRate, OldAlloc, TmpAlloc),
    updateInLoads(S, BitRate, NodeMetrics, TmpMetrics),
    newCarbon(S, Carbon, NodeMetrics, TmpMetrics, TmpCarbon),
    updateStateMid([N | Tail], TmpCarbon, TmpMinB, BitRate, PacketSize, TmpAlloc, TmpMetrics, NewCarbon, NewAlloc, NewNodeMetrics, NewMinB).

updateStateMid([S], Carbon, MinB, BitRate, _, OldAlloc, NodeMetrics, NewCarbon, NewAlloc, NewNodeMetrics, NewMinB) :-
    NewAlloc = OldAlloc,
    NewMinB = MinB,
    updateInLoads(S, BitRate, NodeMetrics, NewNodeMetrics),
    newCarbon(S, Carbon, NodeMetrics, NewNodeMetrics, NewCarbon).

updateStateMid([S, N | Tail], Carbon, MinB, BitRate, PacketSize, OldAlloc, NodeMetrics, NewCarbon, NewAlloc, NewNodeMetrics, NewMinB) :-
    link(S, N, LinkTProp, LinkBandwidth, _),
    budget(N, MinB, LinkTProp, PacketSize, LinkBandwidth, TmpMinB),
    DoubleBitRate is BitRate*2,
    updateAlloc(S, N, BitRate, OldAlloc, TmpAlloc),
    updateInLoads(S, DoubleBitRate, NodeMetrics, TmpMetrics),
    newCarbon(S, Carbon, NodeMetrics, TmpMetrics, TmpCarbon),
    updateStateMid([N | Tail], TmpCarbon, TmpMinB, BitRate, PacketSize, TmpAlloc, TmpMetrics, NewCarbon, NewAlloc, NewNodeMetrics, NewMinB).

newCarbon(Node, Carbon, NodeMetrics, NewNodeMetrics, NewCarbon):-
    routerLoad(Node, NodeMetrics, RouterLoad),
    routerCarbon(Node, RouterLoad, RouterCarbon),
    PreCarbon is Carbon - RouterCarbon,

    routerLoad(Node, NewNodeMetrics, NewRouterLoad),
    routerCarbon(Node, NewRouterLoad, RouterCarbonPostUpdate),
    NewCarbon is PreCarbon + RouterCarbonPostUpdate.

budget(Node, MinB, LinkTProp, PacketSize, LinkBandwidth, NewMinB) :-
    node(Node, MinNodeBudget),
    transmissionTime(PacketSize, LinkBandwidth, TTime),
    NewMinB is MinB - MinNodeBudget - LinkTProp - TTime.

updateAlloc(S, N, BitRate, OldAlloc, [(S, N, NewC) | Tail]) :-
    select((S, N, OldC), OldAlloc, Tail),
    NewC is OldC + BitRate.
updateAlloc(S, N, BitRate, OldAlloc, [(S, N, BitRate) | OldAlloc]) :-
    \+ member((S, N, _), OldAlloc).

updateInLoads(Node, Load, [], [(Node, Load)]) :-
    !.
updateInLoads(Node, Load, [(Node, CurrentLoad) | Tail], [(Node, NewLoad) | Tail]) :-
    !,
    NewLoad is CurrentLoad + Load.
updateInLoads(Node, Load, [Other | Tail], [Other | UpdatedTail]) :-
    updateInLoads(Node, Load, Tail, UpdatedTail).
