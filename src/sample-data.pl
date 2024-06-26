% node(NodeId, MinimumLatencyBudget)
node(nStart, 8).
node(n1, 5).
node(n2, 10).
node(nEnd, 5).

% link(N1,N2, TProp [ms], Bandwidth [Mbps], Reliability [%])
link(nStart, n1, 40, 100, 0.99).
link(nStart, n2, 15, 20, 0.99).
link(nStart, n3, 410, 100, 0.99).
link(nStart, n4, 3, 100, 0.99).
link(nStart, n5, 20, 100, 0.99).
link(n1, nEnd, 3, 20, 0.99).
link(n2, nEnd, 6, 50, 0.99).

% flow(FlowId, NStart, NEnd).
flow(f1, nStart, nEnd).
flow(f2, nStart, nEnd).
flow(f3, nStart, nEnd).

% dataReqs(FlowId, PacketSize [Mb], BurstSize [#packets], BitRate [Mbps], E2ELatencyBudget [ms], TolerationThreshold [ms])
dataReqs(f1, 0.008, 3, 5, 50, 10).
dataReqs(f2, 0.01, 4, 10, 100, 10).
dataReqs(f3, 0.008, 5, 8, 40, 10).

% reliabilityReqs(FlowId, Reliability [%], Replicas [#])
reliabilityReqs(f1, 0.92, 1).
reliabilityReqs(f2, 0.92, 1).
reliabilityReqs(f3, 0.92, 1).

% antiAffinity(FlowId, [FlowIds])
antiAffinity(f1, [f2, f3]).
antiAffinity(f2, [f1]).
antiAffinity(f3, [f1]).

% candidate(PathId, NStart, NEnd, Path)
candidate(p0_nStart_nEnd, nStart, nEnd, ['nStart', 'n1', 'nEnd']).
