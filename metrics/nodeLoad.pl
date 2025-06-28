computeNodeLoad(Alloc, NodeLoads) :-
    allNodes(AllNodes),
    computeNodeLoadList(AllNodes, Alloc, NodeLoads).

computeNodeLoadList([Node|Rest], Alloc, [(Node,Load)|NodeLoads]) :-
    nodeBandwidths(Node, Alloc, BWs),
    sum_list(BWs, Load),
    computeNodeLoadList(Rest, Alloc, NodeLoads).
computeNodeLoadList([], _, []).
