globals [
  n-new-possessions
  n-self-repairs
  n-hub-repairs
  n-volunteers
  d-total
]

breed [persons person]
persons-own [
  skill?
  possession?
  possession-t
  volunteer?
  broken?
  hub-customer?
  address
]

to setup
  clear-all

  ask patches with [ self != patch 0 0 ] [
    if random-float 1 < pop-density [
      sprout-persons 1 [
        set skill? random-float 1 < p-skill
        set volunteer? ifelse-value skill? [ random-float 1 < p-volunteer ] [ false ]
        set possession? random-float 1 < p-possession
        set possession-t ifelse-value possession? [ random break-t ] [ 0 ]
        set broken? false
        set address patch-here
        set hub-customer? false
        set shape "person"
        set color ifelse-value volunteer? [ volunteer-color ] [ grey ]
      ]
    ]
    set pcolor 90
  ]

  set n-volunteers count persons with [volunteer?]

  ask patch 0 0 [
    set pcolor white
  ]

  set n-new-possessions 0
  set n-self-repairs 0
  set n-hub-repairs 0
  set d-total 0

  reset-ticks
end

to go

  ask persons with [volunteer?] [
    travel patch 0 0
    if any? persons-here with [hub-customer?] [
      ask one-of persons-here with [hub-customer?] [
        set possession-t 0
        set broken? false
        set n-hub-repairs n-hub-repairs + 1
        set hub-customer? false
        travel address
        ask patch-here [
          set pcolor min (list 99.9 (pcolor + 0.1))
        ]
        set color hub-repair-color
      ]
    ]
  ]

  let queue-length count persons with [hub-customer?]

  ask persons with [possession?] [
    set possession-t possession-t + 1
    set broken? random-float 1 < p-break
    if broken? [
      (ifelse skill? [
        ; repair it yourself
        set possession-t 0
        set broken? false
        set n-self-repairs n-self-repairs + 1
        set color ifelse-value volunteer? [ volunteer-color ] [ self-repair-color ]
      ] queue-length < n-volunteers and random-float 1 < p-repair [
        ; take it to the repair hub
        travel patch 0 0
        set hub-customer? true
      ] [
        ; buy a new one
        set possession-t 0
        set broken? false
        set n-new-possessions n-new-possessions + 1
        set color replacement-color
      ])
    ]
  ]

  ask persons with [volunteer?] [
    travel address
  ]

  tick
end

to travel [ somewhere ]
  set d-total d-total + distance somewhere
  move-to somewhere
end

to-report p-repair
  report 1 / (1 + exp (-1 * repair-beta * (repair-d - distance (patch 0 0) )))
end

to-report p-break
  report 1 / (1 + exp (-1 * break-beta * (possession-t - break-t)))
end

to-report p-volunteer
  report 1 / (1 + exp (-1 * skill-beta * (skill-d - distance (patch 0 0) )))
end
@#$#@#$#@
GRAPHICS-WINDOW
222
11
1256
1046
-1
-1
2.0
1
10
1
1
1
0
1
1
1
-256
256
-256
256
1
1
1
ticks
30.0

BUTTON
11
20
77
53
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
79
20
142
53
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
144
20
207
53
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
11
60
207
93
pop-density
pop-density
0
1
0.006
0.001
1
NIL
HORIZONTAL

SLIDER
11
96
207
129
p-possession
p-possession
0
1
1.0
0.001
1
NIL
HORIZONTAL

SLIDER
11
168
207
201
break-beta
break-beta
0.01
10
0.67
0.01
1
NIL
HORIZONTAL

SLIDER
11
204
207
237
break-t
break-t
1
1000
700.0
1
1
NIL
HORIZONTAL

SLIDER
11
132
207
165
p-skill
p-skill
0
1
0.25
0.001
1
NIL
HORIZONTAL

SLIDER
11
240
207
273
repair-beta
repair-beta
0
10
0.33
0.01
1
NIL
HORIZONTAL

SLIDER
11
276
207
309
repair-d
repair-d
1
200
120.0
1
1
NIL
HORIZONTAL

SLIDER
11
312
207
345
skill-beta
skill-beta
0
10
0.17
0.01
1
NIL
HORIZONTAL

SLIDER
11
349
207
382
skill-d
skill-d
1
200
40.0
1
1
NIL
HORIZONTAL

MONITOR
17
426
102
471
Self Repairs
n-self-repairs / ticks
2
1
11

MONITOR
17
476
102
521
Replacements
n-new-possessions / ticks
2
1
11

MONITOR
17
525
102
570
Hub Repairs
n-hub-repairs / ticks
2
1
11

MONITOR
17
573
102
618
Queue
count persons with [hub-customer?]
1
1
11

INPUTBOX
19
644
168
704
volunteer-color
45.0
1
0
Color

INPUTBOX
20
708
169
768
self-repair-color
55.0
1
0
Color

INPUTBOX
21
773
170
833
hub-repair-color
105.0
1
0
Color

INPUTBOX
21
837
170
897
replacement-color
13.0
1
0
Color

MONITOR
107
426
192
471
Travelled
d-total / ticks
2
1
11

MONITOR
107
476
192
521
Dist / Repair
d-total / n-hub-repairs
2
1
11

@#$#@#$#@
## WHAT IS IT?

This is an abstract model of a 'repair hub' with the intention of exploring some key tipping points in the system leading to when a repair hub could in principle be viable.

There is a non-specific `possession` which has a probability of breaking each `tick` that is a (sigmoid) function of how old it is. (If you are unfamiliar with sigmoid functions, they are described below.) A broken `possession` can be mended by a person who has the necessary `skill`, and people can take the possession to be repaired by a `volunteer` at a `hub` at `patch 0 0`. However, the probability that someone with the `skill` will `volunteer` is a function of how far away they are from the `hub` (another sigmoid); similarly the probability that someone will bother to go to the `hub` is also a diminishing function of how far away they are from the `hub`.

## HOW IT WORKS

### Initialization and ontology

Agents are `persons`, who occupy the available space with a specified `pop-density`, with a randomly-allocated `address`, which is the patch on which they were initially `sprout`ed. (The patch `patch 0 0` cannot `sprout` a `person` as it is the location of the `hub`.)

Each person has the `skill?` to repair a `possession` with probability `p-skill`. If they have the `skill?` they will be a `volunteer?` at the `hub` with a probability that is a diminishing (sigmoid) function of their distance from the `hub`.

A `person` owns the `possession?` with probability `p-possession` (it probably makes sense to set `p-possession` to 1 -- the same effect could probably be achieved with a lower `pop-density` and, if need be, a higher `p-skill`). The time for which they have owned it is stored in `possession-t`, which is initialized to be a random integer in the range [0, `break-t`[. The possession is initially not `broken?`. 

A `hub-customer?` variable stores whether the `person` is currently awaiting a repair at a hub, and is initially `false`.

### Dynamics

Each time step, nominally perhaps representing a single day, the following things happen:

  1. `persons` who `volunteer?` move to the `hub` at `patch 0 0`. They then choose a random `hub-customer?` and repair that `person`'s possession. The `hub-customer?` then sets `possession-t` to zero (effectively, the repair is 'as new'), `broken?` to `false`, and moves back to their `address`, having set `hub-customer?` to `false`.

  2. The length of the queue at the `hub` is then computed as the number of `persons` with `hub-customer?` `true`.

  3. `persons` who have the `possession?` increment `possession-t`, and then a random probability is used to set `broken?`. If the possession is `broken?` then if the `person` has the `skill?` they will repair it themselves -- setting `possession-t` to zero and `broken?` to `false`. Otherwise, if the length of the `hub` queue calculated in step 2 is less than the number of `persons` who `volunteer?` _and_ a random probability based on the distance to the `hub` determines that they will take it to be repaired, the `person` moves to the `hub`, and sets `hub-customer?` to `true`. Failing both those options the `person` will buy a new possession, setting `possession-t` to zero and `broken?` to `false`.

Global variables keep track of the number of self-repairs, hub-repairs, and replacement purchases. These are displayed in monitors as averages (means) over the number of time steps. They can be considered the outcomes of the model's parameter settings. The key point of interest is whether there are enough breakages and repairs of the possession in the hub to merit keeping it running rather than adopting an alternative approach.

### Sigmoid functions

A sigmoid function is expressed algebraically as (_b_ and _c_ are parameters, and _e_ is the base of natural logarithms):

_y_ = 1 / (1 + _e_^(-_b_ * (_x_ + _c_))

As _x_ approaches negative infinity, _y_ approaches 0. As _x_ approaches positive infinity, _y_ approaches 1. If _c_ = 0, then when _x_ = 0, _y_ = 0.5. The function makes a sort of smooth 'step' centred at that point between _y_ being 0 and _y_ being 1 that is shaped a bit like an old-fashioned 's' (if you pulled the two ends of the 's' and stretched it enough that it didn't double back on itself in the middle) -- hence the name 'sigmoid' (remembering 'sigma' is the Greek letter equivalent to the Latin 's'). The higher _b_ is, the more rapidly that transition of _y_ from 0 to 1 takes place; for high enough values, the function will look like a step. For low values (less than 1), the transition is smoother, and the function looks more like a ramp from 0 to 1. If _b_ is zero, than _y_ is always 0.5 ragardless of _x_.

Note that when making the sigmoid function a _decreasing_ function of _x_ (as we do when _x_ represents distance from the hub, rather than how long the posession has been owned), the sigmoid is implemented this way:

_y_ = 1 / (1 + _e_^(-_b_ * (_c_ - _x_))

## HOW TO USE IT

The model has nine parameters influencing its dynamics, which you can use to explore the conditions under which a hub might be viable:

  + `pop-density` determines the probability with which a patch will `sprout` a `person` during initialization. Higher densities correspond to urban settings (and will correspondingly increase computational demands); lower densities to rural.

  + `p-possession` determines the probability with which a `person` will own the possession (have `possession?` set to `true` during initialization). `Persons` who do not have the possession, and who are not volunteers at the hub will not do anything in the simulation at all. It is probably not necessary to set `p-possession` to a value other than `1`.

  + `p-skill` determines the probability with which a `person` will have the skill to repair the possession (have `skill?` set to `true` during initialization). It is not necesssary to own the possession to have the skill to repair it. `Persons` with the `skill?` can be a `volunteer?`.

  + `skill-beta` and `skill-d` are the parameters of the sigmoid function determining, during initialization, whether a `person` with the `skill?` to repair the possession will be a `volunteer?` at the `hub`. Since volunteers have to travel too and from the `hub` every time step, it makes sense for `skill-d` to be less than `repair-d`. If `skill-beta` is more than 1, then the cut-off for whether a `person` with repair skills will volunteer is very sharp. The closer `skill-beta` is to zero, the less sharp the cut-off; at zero, it's basically a coin toss whether someone will volunteer.

  + `repair-beta` and `repair-d` are the parameters of the function determining, during the model's dynamics, whether a `person` with a `broken?` possession will use the `hub` to repair it if they don't have the `skill?` to repair it themselves (and the queue is not too long). These parameters determining the probability of a repair at the `hub` work in the same way as `skill-beta` and `skill-d` do for determining whether someone will volunteer.

  + `break-beta` and `break-t` are the parameters of the function determining, during the model's dynamics, whether a possession will break.

## THINGS TO NOTICE

The four different colours assigned to `persons` (who are initially grey) indicate whether:

  + They are a volunteer

  + They have repaired a broken possession themselves

  + They have repaired a broken possession at the repair hub at `patch 0 0`

  + They have bought a new possession to replace the broken one

The colours can be configured by the user according to their preferences. The main _visual_ outcome is the spread of the different colours as the model progresses. You will notice a 'circle' around `patch 0 0` (in the centre of the view) where people repair at the hub rather than buying a new one or repairing themselves. The size of this circle (and 'blurring' of its boundary) is determined by `repair-d` (and `repair-beta`). Agents inside that circle may still buy new possessions or repair themselves -- the former if the queue for the repair hub is too long; the latter if they have the necessary skill.

## THINGS TO TRY

Probably the `skill-d`, `repair-d` and `break-t` parameters are the main ones to fiddle with, along with `p-skill`. The `-beta` parameters just 'blur' the circle more as they approach zero. As stated earlier, `p-possession` should probably be set to 1. The `pop-density` parameter could be experimented with to compare outcome phase spaces as a way of assessing the impact of urban versus rural context.

  + If you increase `p-skill`, then more people will be able to repair the possession themselves, and the hub will be that much less viable; but if `p-skill` is too small, then the hub will not have enough volunteers and the queue for repairs will be too long.

  + If you increase `skill-d`, then you can compensate more for a decrease in `p-skill` by increasing the catchment area for volunteers. But the larger that distance, the cheaper (in terms of time or money) you are assuming transport to be per unit distance. Volunteers have to travel to and from the hub every day.

  + If you increase `repair-d`, then in the same way you can increase the catchment area for getting repairs, but then you also increase demand on the hub, and if it is already at capacity, you won't increase utilization.

  + Similarly, lengthening `break-t` will mean the possession is more reliable (and if we included money, more expensive to buy), but then will also reduce demand on the hub. Shortening will mean more demand for repairs, and, without extra volunteers, more replacements being bought.

In general, we might contrast the industrial scale at which consumer products are manufactured and delivered to their users with the effectiveness of a handful of volunteers repairing them at reducing waste, while it is essentially 'free' for manufacturers to have their broken products disposed of at end-of-life.

## EXTENDING THE MODEL

This is intended to be a simple, abstract model to demonstrate some fundamental principles about the conditions under which a repair hub might be a viable 'going concern'. As things stand, it is only looking at access to skills to undertake repairs, accessibility of the hub itself, and likelihood of the posession breaking

Money is a key lacking variable that is likely to change things (basically, how much does it cost to go to the repair hub versus how much a brand new device is, and how much does it cost to access the repair skills -- can we pay the repairers). However, there comes a point at which greater realism starts to open questions about whether a more empirical model would be superior. 

The model also assumes that a new possession can always be bought and delivered reliably. This assumption is not necessarily true -- especially in remote rural areas where deliveries can be unreliable and/or take longer. Having a device that can be repaired may be the quicker route to getting back its functionality.

## CREDITS AND REFERENCES

This model has been created for JHI-C4-1 on the Circular Economy, a project funded by the Scottish Government.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="sweep" repetitions="2" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <postRun>export-view (word "sweep-d" (pop-density * 1000) "-rB" (repair-beta * 100) "-rd" (repair-d) "-bB" (break-beta * 10) "-bt" (break-t) "-sB" (skill-beta * 100) "-sd" (skill-d) "-ps" (p-skill * 100) "-run" behaviorspace-run-number ".png")</postRun>
    <timeLimit steps="10000"/>
    <metric>n-self-repairs</metric>
    <metric>n-new-possessions</metric>
    <metric>n-hub-repairs</metric>
    <metric>d-total</metric>
    <enumeratedValueSet variable="pop-density">
      <value value="0.001"/>
      <value value="0.005"/>
      <value value="0.01"/>
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repair-beta">
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-possession">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skill-d">
      <value value="10"/>
      <value value="20"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-skill">
      <value value="0.01"/>
      <value value="0.02"/>
      <value value="0.05"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="break-t">
      <value value="250"/>
      <value value="500"/>
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="break-beta">
      <value value="0.1"/>
      <value value="0.5"/>
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skill-beta">
      <value value="0.01"/>
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repair-d">
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
