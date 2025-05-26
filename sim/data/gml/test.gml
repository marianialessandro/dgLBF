graph [
  directed 1
  node [
    id 1
    label "n1"
    weight 2
  ]
  node [
    id 2
    label "n2"
    weight 3
  ]
  node [
    id 3
    label "n3"
    weight 1
  ]
  node [
    id 4
    label "n4"
    weight 4
  ]
  node [
    id 5
    label "n5"
    weight 2
  ]
  edge [
    source 1
    target 2
    hops 1
    bandwidth 100
    reliability 0.99
  ]
  edge [
    source 2
    target 1
    hops 1
    bandwidth 100
    reliability 0.99
  ]
  edge [
    source 2
    target 3
    hops 1
    bandwidth 120
    reliability 0.98
  ]
  edge [
    source 3
    target 2
    hops 1
    bandwidth 120
    reliability 0.98
  ]
  edge [
    source 3
    target 4
    hops 2
    bandwidth  80
    reliability 0.97
  ]
  edge [
    source 4
    target 3
    hops 2
    bandwidth  80
    reliability 0.97
  ]
  edge [
    source 4
    target 5
    hops 1
    bandwidth 150
    reliability 0.995
  ]
  edge [
    source 5
    target 4
    hops 1
    bandwidth 150
    reliability 0.995
  ]
  edge [
    source 1
    target 3
    hops 2
    bandwidth  90
    reliability 0.98
  ]
  edge [
    source 3
    target 1
    hops 2
    bandwidth  90
    reliability 0.98
  ]
  edge [
    source 2
    target 4
    hops 1
    bandwidth 110
    reliability 0.96
  ]
  edge [
    source 4
    target 2
    hops 1
    bandwidth 110
    reliability 0.96
  ]
  edge [
    source 2
    target 5
    hops 2
    bandwidth 100
    reliability 0.97
  ]
  edge [
    source 5
    target 2
    hops 2
    bandwidth 100
    reliability 0.97
  ]
  edge [
    source 3
    target 5
    hops 3
    bandwidth  85
    reliability 0.95
  ]
  edge [
    source 5
    target 3
    hops 3
    bandwidth  85
    reliability 0.95
  ]
  edge [
    source 1
    target 4
    hops 1
    bandwidth  70
    reliability 0.94
  ]
  edge [
    source 4
    target 1
    hops 1
    bandwidth  70
    reliability 0.94
  ]
]