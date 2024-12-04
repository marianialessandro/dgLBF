node(du11, 3).
node(du12, 4).
node(du13, 1).
node(du21, 3).
node(du22, 3).
node(sband1, 4).
node(sband2, 1).
node(mimu1, 1).
node(mimu2, 3).
node(mimu3, 2).
node(startr1, 3).
node(startr2, 3).
node(cmriu1, 3).
node(cmriu2, 3).
node(bfcu, 4).
node(fcm1, 1).
node(lcm1, 4).
node(rcm1, 4).
node(fcm2, 4).
node(lcm2, 3).
node(rcm2, 2).
node(cm1ca, 1).
node(cm1cb, 2).
node(sm1ca, 4).
node(sm1cb, 4).
node(smriu1, 2).
node(smriu2, 2).
node(cm2ca, 2).
node(cm2cb, 4).
node(sm2ca, 4).
node(sm2cb, 1).
node(ns11, 1).
node(ns12, 4).
node(ns13, 2).
node(ns14, 2).
node(ns21, 1).
node(ns22, 4).
node(ns7, 1).
node(ns31, 1).
node(ns32, 3).
node(ns41, 3).
node(ns8, 3).
node(ns42, 2).
node(ns51, 4).
node(ns52, 4).
node(ns6, 4).

link(du11, ns11, 3, 440, 0.9928).
link(du12, ns11, 4, 421, 0.9913).
link(du13, ns11, 3, 436, 0.9949).
link(du21, ns14, 1, 251, 0.9922).
link(du22, ns14, 3, 312, 0.9913).
link(sband1, ns12, 4, 265, 0.9956).
link(sband2, ns12, 2, 333, 0.9941).
link(mimu1, ns13, 4, 430, 0.9982).
link(mimu2, ns13, 1, 482, 0.9938).
link(mimu3, ns13, 4, 432, 0.9927).
link(startr1, ns13, 2, 336, 0.9944).
link(startr2, ns13, 1, 433, 0.993).
link(cmriu1, ns21, 4, 280, 0.9924).
link(cmriu2, ns22, 4, 297, 0.9957).
link(bfcu, ns22, 3, 493, 0.9933).
link(fcm1, ns31, 2, 339, 0.995).
link(lcm1, ns31, 4, 208, 0.9925).
link(rcm1, ns31, 3, 407, 0.9981).
link(fcm2, ns32, 4, 393, 0.9962).
link(lcm2, ns32, 4, 368, 0.9916).
link(rcm2, ns32, 4, 488, 0.9944).
link(cm1ca, ns41, 2, 476, 0.9945).
link(cm1cb, ns41, 4, 346, 0.9951).
link(sm1ca, ns51, 4, 350, 0.9913).
link(sm1cb, ns51, 3, 472, 0.9976).
link(smriu1, ns6, 3, 342, 0.9934).
link(smriu2, ns6, 2, 487, 0.9952).
link(cm2ca, ns42, 4, 217, 0.995).
link(cm2cb, ns42, 3, 253, 0.9963).
link(sm2ca, ns52, 3, 212, 0.9907).
link(sm2cb, ns52, 3, 235, 0.9972).
link(ns11, du11, 3, 440, 0.9928).
link(ns11, du12, 4, 421, 0.9913).
link(ns11, du13, 3, 436, 0.9949).
link(ns11, ns21, 3, 325, 0.9913).
link(ns11, ns22, 4, 458, 0.9953).
link(ns12, sband1, 4, 265, 0.9956).
link(ns12, sband2, 2, 333, 0.9941).
link(ns12, ns21, 4, 417, 0.9989).
link(ns12, ns22, 3, 346, 0.9931).
link(ns13, mimu1, 4, 430, 0.9982).
link(ns13, mimu2, 1, 482, 0.9938).
link(ns13, mimu3, 4, 432, 0.9927).
link(ns13, startr1, 2, 336, 0.9944).
link(ns13, startr2, 1, 433, 0.993).
link(ns13, ns21, 4, 446, 0.996).
link(ns13, ns22, 3, 327, 0.9947).
link(ns14, du21, 1, 251, 0.9922).
link(ns14, du22, 3, 312, 0.9913).
link(ns14, ns21, 3, 383, 0.9921).
link(ns14, ns22, 4, 328, 0.9961).
link(ns21, cmriu1, 4, 280, 0.9924).
link(ns21, ns11, 3, 325, 0.9913).
link(ns21, ns12, 4, 417, 0.9989).
link(ns21, ns13, 4, 446, 0.996).
link(ns21, ns14, 3, 383, 0.9921).
link(ns21, ns7, 4, 311, 0.995).
link(ns21, ns31, 3, 352, 0.99).
link(ns22, cmriu2, 4, 297, 0.9957).
link(ns22, bfcu, 3, 493, 0.9933).
link(ns22, ns11, 4, 458, 0.9953).
link(ns22, ns12, 3, 346, 0.9931).
link(ns22, ns13, 3, 327, 0.9947).
link(ns22, ns14, 4, 328, 0.9961).
link(ns22, ns7, 4, 201, 0.999).
link(ns22, ns32, 2, 463, 0.9957).
link(ns7, ns21, 4, 311, 0.995).
link(ns7, ns22, 4, 201, 0.999).
link(ns7, ns31, 3, 311, 0.9909).
link(ns7, ns32, 2, 429, 0.9935).
link(ns31, fcm1, 2, 339, 0.995).
link(ns31, lcm1, 4, 208, 0.9925).
link(ns31, rcm1, 3, 407, 0.9981).
link(ns31, ns21, 3, 352, 0.99).
link(ns31, ns7, 3, 311, 0.9909).
link(ns31, ns41, 4, 419, 0.9942).
link(ns31, ns8, 1, 380, 0.9952).
link(ns31, ns6, 2, 250, 0.9942).
link(ns32, fcm2, 4, 393, 0.9962).
link(ns32, lcm2, 4, 368, 0.9916).
link(ns32, rcm2, 4, 488, 0.9944).
link(ns32, ns22, 2, 463, 0.9957).
link(ns32, ns7, 2, 429, 0.9935).
link(ns32, ns8, 4, 315, 0.9927).
link(ns32, ns6, 3, 389, 0.9926).
link(ns32, ns42, 4, 373, 0.9909).
link(ns41, cm1ca, 2, 476, 0.9945).
link(ns41, cm1cb, 4, 346, 0.9951).
link(ns41, ns31, 4, 419, 0.9942).
link(ns41, ns51, 1, 498, 0.9964).
link(ns8, ns31, 1, 380, 0.9952).
link(ns8, ns32, 4, 315, 0.9927).
link(ns8, ns51, 3, 369, 0.9973).
link(ns8, ns52, 1, 463, 0.9963).
link(ns42, cm2ca, 4, 217, 0.995).
link(ns42, cm2cb, 3, 253, 0.9963).
link(ns42, ns32, 4, 373, 0.9909).
link(ns42, ns52, 4, 341, 0.998).
link(ns51, sm1ca, 4, 350, 0.9913).
link(ns51, sm1cb, 3, 472, 0.9976).
link(ns51, ns41, 1, 498, 0.9964).
link(ns51, ns8, 3, 369, 0.9973).
link(ns52, sm2ca, 3, 212, 0.9907).
link(ns52, sm2cb, 3, 235, 0.9972).
link(ns52, ns8, 1, 463, 0.9963).
link(ns52, ns42, 4, 341, 0.998).
link(ns6, smriu1, 3, 342, 0.9934).
link(ns6, smriu2, 2, 487, 0.9952).
link(ns6, ns31, 2, 250, 0.9942).
link(ns6, ns32, 3, 389, 0.9926).

