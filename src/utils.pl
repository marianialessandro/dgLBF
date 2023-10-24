:- table rankedLinks/2.
:- table rankedLink/4.


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
    findall(r(Rank,link(N, N2, Lat, BW)), (link(N, N2, Lat, BW), degree(N2,D), rankedLink(Lat,D,BW,Rank)), Links),
    sort(Links, Tmp), findall(L, member(r(_,L), Tmp), RankedLinks).

rankedLink(Lat,Deg,BW,Rank) :-
    (maxLatency(MaxLat), minLatency(MinLat), dif(MaxLat,MinLat), NormLat is (Lat-MinLat)/(MaxLat-MinLat) ; NormLat is 1 ),
    (maxDegree(MaxDeg), minDegree(MinDeg), dif(MaxDeg, MinDeg), NormDeg is (MaxDeg-Deg)/(MaxDeg-MinDeg) ; NormDeg is 1),
    (maxBandwidth(MaxBW), minBandwidth(MinBW), dif(MaxBW, MinBW), NormBW is (MaxBW-BW)/(MaxBW-MinBW) ; NormBW is 1),
    Rank is 0.33 * NormLat + 0.33 * NormDeg + 0.33 * NormBW.
