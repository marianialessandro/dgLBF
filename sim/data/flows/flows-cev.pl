flow(f1, du11, sm2cb).
flow(f2, ns12, ns6).
flow(f3, du21, sm1cb).

dataReqs(f1, 0.008, 3, 5, 50, 10).
dataReqs(f2, 0.01, 4, 10, 100, 10).
dataReqs(f3, 0.008, 5, 6, 40, 10).

reliabilityReqs(f1, 0.9, 1).
reliabilityReqs(f2, 0.85, 2).
reliabilityReqs(f3, 0.95, 1).

antiAffinity(f1, [f3]).
%antiAffinity(f2, [f1, f3]).
antiAffinity(f3, [f1]).

candidate(p0_du11_sm2cb, du11, sm2cb, [du11, ns11, ns21, ns31, ns8, ns52, sm2cb]).
candidate(p1_du11_sm2cb, du11, sm2cb, [du11, ns11, ns22, ns32, ns8, ns52, sm2cb]).
candidate(p2_du11_sm2cb, du11, sm2cb, [du11, ns11, ns22, ns32, ns42, ns52, sm2cb]).
candidate(p0_ns12_ns6, ns12, ns6, [ns12, ns21, ns31, ns6]).
candidate(p1_ns12_ns6, ns12, ns6, [ns12, ns22, ns32, ns6]).
candidate(p2_ns12_ns6, ns12, ns6, [ns12, ns21, ns7, ns31, ns6]).
candidate(p3_ns12_ns6, ns12, ns6, [ns12, ns21, ns7, ns32, ns6]).
candidate(p4_ns12_ns6, ns12, ns6, [ns12, ns22, ns7, ns31, ns6]).
candidate(p5_ns12_ns6, ns12, ns6, [ns12, ns22, ns7, ns32, ns6]).
candidate(p6_ns12_ns6, ns12, ns6, [ns12, ns21, ns11, ns22, ns32, ns6]).
candidate(p7_ns12_ns6, ns12, ns6, [ns12, ns21, ns13, ns22, ns32, ns6]).
candidate(p8_ns12_ns6, ns12, ns6, [ns12, ns21, ns14, ns22, ns32, ns6]).
candidate(p9_ns12_ns6, ns12, ns6, [ns12, ns21, ns7, ns22, ns32, ns6]).
candidate(p10_ns12_ns6, ns12, ns6, [ns12, ns21, ns31, ns7, ns32, ns6]).
candidate(p11_ns12_ns6, ns12, ns6, [ns12, ns21, ns31, ns8, ns32, ns6]).
candidate(p12_ns12_ns6, ns12, ns6, [ns12, ns22, ns11, ns21, ns31, ns6]).
candidate(p13_ns12_ns6, ns12, ns6, [ns12, ns22, ns13, ns21, ns31, ns6]).
candidate(p14_ns12_ns6, ns12, ns6, [ns12, ns22, ns14, ns21, ns31, ns6]).
candidate(p15_ns12_ns6, ns12, ns6, [ns12, ns22, ns7, ns21, ns31, ns6]).
candidate(p16_ns12_ns6, ns12, ns6, [ns12, ns22, ns32, ns7, ns31, ns6]).
candidate(p17_ns12_ns6, ns12, ns6, [ns12, ns22, ns32, ns8, ns31, ns6]).
candidate(p18_ns12_ns6, ns12, ns6, [ns12, ns21, ns11, ns22, ns7, ns31, ns6]).
candidate(p19_ns12_ns6, ns12, ns6, [ns12, ns21, ns11, ns22, ns7, ns32, ns6]).
candidate(p20_ns12_ns6, ns12, ns6, [ns12, ns21, ns13, ns22, ns7, ns31, ns6]).
candidate(p21_ns12_ns6, ns12, ns6, [ns12, ns21, ns13, ns22, ns7, ns32, ns6]).
candidate(p22_ns12_ns6, ns12, ns6, [ns12, ns21, ns14, ns22, ns7, ns31, ns6]).
candidate(p23_ns12_ns6, ns12, ns6, [ns12, ns21, ns14, ns22, ns7, ns32, ns6]).
candidate(p24_ns12_ns6, ns12, ns6, [ns12, ns21, ns7, ns31, ns8, ns32, ns6]).
candidate(p25_ns12_ns6, ns12, ns6, [ns12, ns21, ns7, ns32, ns8, ns31, ns6]).
candidate(p26_ns12_ns6, ns12, ns6, [ns12, ns21, ns31, ns7, ns22, ns32, ns6]).
candidate(p27_ns12_ns6, ns12, ns6, [ns12, ns22, ns11, ns21, ns7, ns31, ns6]).
candidate(p28_ns12_ns6, ns12, ns6, [ns12, ns22, ns11, ns21, ns7, ns32, ns6]).
candidate(p29_ns12_ns6, ns12, ns6, [ns12, ns22, ns13, ns21, ns7, ns31, ns6]).
candidate(p30_ns12_ns6, ns12, ns6, [ns12, ns22, ns13, ns21, ns7, ns32, ns6]).
candidate(p31_ns12_ns6, ns12, ns6, [ns12, ns22, ns14, ns21, ns7, ns31, ns6]).
candidate(p32_ns12_ns6, ns12, ns6, [ns12, ns22, ns14, ns21, ns7, ns32, ns6]).
candidate(p33_ns12_ns6, ns12, ns6, [ns12, ns22, ns7, ns31, ns8, ns32, ns6]).
candidate(p34_ns12_ns6, ns12, ns6, [ns12, ns22, ns7, ns32, ns8, ns31, ns6]).
candidate(p35_ns12_ns6, ns12, ns6, [ns12, ns22, ns32, ns7, ns21, ns31, ns6]).
candidate(p0_du21_sm1cb, du21, sm1cb, [du21, ns14, ns21, ns31, ns41, ns51, sm1cb]).
candidate(p1_du21_sm1cb, du21, sm1cb, [du21, ns14, ns21, ns31, ns8, ns51, sm1cb]).
candidate(p2_du21_sm1cb, du21, sm1cb, [du21, ns14, ns22, ns32, ns8, ns51, sm1cb]).
