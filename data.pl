:- dynamic flowsAt/2.

% node(NodeId, MinimumLatencyBudget)
% TODO: estimate MinimumLatencyBudget with queue model (i.e. M/M/1) or UBS calculus?
node(nStart, 8).
node(n1, 5).
node(n2, 10).
node(nEnd, 5).

% flowsAt(N, Flows)
flowsAt(nStart, []).
flowsAt(n1, []).
flowsAt(n2, []).
flowsAt(nEnd, []).

% link(N1,N2, TProp, Bandwidth [Mbps])
link(nStart, n1, 8, 100).
link(nStart, n2, 15, 20).
link(n1, nEnd, 3, 20).
link(n2, nEnd, 6, 50).

% flow(FlowId, NStart, NEnd, PacketSize [Mb], BurstSize [#packets], BitRate [Mbps], E2ELatencyBudget [ms], TolerationThreshold [ms])               
flow(f1, nStart, nEnd, 10, 0.008, 3, 50, 10).