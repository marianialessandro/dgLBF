solutionCost([], Cost) :-
    allNodes(Nodes),
    solutionCostEmpty(Nodes, 0, Cost).
solutionCost(NodesMetrics, Cost) :-
    solutionCost(NodesMetrics, 0, Cost).

solutionCostEmpty([], Cost, Cost).
solutionCostEmpty([Node | Tail], OldCost, NewCost) :-
    routerCost(Node, 0, RouterCost),
    TmpCost is OldCost + RouterCost,
    solutionCostEmpty(Tail, TmpCost, NewCost).

solutionCost([], Cost, Cost).
solutionCost([(Node, Load) | NodesMetricsTail], OldCost, NewCost) :-
    routerCost(Node, Load, RouterCost),
    TmpCost is OldCost + RouterCost,
    solutionCost(NodesMetricsTail, TmpCost, NewCost).
