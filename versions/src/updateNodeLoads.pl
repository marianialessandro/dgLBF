updateNodeLoads([], _, Loads, Loads).

updateNodeLoads([Node], BitRate, Loads, UpdatedLoads) :-
    updateInLoads(Node, BitRate, Loads, UpdatedLoads).

updateNodeLoads([First|Tail], BitRate, Loads, FinalUpdated) :-
    updateInLoads(First, BitRate, Loads, UpdatedFirst),
    processTail(Tail, BitRate, UpdatedFirst, FinalUpdated).

processTail([Last], BitRate, Loads, UpdatedLoads) :-
    updateInLoads(Last, BitRate, Loads, UpdatedLoads).

processTail([Mid|Tail], BitRate, Loads, FinalUpdated) :-
    DoubleBitRate is 2 * BitRate,
    updateInLoads(Mid, DoubleBitRate, Loads, UpdatedMid),
    processTail(Tail, BitRate, UpdatedMid, FinalUpdated).

updateInLoads(Node, Value, [(Node,Current)|Rest], [(Node,NewValue)|Rest]) :-
    NewValue is Current + Value, !.

updateInLoads(Node, Value, [Other|Rest], [Other|Updated]) :-
    updateInLoads(Node, Value, Rest, Updated).

updateInLoads(Node, Value, [], [(Node,Value)]).