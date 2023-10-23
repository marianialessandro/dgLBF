:- table rankedLinks/2.


updateCapacities([N1,N2|Ns], BitRate, OldAlloc, NewAlloc) :-
    select((N1,N2, OldC), OldAlloc, Rest), NewC is OldC + BitRate,
    updateCapacities([N2|Ns], BitRate, [(N1,N2,NewC)|Rest], NewAlloc).
updateCapacities([N1,N2|Ns], BitRate, OldAlloc, NewAlloc) :-
    \+ member((N1,N2,_), OldAlloc),
    updateCapacities([N2|Ns], BitRate, [(N1,N2,BitRate)|OldAlloc], NewAlloc).
updateCapacities([_], _, Alloc, Alloc).

usedBandwidth(N1, N2, Alloc, UsedBW) :- member((N1,N2,UsedBW), Alloc).
usedBandwidth(N1, N2, Alloc, 0) :- \+ member((N1,N2,_), Alloc).

% rank links outgoing from N by their featured latency
rankedLinks(N, RankedLinks) :-
    findall(link(N, N2, Lat, BW), link(N, N2, Lat, BW), Links),
    sort(3, @=<, Links, RankedLinks).