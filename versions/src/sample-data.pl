% node(NodeId, MinimumLatencyBudget)
node(nStart, 8).
node(n1, 5).
node(n2, 10).
node(n3, 15).
node(n4, 5).
node(nEnd, 5).

% link(N1,N2, TProp [ms], Bandwidth [Mbps], Reliability [%])
link(nStart, n1, 40, 100, 0.97).
link(nStart, n2, 15, 20, 0.96).
link(nStart, n3, 410, 100, 0.98).
link(nStart, n4, 3, 100, 0.99).
link(n1, nEnd, 3, 20, 0.99).
link(n2, nEnd, 6, 50, 0.99).
link(n3, nEnd, 10, 50, 0.95).
link(n4, nEnd, 20, 50, 0.96).

link(n1, n2, 5, 50, 0.98).
link(n2, n3, 10, 50, 0.97).
link(n3, n4, 20, 50, 0.95).
link(n1, n3, 7, 50, 0.99).
link(n2, n4, 9, 50, 0.97).
link(n4, n1, 30, 50, 0.95).

% flow(FlowId, NStart, NEnd).
flow(f1, nStart, nEnd).
flow(f2, nStart, n3).
flow(f3, nStart, nEnd).

% dataReqs(FlowId, PacketSize [Mb], BurstSize [#packets], BitRate [Mbps], E2ELatencyBudget [ms], TolerationThreshold [ms])
dataReqs(f1, 0.008, 3, 5, 50, 10).
dataReqs(f2, 0.01, 4, 10, 100, 10).
dataReqs(f3, 0.008, 5, 8, 40, 10).

% reliabilityReqs(FlowId, Reliability [%], Replicas [#])
reliabilityReqs(f1, 0.9, 1).
reliabilityReqs(f2, 0.85, 2).
reliabilityReqs(f3, 0.95, 1).

% antiAffinity(FlowId, [FlowIds])
antiAffinity(f1, [f2]).
antiAffinity(f2, [f1, f3]).
antiAffinity(f3, [f2]).
% antiAffinity(f2, [f1]).
% antiAffinity(f3, [f1]).

% candidate(PathId, NStart, NEnd, Path)
candidate(p0_nStart_nEnd, nStart, nEnd, ['nStart', 'n1', 'nEnd']).
candidate(p1_nStart_nEnd, nStart, nEnd, ['nStart', 'n2', 'nEnd']).
candidate(p2_nStart_nEnd, nStart, nEnd, ['nStart', 'n3', 'nEnd']).
candidate(p3_nStart_nEnd, nStart, nEnd, ['nStart', 'n4', 'nEnd']).
candidate(p5_nStart_nEnd, nStart, nEnd, ['nStart', 'n1', 'n2', 'nEnd']).
candidate(p6_nStart_nEnd, nStart, nEnd, ['nStart', 'n2', 'n3', 'nEnd']).
candidate(p7_nStart_nEnd, nStart, nEnd, ['nStart', 'n3', 'n4', 'nEnd']).
candidate(p9_nStart_nEnd, nStart, nEnd, ['nStart', 'n1', 'n3', 'nEnd']).
candidate(p10_nStart_nEnd, nStart, nEnd, ['nStart', 'n2', 'n4', 'nEnd']).
candidate(p14_nStart_nEnd, nStart, nEnd, ['nStart', 'n4', 'n1', 'nEnd']).

candidate(p0_nStart_n3, nStart, n3, ['nStart', 'n3']).
candidate(p1_nStart_n3, nStart, n3, ['nStart', 'n1', 'n3']).
candidate(p2_nStart_n3, nStart, n3, ['nStart', 'n2', 'n3']).
candidate(p3_nStart_n3, nStart, n3, ['nStart', 'n4', 'n3']).
candidate(p5_nStart_n3, nStart, n3, ['nStart', 'n1', 'n2', 'n3']).
candidate(p6_nStart_n3, nStart, n3, ['nStart', 'n2', 'n4', 'n3']).


% OUTPUT FORMAT
% [(FlowId, PathId, (Path, Reliability, (MinBudget, MaxBudget), Delay))]
