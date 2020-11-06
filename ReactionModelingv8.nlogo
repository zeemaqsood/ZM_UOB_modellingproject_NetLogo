globals [element-scheme color-scheme color-scheme2 effective-receptors-link]

breed [ ligands ligand]
; breed [ dimers dimer]
breed [ receptors receptor]
breed [ syks syk ]

; every turtle possesses the following attributes:
; element-state: the state of element such as R0, R1, R2, R3, R4 and R5. Please refer to documentation for definitions of the states.
; product-id: the identifier of each unique molecule or product formed, it is similar in function to that of a leading turtle in prior versions for clustering. The default value is self.
; product-turn and speed: this would be same as that of the product id.
; molecule: The molecule based on the elements it comprises of.
;--------------------------------------------
; ligand specific attributes:
; receptor-bound: if bounded to a receptor (self explanatory).
; is-dimer? and reversible? (for the dimers in setup, as they are irreversible, examples can be that of fab2 or antibodies, nanobodies etc).
; l1 and l2: two ligands which are dimers. By default, they are nobody.
; --------------------------------------------
; receptor specific attributes:
; phosphorylated? boolean, turns true if the receptor is phoshorylated.
; ligand-bound: self of the ligand that is connected. If no ligands are connected it would be nobody.
; protein-bound: self of syk that is connected. If no syks are connected it would be nobody.
; receptor-bound: a list of other receptors connected to a particular receptor. This will be an empty list if there are no connections.

ligands-own [element-state product-id product-turn product-speed receptor-bound ligand-bound dimer-bound is-dimer? reversible? molecule l1 l2]
;dimers-own [family product-id product-turn site1-bounded?  site2-bounded?]
receptors-own [element-state product-id product-turn product-speed phosphorylated? ligand-bound protein-bound receptor-bound molecule ]
syks-own [element-state product-id product-turn product-speed kinectically-active? inter-complex? site1-bound  site2-bound molecule ]

to setup
  clear-all
  setup-globals
  setup-species
  setup-slow-region
  reset-ticks
end

; setting up color for each element state
to setup-globals
  ; each elements colors are mapped in the same order both lists element-scheme and color-scheme
  set element-scheme ["L0" "L1" "L0L0" "L1L0" "L1L1" "R0" "R1" "R2" "R3" "R4" "R5" "S0" "S1" "S2" "S3" "S4" "S5"]
  set color-scheme [ white blue gray white white gray blue violet blue violet violet gray white blue red white white ]
  set effective-receptors-link limit-rr-links
  if limit-rr-links = "unlimited"
  [ set effective-receptors-link R ]
  set-patch-size 20
  resize-world -20 20 -20 20
end

; setting up the 4 base species
to setup-species
  setup-monomers
  setup-receptors
  setup-syks
  setup-dimers
end

; setting values for monomer ligand
to setup-monomers
  create-ligands L
  [
    set shape "monomer"
    set size 6
    __set-line-thickness .2
    set product-turn random-float 360
    set receptor-bound nobody          ; by default it would be nobody. If it got connected with any of the receptors around, it will become self of that receptor.
    set is-dimer? false                ; false for monomeric ligand.
    set ligand-bound []                ; empty list by default. If it is connected to any ligand, the self of that ligand will be stored.
    set dimer-bound []                 ; if ligand got connected to any dimer, the self of ligand in dimer with l1 = self will be stored. (not implemented now as there are no such reactions as of now)
    set element-state get-ligand-element-state
    set molecule element-state
    set color get-color
    set product-id self
    set l1 nobody                      ; l1 and l2 are nobody for monomeric ligand. For dimer ligand, l1 and l2 help to identify the connected ligands.
    set l2 nobody
    setxy random-xcor random-ycor
   ]
end

; to get the element state of monomer
to-report get-ligand-element-state
  if receptor-bound != nobody [report "L1" ] ; L1 if the ligand is receptor bound
  report "L0"
end

; to get the color based on the element state mentioned in the element-scheme and color-scheme
to-report get-color
  let pos position element-state element-scheme
  report item pos color-scheme
end


; to set up receptors
to setup-receptors
  create-receptors R
  [
    set shape "receptor-with-border"
    set size 4
    set phosphorylated? false
    set ligand-bound nobody
    set protein-bound nobody
    set receptor-bound []
    set element-state get-receptor-element-state
    set molecule element-state
    set color get-color
    set product-id self
    __set-line-thickness -4
    setxy random-xcor random-ycor
  ]
end

; to get the element state of receptor based on the values
to-report get-receptor-element-state
  if phosphorylated? and ligand-bound != nobody and protein-bound != nobody
  [ report "R5" ]
  if phosphorylated? and protein-bound != nobody
  [ report "R4" ]
  if phosphorylated? and ligand-bound != nobody
  [ report "R3" ]
  if ligand-bound != nobody
  [ report "R2" ]
  if phosphorylated?
  [ report "R1" ]
  report "R0"
end

; to setup syks
to setup-syks
  create-syks S
  [
    set shape "syk"
    set size 3
    set kinectically-active? false
    set inter-complex? false
    set site1-bound nobody
    set site2-bound nobody
    set element-state get-syk-element-state
    set molecule element-state
    set color get-color
    set product-id self
    setxy random-xcor random-ycor
  ]
end

; to get the element state of syks
to-report get-syk-element-state
  if kinectically-active? and inter-complex? and site1-bound != nobody  and site2-bound != nobody
  [ report "S5" ]
  if inter-complex? and site1-bound != nobody  and site2-bound != nobody
  [ report "S4" ]
  if kinectically-active? and site1-bound != nobody  and site2-bound != nobody
  [ report "S3" ]
  if site1-bound != nobody  and site2-bound != nobody
  [ report "S2" ]
  if site1-bound != nobody  or site2-bound != nobody
  [ report "S1" ]
  report "S0"
end

; to set up dimers using two monomeric ligands
to setup-dimers
  ; create twice the number of monomers to create dimers
  create-ligands (2  * LL)
  [
    set shape "monomer"
    set size 6
    set receptor-bound nobody
    set is-dimer? true
    set reversible? false
    set product-id self
  ]
  let dimeric-ligands [self] of ligands with [is-dimer?]
  ; setup the two monomers as major and minor
  ; the self of major will be the product-id for both the monomers forming a dimeric ligand
  let i 0
  while [ i < (2 * LL) ]
  [
    let major item i dimeric-ligands
    let minor item (i + 1) dimeric-ligands
    ask major [ set l1 self set l2 [self] of minor]
    ask minor [ set product-id [product-id] of major set l1 [self] of major set l2 self]
    set i (i + 2)
  ]
  ; setting the dimer and aligning the monomers together
  ask ligands with [product-id = self]
  [ setxy random-xcor random-ycor ]
  ask ligands with [product-id  != self]
  [
    setup-minor-ligand
  ]
  ; set the element state as dimer
  ask ligands with [is-dimer?]
  [
    set element-state get-dimer-element-state
    set molecule element-state
    set color get-color
  ]
end

; positioning the minor monomer adjacent to the major one
to setup-minor-ligand
  set heading [heading] of product-id
  set xcor ([xcor] of product-id ) - (1.22 * cos heading)
  set ycor ([ycor] of product-id ) - (1.22 * sin (180 + heading))
end

; to get the element state
to-report get-dimer-element-state
  let l1-bound [receptor-bound] of l1
  let l2-bound [receptor-bound] of l2
  if l1-bound != nobody and l2-bound != nobody
  [ report "L1L1" ]
  if l1-bound != nobody and l2-bound = nobody
  [ report "L1L0" ]
  if l1-bound = nobody and l2-bound != nobody
  [ report "L1L0" ]
  report "L0L0"
end


; routine to get the name of the molecule of a given product (given product-id) and join element states of every element within the molecule to output a final name via concatenation.
; only one element state will be used for dimer as both have the same states.
to-report get-molecule-name [xproduct]
  let l-elements [element-state] of ligands with [product-id = xproduct and not is-dimer?]
  let r-elements [element-state] of receptors with [product-id = xproduct ]
  let s-elements [element-state] of syks with [product-id = xproduct ]
  let d-elements [element-state] of ligands with [product-id = xproduct and is-dimer? and l1 = self]
  let molecule-name ""
  foreach l-elements
  [ element ->
    set molecule-name (word molecule-name element)
  ]
  foreach r-elements
  [ element ->
    set molecule-name (word molecule-name element)
  ]
  foreach s-elements
  [ element ->
    set molecule-name (word molecule-name element)
  ]
  foreach d-elements
  [ element ->
    set molecule-name (word molecule-name element)
  ]
  report molecule-name
end

; to slow down the region which is marked as yellow i.e. lipid rafts.
; to have fifty patches together and each fifty set of patches will be
; randomly located.
to  setup-slow-region
  if slowing-region?
  [
    let cnt-patches (slow-area / 100) * count patches  ; number of patches to be colored
    let yellow-space-num cnt-patches / 50              ; number of different regions to be formed which are of size 50
    ask n-of yellow-space-num  patches [ set pcolor yellow]  ; starting point of creating yellow regions
    let yellow-patches count patches with [ pcolor = yellow ]
    if yellow-space-num >= 1
    [
      while [yellow-patches <= cnt-patches]              ; creating regions around starting points and have total size less than or equal to required percentage of rafts
      [
        ask patches with [ pcolor = yellow ] [
          ask neighbors with [ pcolor = black ]
          [ set pcolor [ pcolor ] of myself ]
        ]
        set yellow-patches count patches with [ pcolor = yellow ]
      ]
    ]

    ; ask n-of cnt-patches patches [ set pcolor yellow]
  ]
end


; go functions
; the functions implement the dissociation, association and transformation

to go
  move
  asssociate-and-transform
  dissociate-and-reverse

  write-into-file
  tick
end

; routine to allow the products to move.
to move
  ; to set the speed and turning angle for the leading element in the product/ molecule
  ask turtles with [ product-id = self ]
  [
    let size-of-product  (count turtles with [product-id = [product-id] of myself])
    set product-speed (1 / size-of-product)           ; reducing the speed based on the size of the product formed
    if pcolor = yellow
    [
      set product-speed product-speed * coefficient-of-diffusion ; in case of rafts initialised, reduce the speed in rafts
    ]
    set product-turn random-float 10 - random-float 10
      ; arrange other elements with respect to the location of leading element
    let adjustment 0 ;adjustment is to adjust the position of the elements. if it is zero all the elements will overlap with each other
    ask turtles with [ product-id = [product-id] of myself and product-id != self ] [
      go-on-receptor-in-molecule product-id adjustment          ; aligning receptors close to leading product id
      go-on-ligand-in-molecule product-id adjustment            ; aligning ligands close to leading product id
      go-on-syk-in-molecule product-id adjustment               ; aligning syks close to leading product id
      set product-turn [product-turn] of product-id
      set product-speed [product-speed] of product-id
      set adjustment (adjustment + 0.05)
    ]
  ]

  ; moving the elements
  ask turtles [
    rt  product-turn
    fd product-speed
  ]

end

; association or transformation of the elements based on all themes
to asssociate-and-transform
  phosphorylation-process
  if theme-2 [ dimerization-of-r ]
  syk-activation
  if theme-4 [ attaching-syk-within ]
  if theme-6 [dimerize-ligands]
  if theme-8 [ligand-and-receptor]
  if theme-9 [syk-and-phosphorylated-r]

end
; routine to enable phosphorylation process
; by default the receptors are non phosphorylated
; the receptors transform into phosphorylated receptors under various themes
; R0 will change only under theme 1 and 10 while others could transform under themes 1,5 and 10
to  phosphorylation-process
  let already-set? false
  ask receptors with [not phosphorylated?]
  [
    let themes (list "theme-1" "theme-5" "theme-10") ; list the themes that apply for phosphorylation
    if element-state = "R0"
    [ set themes (list "theme-1"  "theme-10") ]
    ; to get the themes if the switch is on and apply rates corresponding to the applicable themes
    ; to get a boolean in case the transformation is possible ( if the randomly generated number is less than
    ; corresponding rate of reaction)
    ; if theme 1 and 5 are on and rate is applicable for 5 then output will be
    ; [["theme-1" "theme-5"] [false true]]

    let theme-rates get-theme-rates themes
    let theme-list  item 0 theme-rates             ; to get the list of themes applicable
    let rate-list  item 1 theme-rates
    let transform-list? will-transform? rate-list
    ; if theme-1 is enabled and it could be transformed (true in rate-list)
    ; then we can phosphorylate the receptor, similar logic from theme 5 and 10.
    if member? "theme-1" theme-list
    [
      let pos position "theme-1" theme-list
      if (item pos transform-list? and member? element-state molecule)
      [
        phosphorylate true
        set  already-set? true
      ]
    ]
    if member? "theme-5" theme-list and not already-set?
    [
      let pos position "theme-5" theme-list
      if (item pos transform-list? and ligand-bound != nobody )
      [
        phosphorylate true
        set  already-set? true
      ]
    ]
    if member? "theme-10" theme-list and  is-there-any-syk? and not already-set?
    [
      let pos position "theme-10" theme-list
      if (item pos transform-list? and protein-bound != nobody )
      [
        phosphorylate true
      ]
    ]
  ]

end

; routine for phosphorylation
; setting the variable true for phosphorylation and false for unphosphorylation
to phosphorylate [ xstate ]
  set phosphorylated? xstate                       ; phosphorylate or unphosphorylate the receptor state
  set element-state get-receptor-element-state
  set color get-color
  update-molecule
end

; updating the molecule name for all the elements in a product
to update-molecule
  ; get the molecule name
  set molecule get-molecule-name product-id
  ; set the molecule name for all the elements in the molecule
  ; the molecule is identified using the product id
  ask turtles with [product-id = [product-id] of myself]
  [ set molecule [molecule] of myself ]
end

; From the given list of themes, identify the rates and return the values in the interface
; For example if the list comprises of [ "theme-1"], the rate rate-for-theme-1 will be returned
; if it is [ "theme-1" , "theme-2"] the list [ rate-for-theme-1  rate-for-theme-2 ] will be returned
to-report get-theme-rates [ themes ]
  let theme-list []
  let rate-list []
  foreach themes
  [ theme ->
    if (runresult theme)
    [
      set theme-list lput theme theme-list
      let temp (word "rate-for-" theme)
      set rate-list lput (runresult temp) rate-list
    ]
  ]
  report (list theme-list rate-list)
end

; Check if the element should transform or not.
; if random-float 100 < kn, it would transform.
; this routine tries to handle different number of themes if multiple themse are
; applicable
to-report will-transform? [theme-list]
  let len-list length theme-list
  let rand-value random-float (100 * len-list)
  let transform-list []
  ; if only one theme is considered
  if len-list = 1
  [
    ifelse rand-value < item 0 theme-list
    [set transform-list lput true transform-list ]
    [set transform-list lput false transform-list ]
  ]
   ; if two themes are considered
  if len-list = 2
  [
    ifelse (rand-value < item 0 theme-list )
    [set transform-list lput true transform-list ]
    [set transform-list lput false transform-list ]

    ifelse ((rand-value >= item 0 theme-list) and
      (rand-value < (item 0 theme-list + item 1 theme-list) ))
    [set transform-list lput true transform-list ]
    [set transform-list lput false transform-list ]
  ]
   ; if three themes are considered
  if len-list = 3
  [
    ifelse (rand-value < item 0 theme-list )
    [set transform-list lput true transform-list ]
    [set transform-list lput false transform-list ]
    ifelse (rand-value >= item 0 theme-list) and
      (rand-value < (item 0 theme-list + item 1 theme-list))
    [set transform-list lput true transform-list ]
    [set transform-list lput false transform-list ]
    ifelse ((rand-value >= (item 0 theme-list + item 1 theme-list)) and
      (rand-value < (item 0 theme-list + item 1 theme-list + item 2 theme-list)))
    [set transform-list lput true transform-list ]
    [set transform-list lput false transform-list ]
  ]
  report transform-list
end


to-report is-there-any-syk?
  if any? syks-here with [element-state = "S3" ]
  [ report true ]
  report false
end

; routine to dimerise receptors by finding nearby receptors and dimerise as per the rate for theme 2.
; to capture the list of all receptors connected to the receptor, in the form of a list
; update the product id and molecule post-dimerisation
to dimerization-of-r
  ask receptors with [ length receptor-bound < effective-receptors-link ]
  ;ask receptors with [ length receptor-bound = 0 ]
  [
    ; get list of receptors that are already connected to the asking receptor
    let connected-receptors receptor-bound
    ; identify any receptors which are not already connected
    let near-by-molecules other receptors-here with [ not member? self connected-receptors and  (length receptor-bound + length connected-receptors) < effective-receptors-link  ]
    ; if there are any other receptors which are not connected to the receptor, connect and dimerise
    if any? near-by-molecules and random-float 100 < rate-for-theme-2
    [
      let near-by-molecule one-of near-by-molecules
      ; add the receptor bound of self to others
      let receptor-list (sentence receptor-bound ([receptor-bound] of near-by-molecule) ([self] of near-by-molecule)  self )
      ask turtles with [product-id = [product-id] of myself ]
      [
        set product-id [product-id] of near-by-molecule
      ]

      ask receptors with [product-id = [product-id] of myself and member? self receptor-list ]
      [
        let new-receptor-list receptor-list
        if member? self receptor-list
        [
          set new-receptor-list remove self new-receptor-list
        ]
        set receptor-bound new-receptor-list
        __set-line-thickness .2
      ]
      set color get-color
      set molecule get-molecule-name product-id
      go-receptor-in-molecule product-id ;
    ]
  ]
end

; positioning receptor post-dimerisation with respect to the other receptor(s).
to go-receptor-in-molecule [xreceptor]
  set heading [heading] of xreceptor
  set xcor ([xcor] of xreceptor ) + (1.6 * cos heading)
  set ycor ([ycor] of xreceptor ) + (1.6 * sin (180 + heading))
end

; to activate syk from S2 to S3
; theme 3 applies here
to  syk-activation
  ask syks with [not kinectically-active? and site1-bound != nobody and site2-bound != nobody]
  [
    let themes (list "theme-3" )
    let theme-rates get-theme-rates themes
    let theme-list  item 0 theme-rates
    let rate-list  item 1 theme-rates
    let transform-list? will-transform? rate-list
    if member? "theme-3" theme-list
    [
      let pos position "theme-3" theme-list
      if (item pos transform-list?)
      [
        syk-activate
      ]
    ]
  ]
end


; updating the states to activate syk
to syk-activate
  set kinectically-active? true
  set element-state get-syk-element-state
  set color get-color
  update-molecule
end

; attaching syk within a molecule
; theme 4 applies here
to attaching-syk-within
  ask syks with [ element-state = "S1" ]
  [
    let theme-rates get-theme-rates ["theme-4"]
    let theme-list  item 0 theme-rates
    let rate-list  item 1 theme-rates
    let already-set? false
    let transform-list? will-transform? rate-list
    if member? "theme-4" theme-list
    [
      let pos position "theme-4" theme-list
      if (item pos transform-list?)
      [
        attach-syk
        set  already-set? true
      ]
    ]
;    if member? "theme-9" theme-list and not already-set?
;    [
;
;      let pos position "theme-9" theme-list
;      if (item pos transform-list?)
;      [
;        attach-syk
;        set  already-set? true
;      ]
;    ]

  ]
end

; to attach syk if state of syk is S1. If there are any receptors here,
; then site2 will become bound with the nearest receptor,
; to also update the molecule name accordingly.
to attach-syk
  let the-molecules receptors in-radius 1 with [phosphorylated? and protein-bound = nobody ]
  if any? the-molecules
  [
    let the-molecule one-of the-molecules
    set site2-bound [self] of the-molecule

    set element-state get-syk-element-state
    set color get-color
    ; create-link-with the-molecule [ set hidden? true]
    ask turtles with [product-id = [product-id] of myself ]
    [
      set product-id [product-id] of the-molecule
    ]
    ask the-molecule
    [
      set protein-bound [self] of myself
      set element-state get-receptor-element-state
      set color get-color
     ]
    update-molecule
  ]
end

; routine to dimerise ligands
; if the ligands are not dimers, they may dimerise with fellow ligands that are not dimers
; if the ligands are dimers they may dimerize with dimers only which are initialised in the setup function
to dimerize-ligands
  ask ligands with [not is-dimer? ]
  [
    let connected-ligands ligand-bound
    let near-by-molecules other ligands-here with [not is-dimer? and not member? self connected-ligands]
    if any? near-by-molecules and random-float 100 < rate-for-theme-6
    [
      let near-by-molecule one-of near-by-molecules
      set color get-color
      set reversible? true
      let ligand-list (sentence ligand-bound ([ligand-bound] of near-by-molecule) self ([self] of near-by-molecule))
           ;set dimer-bound []
      ask near-by-molecule [set reversible? true ]
      ask turtles with [product-id = [product-id] of myself ]
      [
        set product-id [product-id] of near-by-molecule
      ]
      ask ligands with [product-id = [product-id] of myself and member? self ligand-bound]
      [
        let new-ligand-list ligand-list
        if member? self new-ligand-list
        [
          set new-ligand-list remove self new-ligand-list
        ]
        set ligand-bound new-ligand-list
      ]
      update-molecule
    ]
  ]


end

; the ligand and receptors react to form a ligand receptor complex
; the receptor bound attrubute becomes true and for receptors, ligand-bound attribute becomes true in this routine,
; the state and moleule will be updated accordingly.
to ligand-and-receptor
  ask ligands  with [ receptor-bound = nobody]
  [
    if any? receptors-here with [ligand-bound = nobody ] and random-float 100 < rate-for-theme-8
    [
      let near-by-receptor one-of receptors-here with [ligand-bound = nobody ]
      set receptor-bound near-by-receptor
      set element-state get-ligand-element-state
      set color get-color
      ask turtles with [product-id = [product-id] of myself ]
      [
        set product-id [product-id] of near-by-receptor
      ]
      ;create-link-with near-by-receptor [ set hidden? true]
;      set heading [heading] of product-id
;      set xcor ([xcor] of product-id ) + (1.22 * cos heading)
;      set ycor ([ycor] of product-id ) + (1.22 * sin (180 + heading))
      ask near-by-receptor
      [
        set ligand-bound [self] of myself
        set element-state get-receptor-element-state
        set color get-color
      ]
      update-molecule
      go-ligand-in-molecule product-id
    ]
   ]
end

; positioning of the ligand with respect to receptor
to go-ligand-in-molecule [xreceptor]
  set heading [heading] of xreceptor
  set xcor ([xcor] of xreceptor ) + (1.22 * cos heading)
  set ycor ([ycor] of xreceptor ) + (1.22 * sin (180 + heading))
end

; routine to define how syk reacts with phosphorylated receptors
to syk-and-phosphorylated-r

  ask syks with [ site1-bound = nobody and site2-bound = nobody]
  [
    let near-by-molecules receptors-here with [phosphorylated? and protein-bound = nobody  ]
    if any? near-by-molecules  and random-float 100 < rate-for-theme-9
    [
      let near-by-molecule one-of near-by-molecules
      set  site1-bound [self] of near-by-molecule
      set element-state get-syk-element-state
      set color get-color
      ask turtles with [product-id = [product-id] of myself ]
      [
        set product-id [product-id] of near-by-molecule
      ]
      ;create-link-with near-by-molecule [ set hidden? true]
      go-syk-in-molecule product-id
      ask near-by-molecule
      [
        set protein-bound [self] of myself
        set element-state get-receptor-element-state
        set color get-color
      ]
      update-molecule
    ]
  ]

end

; positioning syk with respect to receptors
to go-syk-in-molecule [xreceptor]
  set heading [heading] of  xreceptor
  set xcor ([xcor] of xreceptor ) + (.8 * cos heading)
  set ycor ([ycor] of xreceptor ) + (.8 * sin (180 + heading))
end

; adjusting the position in go function
to go-on-receptor-in-molecule [xreceptor xadj]
  set heading [heading] of  xreceptor
  set xcor ([xcor] of xreceptor ) + ((xadj + 1.6 ) * cos heading)
  set ycor ([ycor] of xreceptor ) + ((xadj + 1.6 ) * sin (random-float 180 + heading))
end

; adjusting the position in go function
to go-on-ligand-in-molecule [xreceptor xadj ]
  set heading [heading] of  xreceptor
  set xcor ([xcor] of xreceptor ) + ((xadj + 1.22 ) * cos heading)
  set ycor ([ycor] of xreceptor ) + ((xadj + 1.22 ) * sin (random-float 180 + heading))
end


; adjusting the position in go function
to go-on-syk-in-molecule [xreceptor xadj]
  set heading [heading] of  xreceptor
  set xcor ([xcor] of xreceptor ) + ((xadj + .8 ) * cos heading)
  set ycor ([ycor] of xreceptor ) + ((xadj + .8 ) * sin (random-float 180 + heading))
end

; the main function for dissociation and reverse logic
to dissociate-and-reverse
  let unique-products  get-unique-product-id
  foreach unique-products
  [
    upid ->
    ask one-of turtles with [ product-id = upid ]
    [
      let element self
      if is-receptor? element
      [
        reverse-logic-for-receptors
      ]
      if is-syk? element
      [
        reverse-logic-for-syks
      ]
      if is-ligand? element
      [
        reverse-logic-for-ligands
      ]
    ]

  ]

end

to reverse-logic-for-receptors
  let processed? false
  if phosphorylated? or
  ligand-bound != nobody or
  protein-bound != nobody or
  not empty? receptor-bound
  [
    if protein-bound != nobody
    [
      let connected-syk protein-bound
      if dissociate-receptor-and-syk?  connected-syk
      [
        set protein-bound nobody
        set element-state get-receptor-element-state
        set color get-color
        let bound? false
        if ligand-bound != nobody or not empty? receptor-bound
        [
          set bound? true
        ]
        ask connected-syk
        [
          ifelse site1-bound = [self] of myself
          [ set site1-bound nobody ]
          [ set site2-bound nobody ]
          if (not bound? and (product-id = [product-id] of myself)) or (site1-bound = nobody and site2-bound = nobody)

          [
            set product-id self
          ]
          set element-state get-syk-element-state
          set color get-color
        ]
        ifelse ligand-bound = nobody and empty? receptor-bound
        [
          set product-id self
          set molecule element-state
          ask turtles with [product-id = [product-id] of connected-syk ]
          [
            set molecule get-molecule-name product-id
          ]
        ]
        [
          ask turtles with [product-id = [product-id] of myself ]
          [
            set molecule get-molecule-name product-id
          ]
        ]
        set processed? true
      ]
    ]

    if ligand-bound != nobody and not processed?
    [
      let connected-ligand ligand-bound
      if dissociate-receptor-and-ligand?
      [
        set ligand-bound nobody
        set element-state get-receptor-element-state
        set color get-color
        let bound? false
        if protein-bound != nobody or not empty? receptor-bound
        [
          set bound? true
        ]
        ask connected-ligand
        [

          if receptor-bound = [self] of myself
          [ set receptor-bound nobody ]
          ifelse is-dimer?
          [
            ifelse l1 = self
            [ set element-state get-dimer-element-state
              set color get-color
              ask l2 [ set element-state get-dimer-element-state set color get-color]
            ]
            [
              set element-state get-dimer-element-state
              set color get-color
              ask l1 [ set element-state get-dimer-element-state set color get-color ]
            ]
            if (not bound? and (product-id = [product-id] of myself)) or (([receptor-bound] of l1 = nobody and [receptor-bound] of l2 = nobody))
            [
              set product-id self
            ]
          ]
          [
            set element-state get-ligand-element-state
            set color get-color
            if ((not bound? and (product-id = [product-id] of myself)) or receptor-bound = nobody)
            [
              set product-id self
            ]
          ]

        ]
        ifelse protein-bound = nobody and empty? receptor-bound
        [
          set product-id self
          set molecule element-state
          ask turtles with [product-id = [product-id] of connected-ligand ]
          [
            set molecule get-molecule-name product-id
          ]
        ]
        [
          ask turtles with [product-id = [product-id] of myself ]
          [
            set molecule get-molecule-name product-id
          ]
        ]
        set processed? true
      ]
    ]

    if not empty? receptor-bound and not processed?
    [
      let connected-receptors  receptor-bound
      let me self
      if protein-bound = nobody and ligand-bound = nobody and dissociate-receptor-and-receptor?
      [
        let current-product-id [product-id] of one-of receptor-bound
        let new-product-id current-product-id
        if current-product-id = self
        [
          set new-product-id [self] of one-of receptor-bound
        ]
        set receptor-bound []
        __set-line-thickness -4
        foreach connected-receptors
        [
          c-r ->
          ask c-r
          [
            ifelse  member? me receptor-bound
            [ set receptor-bound remove me receptor-bound ]
            [ show "not member"]
          ]

        ]
        ask turtles with [product-id = current-product-id ]
        [
          set product-id new-product-id
        ]
        set product-id self
        set molecule get-molecule-name product-id
        ask turtles with [product-id = new-product-id ]
        [
          set molecule get-molecule-name product-id
        ]
        set processed? true
      ]
    ]

    if phosphorylated? and protein-bound = nobody and not processed?
    [
      unphosphorylation-process
    ]
  ]
  ask receptors with [empty? receptor-bound]
  [ __set-line-thickness -4 ]
end

; reverse reaction logic implentations
to  unphosphorylation-process
  let already-set? false
  let themes (list "theme-1" "theme-5" "theme-10")
  if element-state = "R1"
  [ set themes (list "theme-1"  "theme-10") ]
  let theme-rates get-reverse-theme-rates themes
  let theme-list  item 0 theme-rates
  let rate-list  item 1 theme-rates
  let transform-list? will-transform? rate-list
  if member? "theme-1" theme-list
  [
    let pos position "theme-1" theme-list
    if (item pos transform-list?)
    [
      phosphorylate false
      set  already-set? true
    ]
  ]
  if member? "theme-5" theme-list and not already-set?
  [
    let pos position "theme-5" theme-list
    if (item pos transform-list? and ligand-bound != nobody)
    [
      phosphorylate false
      set  already-set? true
    ]
  ]
  if member? "theme-10" theme-list and not already-set?
  [
    let pos position "theme-10" theme-list
    if (item pos transform-list? and protein-bound != nobody)
    [
      phosphorylate false
    ]
  ]

end

to-report get-reverse-theme-rates [ themes ]
  let theme-list []
  let rate-list []
  foreach themes
  [ theme ->
    if (runresult theme)
    [
      set theme-list lput theme theme-list
      let temp (word "reverse-rate-for-" theme)
      set rate-list lput (runresult temp) rate-list
    ]
  ]
  report (list theme-list rate-list)
end


to-report get-unique-product-id
  let products [product-id] of turtles
  let unique-products []
  foreach products
  [ pid ->
    if not member? pid unique-products
    [
      set unique-products lput pid unique-products
    ]
  ]
  report unique-products
end

to-report get-unique-products
  let products [product-id] of turtles
  let unique-products []
  foreach products
  [ pid ->
    if not member? pid unique-products and (count turtles with [product-id = pid] > 1)
    [
      set unique-products lput pid unique-products
    ]
  ]
  report unique-products
end

to-report dissociate-receptor-and-syk? [xsyk]
  if [ site1-bound] of xsyk != nobody and [site2-bound] of xsyk != nobody    ; S2
  [
    if random-float 100 < reverse-rate-for-theme-4
    [report true ]
  ]
  if ([ site1-bound ] of xsyk != nobody and [site2-bound] of xsyk = nobody) or
     ([ site1-bound ] of xsyk = nobody and [site2-bound] of xsyk != nobody)   ; S1
  [
    if random-float 100 < reverse-rate-for-theme-9
    [ report true]
  ]
  report false
end


to-report dissociate-receptor-and-ligand?
  if random-float 100 < reverse-rate-for-theme-8
  [ report true]
  report false
end

to-report dissociate-receptor-and-receptor?
  if random-float 100 < reverse-rate-for-theme-2
  [ report true]
  report false
end


to reverse-logic-for-syks
  let processed? false
  if kinectically-active? or site1-bound != nobody or  site2-bound != nobody
  [
    ifelse kinectically-active? ; S3
    [
      if site1-bound != nobody and  site2-bound != nobody and make-syk-inactive?
      [
        set kinectically-active? false
        set element-state get-syk-element-state
        set color get-color
        update-molecule
        set processed? true
      ]
    ]
    [
      if site1-bound != nobody and  site2-bound != nobody and dissociate-one-site?
      [
        ; selecting the receptor connected to site1 or site2 randomly.
        ; the following command select site1 or site2 with 50% chance
        let connected-receptor  site1-bound
        if random 100 < 50
        [ set connected-receptor  site2-bound]
        ask connected-receptor
        [
          set protein-bound nobody
          if ligand-bound = nobody and empty? receptor-bound
          [
            set product-id self
          ]
          set element-state get-receptor-element-state
          set color get-color
        ]
        ifelse product-id = [product-id] of connected-receptor
        [
          ifelse connected-receptor =  site1-bound
          [
            set site1-bound nobody
            set product-id site2-bound
          ]
          [
            set site2-bound nobody
            set product-id site1-bound
          ]
          set element-state get-syk-element-state
          set color get-color
        ]
        [
          ifelse connected-receptor =  site1-bound
          [
            set site1-bound nobody
          ]
          [
            set site2-bound nobody
          ]
          set element-state get-syk-element-state
          set color get-color
        ]
        update-molecule
        ask connected-receptor [ update-molecule ]
      ]
      if ((site1-bound = nobody and  site2-bound != nobody) or
      (site1-bound != nobody and  site2-bound = nobody)) and detach-syk?
      [
        let connected-receptor nobody
        ifelse site1-bound != nobody [ set connected-receptor site1-bound set site1-bound  nobody]
        [if site2-bound != nobody [ set connected-receptor site2-bound set site2-bound  nobody]]
        set element-state get-syk-element-state
        set color get-color
        set product-id self
        ask connected-receptor
        [
          set protein-bound nobody
          if ligand-bound = nobody and empty? receptor-bound
          [
            set product-id self
          ]
          set element-state get-receptor-element-state
          set color get-color
          update-molecule
        ]
        update-molecule
      ]
    ]
  ]
end

to-report make-syk-inactive?
  if random-float 100 < reverse-rate-for-theme-3
  [
    report true
  ]
  report false
end

to-report dissociate-one-site?
  if random-float 100 < reverse-rate-for-theme-4
  [
    report true
  ]
  report false
end

to-report detach-syk?
  if random-float 100 < reverse-rate-for-theme-9
  [
    report true
  ]
  report false
end

to reverse-logic-for-ligands
  let processed? false
  ifelse is-dimer?
  [
    if [receptor-bound] of l1 != nobody or [receptor-bound] of l2 != nobody
    [
      if [receptor-bound] of l1 != nobody and [receptor-bound] of l2 != nobody and dissociate-one-receptor?
      [
        let connected-receptor [receptor-bound] of l1
        if random 100 < 50
        [ set connected-receptor [receptor-bound] of l2]
        ask connected-receptor
        [
          set ligand-bound nobody
          if protein-bound = nobody and empty? receptor-bound
          [
            set product-id self
          ]
          set element-state get-receptor-element-state
          set color get-color
        ]
        ifelse product-id = [product-id] of connected-receptor
        [
          ifelse connected-receptor =  [receptor-bound] of l1
          [
            ask l1
            [ set receptor-bound nobody
              set product-id [receptor-bound] of l2
            ]
          ]
          [
            ask l2
            [ set receptor-bound nobody
              set product-id [receptor-bound] of l1
            ]
          ]
          set element-state get-dimer-element-state
          set color get-color
        ]
        [
          ifelse connected-receptor =  [receptor-bound] of l1
          [
            ask l1 [
              set receptor-bound nobody
            ]
          ]
          [
            ask l2 [
              set receptor-bound nobody
            ]
          ]
          set element-state get-dimer-element-state
          set color get-color
        ]
        update-molecule
        ask connected-receptor [ update-molecule ]
        set processed? true
      ]

      if (([receptor-bound] of l1 != nobody and [receptor-bound] of l2 = nobody) or
        ([receptor-bound] of l1 = nobody and [receptor-bound] of l2 != nobody)) and dissociate-one-receptor? and not processed?
      [
        let connected-receptor nobody
        ifelse [receptor-bound] of l1 != nobody [ ask l1 [ set connected-receptor receptor-bound set receptor-bound  nobody] ]
        [ if [receptor-bound] of l2 != nobody [ ask l2 [ set connected-receptor receptor-bound set receptor-bound  nobody]]]
        set element-state get-dimer-element-state
        set color get-color
        set product-id self
        ask connected-receptor
        [
          set ligand-bound nobody
          if protein-bound = nobody and empty? receptor-bound
          [
            set product-id self
          ]
          set element-state get-receptor-element-state
          set color get-color
          update-molecule
        ]
        update-molecule
        set processed? true
      ]
    ]
  ]
  [
    if receptor-bound != nobody or not empty? ligand-bound
    [
      if receptor-bound != nobody and dissociate-one-receptor?
      [
        let connected-receptor receptor-bound
        set receptor-bound nobody
        set element-state get-ligand-element-state
        set color get-color
        ifelse empty? ligand-bound [ set product-id self ]
        [ask turtles with [ product-id = [product-id] of myself] [set product-id [self] of myself ]]
        ask connected-receptor
        [
          set ligand-bound nobody
          if protein-bound = nobody and empty? receptor-bound
          [
            set product-id self
          ]
          set element-state get-receptor-element-state
          set color get-color
          update-molecule
        ]
        update-molecule
        set processed? true
      ]
      if not empty? ligand-bound and not processed?
      [
        let connected-ligands  ligand-bound
        let me self
        if receptor-bound = nobody and dissociate-ligands?
        [
          let current-product-id [product-id] of one-of ligand-bound
          let new-product-id current-product-id
          if current-product-id = self
          [
            set new-product-id [self] of one-of ligand-bound
          ]
          set ligand-bound []
          foreach connected-ligands
          [
            c-l ->
            ask c-l
            [
              ifelse  member? me ligand-bound
              [ set ligand-bound remove me ligand-bound ]
              [ show "not member ligand" ]
            ]

          ]
          ask turtles with [product-id = current-product-id ]
          [
            set product-id new-product-id
          ]
          set product-id self
          set molecule get-molecule-name product-id
          ask turtles with [product-id = new-product-id ]
          [
            set molecule get-molecule-name product-id
          ]
          set processed? true
        ]
      ]

    ]
  ]

end

to-report dissociate-one-receptor?
  if random-float 100 < reverse-rate-for-theme-8
  [
    report true
  ]
  report false
end

to-report  dissociate-ligands?
  if random-float 100 < reverse-rate-for-theme-6
  [
    report true
  ]
  report false
end
;----------------------------------------------------------------------------
; Output csv file
;----------------------------------------------------------------------------
to write-into-file
  let file-name (word "Reporting.csv" )
  let need-header? true
  let header ""
  let line ""
  let product-num 0
  let needed-values [ "TotPhosReceptors" "ClusterNumber" "MeanCluster" "TotPhosReceptorsInCluster" "TotPhosReceptorsOutCluster" "TotalSykInCluster" "TotSykOutCluster" ]
  if file-exists? file-name [ set need-header? false ]
  file-open file-name
  if need-header? = true [
    set header "RunNumber, TimeStep,"
    foreach needed-values
    [ value ->
      set header (word header "," value)
    ]
    file-print header
  ]
  let cluster-details cluster-number
  let num-clusters item 0 cluster-details
  let mean-size item 1 cluster-details
  set line (word behaviorspace-run-number "," ticks "," tot-phos-receptors ","  num-clusters "," mean-size ","  receptors-in-cluster "," receptors-out-cluster "," double-syks-in-cluster "," double-syks-out-cluster)
  file-print line
  file-close
end


to-report tot-phos-receptors
  ; report count receptors with [element-state = "R1" or element-state = "R3" or element-state = "R4" or element-state = "R5"  ]
  report count receptors with [ phosphorylated? ]
end

to-report cluster-number
  let cluster-count 0
  let unique-products []
  let size-of-cluster []
  ask turtles
  [
    let size-cluster count turtles with [product-id = [product-id] of myself]
    if is-receptor? self
    [
      if not member? product-id unique-products and ( size-cluster > 4 )
      [
        set cluster-count (cluster-count + 1)
        set size-of-cluster lput size-cluster size-of-cluster
        set unique-products lput product-id unique-products
      ]
    ]
    if is-syk? self
    [
      if not member? product-id unique-products and ( size-cluster > 4 )
      [
        set cluster-count (cluster-count + 1)
        set size-of-cluster lput size-cluster size-of-cluster
        set unique-products lput product-id unique-products
      ]
    ]
    if is-ligand? self
    [
      ifelse is-dimer?
      [
        if not member? product-id unique-products and ( size-cluster > 2 )
        [
          let count-dimer count ligands with [product-id = [product-id] of myself and is-dimer?]
          set cluster-count (cluster-count + 1)
          set size-of-cluster lput (size-cluster - count-dimer) size-of-cluster
          set unique-products lput product-id unique-products
        ]
      ]
      [
        if not member? product-id unique-products and ( size-cluster > 1 )
        [
          set cluster-count (cluster-count + 1)
          set size-of-cluster lput size-cluster size-of-cluster
          set unique-products lput product-id unique-products
        ]
      ]
    ]
  ]
  let total-size 0
  foreach size-of-cluster
  [
    sc -> set total-size total-size + sc
  ]
  let mean-size 0
  if cluster-count > 0
  [ set  mean-size total-size / cluster-count ]
  report (list cluster-count mean-size )
end

to-report receptors-in-cluster
  report count receptors with [ phosphorylated? and molecule != element-state and ((length (word molecule)) > 8) ]
end

to-report receptors-out-cluster
  report count receptors with [ phosphorylated? and  molecule = element-state ]
end


to-report double-syks-in-cluster
  report count syks with [ site1-bound != nobody and site2-bound != nobody and molecule != element-state and ((length (word molecule)) > 8)]
end

to-report double-syks-out-cluster
  report count syks with [ site1-bound != nobody and site2-bound != nobody and   molecule = element-state ]
end

;to write-into-file
;  let file-name (word "element-count.csv" )
;  let need-header? true
;  let header ""
;  let line ""
;  let product-num 0
;  let element-list ["L0" "L1" "R0" "R1" "R2" "R3" "R4" "R5" "S0" "S1" "S2" "S3" "S4" "S5"]
;  if file-exists? file-name [ set need-header? false ]
;  file-open file-name
;  if need-header? = true [
;    set header "RunNumber, TimeStep, Molecule"
;    foreach element-list
;    [ element ->
;      set header (word header "," element)
;    ]
;    file-print header
;  ]
;  let unique-products get-unique-molecules
;  foreach unique-products
;  [ upid ->
;    let product [molecule] of upid
;    set line (word behaviorspace-run-number "," ticks "," product)
;    foreach element-list
;    [ element ->
;      set line (word line "," get-count-element upid element)
;    ]
;    file-print line
;  ]
;  file-close
;end
;
;
;to-report get-count-element [ xproduct xelement ]
;  report count turtles with [element-state = xelement and product-id =  xproduct ]
;end
@#$#@#$#@
GRAPHICS-WINDOW
552
10
1380
839
-1
-1
20.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
13
12
185
45
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
194
12
365
45
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
13
49
185
82
L
L
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
193
49
365
82
R
R
0
1000
320.0
80
1
NIL
HORIZONTAL

SLIDER
193
85
365
118
S
S
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
212
146
363
179
rate-for-theme-1
rate-for-theme-1
0
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
373
145
548
178
reverse-rate-for-theme-1
reverse-rate-for-theme-1
0
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
213
181
364
214
rate-for-theme-2
rate-for-theme-2
0
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
213
218
365
251
rate-for-theme-3
rate-for-theme-3
0
100
5.0
1
1
NIL
HORIZONTAL

TEXTBOX
273
124
423
142
Forward
11
0.0
1

TEXTBOX
438
123
588
141
Reverse
11
0.0
1

SLIDER
213
254
366
287
rate-for-theme-4
rate-for-theme-4
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
13
85
185
118
LL
LL
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
213
289
367
322
rate-for-theme-5
rate-for-theme-5
0
100
61.0
1
1
NIL
HORIZONTAL

SLIDER
213
325
368
358
rate-for-theme-6
rate-for-theme-6
0
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
146
857
318
890
rate-for-theme-7
rate-for-theme-7
0
100
86.0
1
1
NIL
HORIZONTAL

SLIDER
214
362
369
395
rate-for-theme-8
rate-for-theme-8
0
100
54.0
1
1
NIL
HORIZONTAL

SLIDER
214
399
368
432
rate-for-theme-9
rate-for-theme-9
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
214
434
368
467
rate-for-theme-10
rate-for-theme-10
0
100
69.0
1
1
NIL
HORIZONTAL

SLIDER
373
181
548
214
reverse-rate-for-theme-2
reverse-rate-for-theme-2
0
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
374
217
548
250
reverse-rate-for-theme-3
reverse-rate-for-theme-3
0
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
374
254
548
287
reverse-rate-for-theme-4
reverse-rate-for-theme-4
0
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
374
290
548
323
reverse-rate-for-theme-5
reverse-rate-for-theme-5
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
373
327
548
360
reverse-rate-for-theme-6
reverse-rate-for-theme-6
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
323
857
515
890
reverse-rate-for-theme-7
reverse-rate-for-theme-7
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
373
362
548
395
reverse-rate-for-theme-8
reverse-rate-for-theme-8
0
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
373
398
547
431
reverse-rate-for-theme-9
reverse-rate-for-theme-9
0
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
373
434
548
467
reverse-rate-for-theme-10
reverse-rate-for-theme-10
0
100
9.0
1
1
NIL
HORIZONTAL

SWITCH
117
147
207
180
theme-1
theme-1
1
1
-1000

SWITCH
118
182
208
215
theme-2
theme-2
0
1
-1000

SWITCH
118
217
208
250
theme-3
theme-3
1
1
-1000

SWITCH
118
253
208
286
theme-4
theme-4
1
1
-1000

SWITCH
117
289
207
322
theme-5
theme-5
1
1
-1000

SWITCH
118
325
208
358
theme-6
theme-6
1
1
-1000

SWITCH
39
857
142
890
theme-7
theme-7
1
1
-1000

SWITCH
119
362
209
395
theme-8
theme-8
1
1
-1000

SWITCH
119
398
209
431
theme-9
theme-9
1
1
-1000

SWITCH
118
434
210
467
theme-10
theme-10
1
1
-1000

MONITOR
513
833
653
894
Products 
length get-unique-product-id
17
1
15

SWITCH
405
14
546
47
slowing-region?
slowing-region?
1
1
-1000

SLIDER
405
50
546
83
slow-area
slow-area
0
100
25.0
5
1
%
HORIZONTAL

SLIDER
405
85
547
118
coefficient-of-diffusion
coefficient-of-diffusion
0
1
0.056
.0001
1
NIL
HORIZONTAL

TEXTBOX
18
154
120
172
Basal phospho-R
11
0.0
1

TEXTBOX
18
190
105
208
R dimerisation\n
11
0.0
1

TEXTBOX
18
225
105
243
S activation
11
0.0
1

TEXTBOX
18
261
113
289
S attachment: 2\n\n
11
0.0
1

TEXTBOX
19
408
121
426
S attachment: 1\n
11
0.0
1

TEXTBOX
19
364
100
392
LR complex\nformation\n
11
0.0
1

TEXTBOX
19
436
111
464
Phosphorylation by S\n
11
0.0
1

TEXTBOX
19
335
92
353
L dimerisation\n
11
0.0
1

TEXTBOX
18
296
102
324
Phosphorylation by L\n
11
0.0
1

MONITOR
227
474
367
535
Number of Clusters
item 0 cluster-number
17
1
15

PLOT
14
545
505
829
Reporting
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Cluster Number" 1.0 0 -5298144 true "" "plot item 0 cluster-number"
"Mean Size" 1.0 0 -4079321 true "" "plot item 1 cluster-number"
"Phos. Receptors in Cluster" 1.0 0 -13840069 true "" "plot receptors-in-cluster"
"Phos Receptors Out Cluster" 1.0 0 -7500403 true "" "plot receptors-out-cluster"
"Double Syks in Cluster " 1.0 0 -2674135 true "" "plot double-syks-in-cluster"
"Double Syks Out Cluster" 1.0 0 -955883 true "" "plot double-syks-out-cluster"
"Total Phos Receptors" 1.0 0 -6759204 true "" "plot count receptors with [ phosphorylated? ]"

CHOOSER
121
485
213
530
limit-rr-links
limit-rr-links
1 2 "unlimited"
2

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

acorn
false
0
Polygon -7500403 true true 146 297 120 285 105 270 75 225 60 180 60 150 75 105 225 105 240 150 240 180 225 225 195 270 180 285 155 297
Polygon -6459832 true false 121 15 136 58 94 53 68 65 46 90 46 105 75 115 234 117 256 105 256 90 239 68 209 57 157 59 136 8
Circle -16777216 false false 223 95 18
Circle -16777216 false false 219 77 18
Circle -16777216 false false 205 88 18
Line -16777216 false 214 68 223 71
Line -16777216 false 223 72 225 78
Line -16777216 false 212 88 207 82
Line -16777216 false 206 82 195 82
Line -16777216 false 197 114 201 107
Line -16777216 false 201 106 193 97
Line -16777216 false 198 66 189 60
Line -16777216 false 176 87 180 80
Line -16777216 false 157 105 161 98
Line -16777216 false 158 65 150 56
Line -16777216 false 180 79 172 70
Line -16777216 false 193 73 197 66
Line -16777216 false 237 82 252 84
Line -16777216 false 249 86 253 97
Line -16777216 false 240 104 252 96

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

airplane 2
true
0
Polygon -7500403 true true 150 26 135 30 120 60 120 90 18 105 15 135 120 150 120 165 135 210 135 225 150 285 165 225 165 210 180 165 180 150 285 135 282 105 180 90 180 60 165 30
Line -7500403 false 120 30 180 30
Polygon -7500403 true true 105 255 120 240 180 240 195 255 180 270 120 270

ambulance
false
0
Rectangle -7500403 true true 30 90 210 195
Polygon -7500403 true true 296 190 296 150 259 134 244 104 210 105 210 190
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Circle -16777216 true false 69 174 42
Rectangle -1 true false 288 158 297 173
Rectangle -1184463 true false 289 180 298 172
Rectangle -2674135 true false 29 151 298 158
Line -16777216 false 210 90 210 195
Rectangle -16777216 true false 83 116 128 133
Rectangle -16777216 true false 153 111 176 134
Line -7500403 true 165 105 165 135
Rectangle -7500403 true true 14 186 33 195
Line -13345367 false 45 135 75 120
Line -13345367 false 75 135 45 120
Line -13345367 false 60 112 60 142

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

ant 2
true
0
Polygon -7500403 true true 150 19 120 30 120 45 130 66 144 81 127 96 129 113 144 134 136 185 121 195 114 217 120 255 135 270 165 270 180 255 188 218 181 195 165 184 157 134 170 115 173 95 156 81 171 66 181 42 180 30
Polygon -7500403 true true 150 167 159 185 190 182 225 212 255 257 240 212 200 170 154 172
Polygon -7500403 true true 161 167 201 150 237 149 281 182 245 140 202 137 158 154
Polygon -7500403 true true 155 135 185 120 230 105 275 75 233 115 201 124 155 150
Line -7500403 true 120 36 75 45
Line -7500403 true 75 45 90 15
Line -7500403 true 180 35 225 45
Line -7500403 true 225 45 210 15
Polygon -7500403 true true 145 135 115 120 70 105 25 75 67 115 99 124 145 150
Polygon -7500403 true true 139 167 99 150 63 149 19 182 55 140 98 137 142 154
Polygon -7500403 true true 150 167 141 185 110 182 75 212 45 257 60 212 100 170 146 172

apple
false
0
Polygon -7500403 true true 33 58 0 150 30 240 105 285 135 285 150 270 165 285 195 285 255 255 300 150 268 62 226 43 194 36 148 32 105 35
Line -16777216 false 106 55 151 62
Line -16777216 false 157 62 209 57
Polygon -6459832 true false 152 62 158 62 160 46 156 30 147 18 132 26 142 35 148 46
Polygon -16777216 false false 132 25 144 38 147 48 151 62 158 63 159 47 155 30 147 18

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

arrow 2
true
0
Polygon -7500403 true true 150 0 0 150 120 150 120 293 180 293 180 150 300 150

arrow 3
true
0
Polygon -7500403 true true 135 255 105 300 105 225 135 195 135 75 105 90 150 0 195 90 165 75 165 195 195 225 195 300 165 255

ball baseball
false
0
Circle -7500403 true true 30 30 240
Polygon -2674135 true false 247 79 243 86 237 106 232 138 232 167 235 199 239 215 244 225 236 234 229 221 224 196 220 163 221 138 227 102 234 83 240 71
Polygon -2674135 true false 53 79 57 86 63 106 68 138 68 167 65 199 61 215 56 225 64 234 71 221 76 196 80 163 79 138 73 102 66 83 60 71
Line -2674135 false 241 149 210 149
Line -2674135 false 59 149 90 149
Line -2674135 false 241 171 212 176
Line -2674135 false 246 191 218 203
Line -2674135 false 251 207 227 226
Line -2674135 false 251 93 227 74
Line -2674135 false 246 109 218 97
Line -2674135 false 241 129 212 124
Line -2674135 false 59 171 88 176
Line -2674135 false 59 129 88 124
Line -2674135 false 54 109 82 97
Line -2674135 false 49 93 73 74
Line -2674135 false 54 191 82 203
Line -2674135 false 49 207 73 226

ball basketball
false
0
Circle -7500403 true true 26 26 247
Polygon -16777216 false false 30 150 30 165 45 195 75 225 120 240 180 240 225 225 255 195 270 165 270 150 270 135 255 105 225 75 180 60 120 60 75 75 45 105 30 135
Line -16777216 false 30 150 270 150
Circle -16777216 false false 26 26 247

ball football
false
0
Polygon -7500403 false true 301 133 301 164 275 192 229 224 167 236 137 236 74 224 30 194 3 162 2 138 30 104 76 74 134 62 168 62 228 74 274 105
Polygon -7500403 true true 300 150 300 165 270 195 225 225 163 236 134 236 75 225 30 195 2 162 2 140 30 105 75 75 136 63 165 63 225 75 270 105 300 135
Line -16777216 false 300 155 5 155
Polygon -1 true false 28 193 28 107 51 91 51 209
Rectangle -1 true false 90 150 210 160
Rectangle -1 true false 198 141 205 170
Rectangle -1 true false 183 141 190 170
Rectangle -1 true false 168 141 175 170
Rectangle -1 true false 153 141 160 170
Rectangle -1 true false 138 141 145 170
Rectangle -1 true false 123 141 130 170
Rectangle -1 true false 108 141 115 170
Rectangle -1 true false 93 141 100 170
Polygon -1 true false 272 193 272 107 249 91 249 209

ball tennis
false
0
Circle -7500403 true true 30 30 240
Circle -7500403 false true 30 30 240
Polygon -16777216 true false 50 82 54 90 59 107 64 140 64 164 63 189 59 207 54 222 68 236 76 220 81 195 84 163 83 139 78 102 72 83 63 67
Polygon -16777216 true false 250 82 246 90 241 107 236 140 236 164 237 189 241 207 246 222 232 236 224 220 219 195 216 163 217 139 222 102 228 83 237 67
Polygon -1 true false 247 79 243 86 237 106 232 138 232 167 235 199 239 215 244 225 236 234 229 221 224 196 220 163 221 138 227 102 234 83 240 71
Polygon -1 true false 53 79 57 86 63 106 68 138 68 167 65 199 61 215 56 225 64 234 71 221 76 196 80 163 79 138 73 102 66 83 60 71

balloon
false
0
Circle -7500403 true true 73 0 152
Polygon -7500403 true true 219 104 205 133 185 165 174 190 165 210 165 225 150 225 147 119
Polygon -7500403 true true 79 103 95 133 115 165 126 190 135 210 135 225 150 225 154 120
Rectangle -6459832 true false 129 241 173 273
Line -16777216 false 135 225 135 240
Line -16777216 false 165 225 165 240
Line -16777216 false 150 225 150 240

ballpin
false
0
Polygon -1 true false 150 135 150 150 165 150 255 60 240 45 150 135
Circle -7500403 true true 181 31 86

banana
false
0
Polygon -7500403 false true 25 78 29 86 30 95 27 103 17 122 12 151 18 181 39 211 61 234 96 247 155 259 203 257 243 245 275 229 288 205 284 192 260 188 249 187 214 187 188 188 181 189 144 189 122 183 107 175 89 158 69 126 56 95 50 83 38 68
Polygon -7500403 true true 39 69 26 77 30 88 29 103 17 124 12 152 18 179 34 205 60 233 99 249 155 260 196 259 237 248 272 230 289 205 284 194 264 190 244 188 221 188 185 191 170 191 145 190 123 186 108 178 87 157 68 126 59 103 52 88
Line -16777216 false 54 169 81 195
Line -16777216 false 75 193 82 199
Line -16777216 false 99 211 118 217
Line -16777216 false 241 211 254 210
Line -16777216 false 261 224 276 214
Polygon -16777216 true false 283 196 273 204 287 208
Polygon -16777216 true false 36 114 34 129 40 136
Polygon -16777216 true false 46 146 53 161 53 152
Line -16777216 false 65 132 82 162
Line -16777216 false 156 250 199 250
Polygon -16777216 true false 26 77 30 90 50 85 39 69

bee
true
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

bee 2
true
0
Polygon -1184463 true false 195 150 105 150 90 165 90 225 105 270 135 300 165 300 195 270 210 225 210 165 195 150
Rectangle -16777216 true false 90 165 212 185
Polygon -16777216 true false 90 207 90 226 210 226 210 207
Polygon -16777216 true false 103 266 198 266 203 246 96 246
Polygon -6459832 true false 120 150 105 135 105 75 120 60 180 60 195 75 195 135 180 150
Polygon -6459832 true false 150 15 120 30 120 60 180 60 180 30
Circle -16777216 true false 105 30 30
Circle -16777216 true false 165 30 30
Polygon -7500403 true true 120 90 75 105 15 90 30 75 120 75
Polygon -16777216 false false 120 75 30 75 15 90 75 105 120 90
Polygon -7500403 true true 180 75 180 90 225 105 285 90 270 75
Polygon -16777216 false false 180 75 270 75 285 90 225 105 180 90
Polygon -7500403 true true 180 75 180 90 195 105 240 195 270 210 285 210 285 150 255 105
Polygon -16777216 false false 180 75 255 105 285 150 285 210 270 210 240 195 195 105 180 90
Polygon -7500403 true true 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 false false 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 true false 135 300 165 300 180 285 120 285

bike
false
1
Line -7500403 false 163 183 228 184
Circle -7500403 false false 213 184 22
Circle -7500403 false false 156 187 16
Circle -16777216 false false 28 148 95
Circle -16777216 false false 24 144 102
Circle -16777216 false false 174 144 102
Circle -16777216 false false 177 148 95
Polygon -2674135 true true 75 195 90 90 98 92 97 107 192 122 207 83 215 85 202 123 211 133 225 195 165 195 164 188 214 188 202 133 94 116 82 195
Polygon -2674135 true true 208 83 164 193 171 196 217 85
Polygon -2674135 true true 165 188 91 120 90 131 164 196
Line -7500403 false 159 173 170 219
Line -7500403 false 155 172 166 172
Line -7500403 false 166 219 177 219
Polygon -16777216 true false 187 92 198 92 208 97 217 100 231 93 231 84 216 82 201 83 184 85
Polygon -7500403 true true 71 86 98 93 101 85 74 81
Rectangle -16777216 true false 75 75 75 90
Polygon -16777216 true false 70 87 70 72 78 71 78 89
Circle -7500403 false false 153 184 22
Line -7500403 false 159 206 228 205

bird
false
0
Polygon -7500403 true true 135 165 90 270 120 300 180 300 210 270 165 165
Rectangle -7500403 true true 120 105 180 237
Polygon -7500403 true true 135 105 120 75 105 45 121 6 167 8 207 25 257 46 180 75 165 105
Circle -16777216 true false 128 21 42
Polygon -7500403 true true 163 116 194 92 212 86 230 86 250 90 265 98 279 111 290 126 296 143 298 158 298 166 296 183 286 204 272 219 259 227 235 240 241 223 250 207 251 192 245 180 232 168 216 162 200 162 186 166 175 173 171 180
Polygon -7500403 true true 137 116 106 92 88 86 70 86 50 90 35 98 21 111 10 126 4 143 2 158 2 166 4 183 14 204 28 219 41 227 65 240 59 223 50 207 49 192 55 180 68 168 84 162 100 162 114 166 125 173 129 180

bird 2
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

bird 3
false
0
Polygon -7500403 true true 2 4 33 4 298 270 298 298 272 298 155 184 117 289 61 295 61 105 0 43

bird side
false
0
Polygon -7500403 true true 0 120 45 90 75 90 105 120 150 120 240 135 285 120 285 135 300 150 240 150 195 165 255 195 210 195 150 210 90 195 60 180 45 135
Circle -16777216 true false 38 98 14

boat
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat 2
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 157 54 175 79 174 96 185 102 178 112 194 124 196 131 190 139 192 146 211 151 216 154 157 154
Polygon -7500403 true true 150 74 146 91 139 99 143 114 141 123 137 126 131 129 132 139 142 136 126 142 119 147 148 147

boat 3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

boat top
true
0
Polygon -7500403 true true 150 1 137 18 123 46 110 87 102 150 106 208 114 258 123 286 175 287 183 258 193 209 198 150 191 87 178 46 163 17
Rectangle -16777216 false false 129 92 170 178
Rectangle -16777216 false false 120 63 180 93
Rectangle -7500403 true true 133 89 165 165
Polygon -11221820 true false 150 60 105 105 150 90 195 105
Polygon -16777216 false false 150 60 105 105 150 90 195 105
Rectangle -16777216 false false 135 178 165 262
Polygon -16777216 false false 134 262 144 286 158 286 166 262
Line -16777216 false 129 149 171 149
Line -16777216 false 166 262 188 252
Line -16777216 false 134 262 112 252
Line -16777216 false 150 2 149 62

book
false
0
Polygon -7500403 true true 30 195 150 255 270 135 150 75
Polygon -7500403 true true 30 135 150 195 270 75 150 15
Polygon -7500403 true true 30 135 30 195 90 150
Polygon -1 true false 39 139 39 184 151 239 156 199
Polygon -1 true false 151 239 254 135 254 90 151 197
Line -7500403 true 150 196 150 247
Line -7500403 true 43 159 138 207
Line -7500403 true 43 174 138 222
Line -7500403 true 153 206 248 113
Line -7500403 true 153 221 248 128
Polygon -1 true false 159 52 144 67 204 97 219 82

bottle
false
0
Circle -7500403 true true 90 240 60
Rectangle -1 true false 135 8 165 31
Line -7500403 true 123 30 175 30
Circle -7500403 true true 150 240 60
Rectangle -7500403 true true 90 105 210 270
Rectangle -7500403 true true 120 270 180 300
Circle -7500403 true true 90 45 120
Rectangle -7500403 true true 135 27 165 51

bowling pin
false
0
Polygon -7500403 true true 132 285 117 256 105 210 105 165 121 135 136 90 136 75 126 32 125 14 134 5 151 0 168 4 177 12 176 32 166 75 166 90 181 135 195 165 195 210 184 256 170 285
Polygon -2674135 true false 134 68 132 59 170 59 168 68
Polygon -2674135 true false 136 84 135 94 167 94 166 84

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

box 2
false
0
Polygon -7500403 true true 150 285 270 225 270 90 150 150
Polygon -13791810 true false 150 150 30 90 150 30 270 90
Polygon -13345367 true false 30 90 30 225 150 285 150 150

bread
false
0
Polygon -16777216 true false 140 145 170 250 245 190 234 122 247 107 260 79 260 55 245 40 215 32 185 40 155 31 122 41 108 53 28 118 110 115 140 130
Polygon -7500403 true true 135 151 165 256 240 196 225 121 241 105 255 76 255 61 240 46 210 38 180 46 150 37 120 46 105 61 47 108 105 121 135 136
Polygon -1 true false 60 181 45 256 165 256 150 181 165 166 180 136 180 121 165 106 135 98 105 106 75 97 46 107 29 118 30 136 45 166 60 181
Polygon -16777216 false false 45 255 165 255 150 180 165 165 180 135 180 120 165 105 135 97 105 105 76 96 46 106 29 118 30 135 45 165 60 180
Line -16777216 false 165 255 239 195

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

bulldozer top
true
0
Rectangle -7500403 true true 195 60 255 255
Rectangle -16777216 false false 195 60 255 255
Rectangle -7500403 true true 45 60 105 255
Rectangle -16777216 false false 45 60 105 255
Line -16777216 false 45 75 255 75
Line -16777216 false 45 105 255 105
Line -16777216 false 45 60 255 60
Line -16777216 false 45 240 255 240
Line -16777216 false 45 225 255 225
Line -16777216 false 45 195 255 195
Line -16777216 false 45 150 255 150
Polygon -1184463 true true 90 60 75 90 75 240 120 255 180 255 225 240 225 90 210 60
Polygon -16777216 false false 225 90 210 60 211 246 225 240
Polygon -16777216 false false 75 90 90 60 89 246 75 240
Polygon -16777216 false false 89 247 116 254 183 255 211 246 211 211 90 210
Rectangle -16777216 false false 90 60 210 90
Rectangle -1184463 true true 180 30 195 90
Rectangle -16777216 false false 105 30 120 90
Rectangle -1184463 true true 105 45 120 90
Rectangle -16777216 false false 180 45 195 90
Polygon -16777216 true false 195 105 180 120 120 120 105 105
Polygon -16777216 true false 105 199 120 188 180 188 195 199
Polygon -16777216 true false 195 120 180 135 180 180 195 195
Polygon -16777216 true false 105 120 120 135 120 180 105 195
Line -1184463 true 105 165 195 165
Circle -16777216 true false 113 226 14
Polygon -1184463 true true 105 15 60 30 60 45 240 45 240 30 195 15
Polygon -16777216 false false 105 15 60 30 60 45 240 45 240 30 195 15

bus
false
0
Polygon -7500403 true true 15 206 15 150 15 120 30 105 270 105 285 120 285 135 285 206 270 210 30 210
Rectangle -16777216 true false 36 126 231 159
Line -7500403 false 60 135 60 165
Line -7500403 false 60 120 60 165
Line -7500403 false 90 120 90 165
Line -7500403 false 120 120 120 165
Line -7500403 false 150 120 150 165
Line -7500403 false 180 120 180 165
Line -7500403 false 210 120 210 165
Line -7500403 false 240 135 240 165
Rectangle -16777216 true false 15 174 285 182
Circle -16777216 true false 48 187 42
Rectangle -16777216 true false 240 127 276 205
Circle -16777216 true false 195 187 42
Line -7500403 false 257 120 257 207

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

butterfly 2
true
0
Polygon -16777216 true false 151 76 138 91 138 284 150 296 162 286 162 91
Polygon -7500403 true true 164 106 184 79 205 61 236 48 259 53 279 86 287 119 289 158 278 177 256 182 164 181
Polygon -7500403 true true 136 110 119 82 110 71 85 61 59 48 36 56 17 88 6 115 2 147 15 178 134 178
Polygon -7500403 true true 46 181 28 227 50 255 77 273 112 283 135 274 135 180
Polygon -7500403 true true 165 185 254 184 272 224 255 251 236 267 191 283 164 276
Line -7500403 true 167 47 159 82
Line -7500403 true 136 47 145 81
Circle -7500403 true true 165 45 8
Circle -7500403 true true 134 45 6
Circle -7500403 true true 133 44 7
Circle -7500403 true true 133 43 8

cactus
false
0
Polygon -7500403 true true 130 300 124 206 110 207 94 201 81 183 75 171 74 95 79 79 88 74 97 79 100 95 101 151 104 169 115 180 126 169 129 31 132 19 145 16 153 20 158 32 162 142 166 149 177 149 185 137 185 119 189 108 199 103 212 108 215 121 215 144 210 165 196 177 176 181 164 182 159 302
Line -16777216 false 142 32 146 143
Line -16777216 false 148 179 143 300
Line -16777216 false 123 191 114 197
Line -16777216 false 113 199 96 188
Line -16777216 false 95 188 84 168
Line -16777216 false 83 168 82 103
Line -16777216 false 201 147 202 123
Line -16777216 false 190 162 199 148
Line -16777216 false 174 164 189 163

campsite
false
0
Polygon -7500403 true true 150 11 30 221 270 221
Polygon -16777216 true false 151 90 92 221 212 221
Line -7500403 true 150 30 150 225

cannon
true
0
Polygon -7500403 true true 165 0 165 15 180 150 195 165 195 180 180 195 165 225 135 225 120 195 105 180 105 165 120 150 135 15 135 0
Line -16777216 false 120 150 180 150
Line -16777216 false 120 195 180 195
Line -16777216 false 165 15 135 15
Polygon -16777216 false false 165 0 135 0 135 15 120 150 105 165 105 180 120 195 135 225 165 225 180 195 195 180 195 165 180 150 165 15

cannon carriage
false
0
Circle -7500403 false true 105 105 90
Circle -7500403 false true 90 90 120
Line -7500403 true 180 120 120 180
Line -7500403 true 120 120 180 180
Line -7500403 true 150 105 150 195
Line -7500403 true 105 150 195 150
Polygon -7500403 false true 0 195 0 210 180 150 180 135

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

car side
false
0
Polygon -7500403 true true 19 147 11 125 16 105 63 105 99 79 155 79 180 105 243 111 266 129 253 149
Circle -16777216 true false 43 123 42
Circle -16777216 true false 194 124 42
Polygon -16777216 true false 101 87 73 108 171 108 151 87
Line -8630108 false 121 82 120 108
Polygon -1 true false 242 121 248 128 266 129 247 115
Rectangle -16777216 true false 12 131 28 143

car top
true
0
Polygon -7500403 true true 151 8 119 10 98 25 86 48 82 225 90 270 105 289 150 294 195 291 210 270 219 225 214 47 201 24 181 11
Polygon -16777216 true false 210 195 195 210 195 135 210 105
Polygon -16777216 true false 105 255 120 270 180 270 195 255 195 225 105 225
Polygon -16777216 true false 90 195 105 210 105 135 90 105
Polygon -1 true false 205 29 180 30 181 11
Line -7500403 false 210 165 195 165
Line -7500403 false 90 165 105 165
Polygon -16777216 true false 121 135 180 134 204 97 182 89 153 85 120 89 98 97
Line -16777216 false 210 90 195 30
Line -16777216 false 90 90 105 30
Polygon -1 true false 95 29 120 30 119 11

cat
false
0
Line -7500403 true 285 240 210 240
Line -7500403 true 195 300 165 255
Line -7500403 true 15 240 90 240
Line -7500403 true 285 285 195 240
Line -7500403 true 105 300 135 255
Line -16777216 false 150 270 150 285
Line -16777216 false 15 75 15 120
Polygon -7500403 true true 300 15 285 30 255 30 225 75 195 60 255 15
Polygon -7500403 true true 285 135 210 135 180 150 180 45 285 90
Polygon -7500403 true true 120 45 120 210 180 210 180 45
Polygon -7500403 true true 180 195 165 300 240 285 255 225 285 195
Polygon -7500403 true true 180 225 195 285 165 300 150 300 150 255 165 225
Polygon -7500403 true true 195 195 195 165 225 150 255 135 285 135 285 195
Polygon -7500403 true true 15 135 90 135 120 150 120 45 15 90
Polygon -7500403 true true 120 195 135 300 60 285 45 225 15 195
Polygon -7500403 true true 120 225 105 285 135 300 150 300 150 255 135 225
Polygon -7500403 true true 105 195 105 165 75 150 45 135 15 135 15 195
Polygon -7500403 true true 285 120 270 90 285 15 300 15
Line -7500403 true 15 285 105 240
Polygon -7500403 true true 15 120 30 90 15 15 0 15
Polygon -7500403 true true 0 15 15 30 45 30 75 75 105 60 45 15
Line -16777216 false 164 262 209 262
Line -16777216 false 223 231 208 261
Line -16777216 false 136 262 91 262
Line -16777216 false 77 231 92 261

caterpillar
true
0
Polygon -7500403 true true 165 210 165 225 135 255 105 270 90 270 75 255 75 240 90 210 120 195 135 165 165 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 60 225 105 225 135 210 150 210 165 195 195 180 210
Line -16777216 false 135 255 90 210
Line -16777216 false 165 225 120 195
Line -16777216 false 135 165 180 210
Line -16777216 false 150 150 201 186
Line -16777216 false 165 135 210 150
Line -16777216 false 165 120 225 120
Line -16777216 false 165 106 221 90
Line -16777216 false 157 91 210 60
Line -16777216 false 150 60 180 45
Line -16777216 false 120 30 96 26
Line -16777216 false 124 0 135 15

check
false
0
Polygon -7500403 true true 55 138 22 155 53 196 72 232 91 288 111 272 136 258 147 220 167 174 208 113 280 24 257 7 192 78 151 138 106 213 87 182

checker piece
false
0
Circle -7500403 true true 60 60 180
Circle -16777216 false false 60 60 180
Circle -7500403 true true 75 45 180
Circle -16777216 false false 75 45 180

checker piece 2
false
0
Circle -7500403 true true 60 60 180
Circle -16777216 false false 60 60 180
Circle -7500403 true true 75 45 180
Circle -16777216 false false 83 36 180
Circle -7500403 true true 105 15 180
Circle -16777216 false false 105 15 180

chess bishop
false
0
Circle -7500403 true true 135 35 30
Circle -16777216 false false 135 35 30
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Polygon -7500403 true true 105 255 120 165 180 165 195 255
Polygon -16777216 false false 105 255 120 165 180 165 195 255
Rectangle -7500403 true true 105 165 195 150
Rectangle -16777216 false false 105 150 195 165
Line -16777216 false 137 59 162 59
Polygon -7500403 true true 135 60 120 75 120 105 120 120 105 120 105 90 90 105 90 120 90 135 105 150 195 150 210 135 210 120 210 105 195 90 165 60
Polygon -16777216 false false 135 60 120 75 120 120 105 120 105 90 90 105 90 135 105 150 195 150 210 135 210 105 165 60

chess king
false
0
Polygon -7500403 true true 105 255 120 90 180 90 195 255
Polygon -16777216 false false 105 255 120 90 180 90 195 255
Polygon -7500403 true true 120 85 105 40 195 40 180 85
Polygon -16777216 false false 119 85 104 40 194 40 179 85
Rectangle -7500403 true true 105 105 195 75
Rectangle -16777216 false false 105 75 195 105
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Rectangle -7500403 true true 165 23 134 13
Rectangle -7500403 true true 144 0 154 44
Polygon -16777216 false false 153 0 144 0 144 13 133 13 133 22 144 22 144 41 154 41 154 22 165 22 165 12 153 12

chess knight
false
0
Line -16777216 false 75 255 225 255
Polygon -7500403 true true 90 255 60 255 60 225 75 180 75 165 60 135 45 90 60 75 60 45 90 30 120 30 135 45 240 60 255 75 255 90 255 105 240 120 225 105 180 120 210 150 225 195 225 210 210 255
Polygon -16777216 false false 210 255 60 255 60 225 75 180 75 165 60 135 45 90 60 75 60 45 90 30 120 30 135 45 240 60 255 75 255 90 255 105 240 120 225 105 180 120 210 150 225 195 225 210
Line -16777216 false 255 90 240 90
Circle -16777216 true false 134 63 24
Line -16777216 false 103 34 108 45
Line -16777216 false 80 41 88 49
Line -16777216 false 61 53 70 58
Line -16777216 false 64 75 79 75
Line -16777216 false 53 100 67 98
Line -16777216 false 63 126 69 123
Line -16777216 false 71 148 77 145
Rectangle -7500403 true true 90 255 210 300
Rectangle -16777216 false false 90 255 210 300

chess pawn
false
0
Circle -7500403 true true 105 65 90
Circle -16777216 false false 105 65 90
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Polygon -7500403 true true 105 255 120 165 180 165 195 255
Polygon -16777216 false false 105 255 120 165 180 165 195 255
Rectangle -7500403 true true 105 165 195 150
Rectangle -16777216 false false 105 150 195 165

chess queen
false
0
Circle -7500403 true true 140 11 20
Circle -16777216 false false 139 11 20
Circle -7500403 true true 120 22 60
Circle -16777216 false false 119 20 60
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Polygon -7500403 true true 105 255 120 90 180 90 195 255
Polygon -16777216 false false 105 255 120 90 180 90 195 255
Rectangle -7500403 true true 105 105 195 75
Rectangle -16777216 false false 105 75 195 105
Polygon -7500403 true true 120 75 105 45 195 45 180 75
Polygon -16777216 false false 120 75 105 45 195 45 180 75
Circle -7500403 true true 180 35 20
Circle -16777216 false false 180 35 20
Circle -7500403 true true 140 35 20
Circle -16777216 false false 140 35 20
Circle -7500403 true true 100 35 20
Circle -16777216 false false 99 35 20
Line -16777216 false 105 90 195 90

chess rook
false
0
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Polygon -7500403 true true 90 255 105 105 195 105 210 255
Polygon -16777216 false false 90 255 105 105 195 105 210 255
Rectangle -7500403 true true 75 90 120 60
Rectangle -7500403 true true 75 84 225 105
Rectangle -7500403 true true 135 90 165 60
Rectangle -7500403 true true 180 90 225 60
Polygon -16777216 false false 90 105 75 105 75 60 120 60 120 84 135 84 135 60 165 60 165 84 179 84 180 60 225 60 225 105

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

clock
true
0
Circle -7500403 true true 30 30 240
Polygon -16777216 true false 150 31 128 75 143 75 143 150 158 150 158 75 173 75
Circle -16777216 true false 135 135 30

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

coin heads
false
0
Circle -7500403 true true 15 15 270
Circle -16777216 false false 22 21 256
Line -16777216 false 165 180 192 196
Line -16777216 false 42 140 83 140
Line -16777216 false 37 151 91 151
Line -16777216 false 218 167 265 167
Polygon -16777216 false false 148 265 75 229 86 207 113 191 120 175 109 162 109 136 86 124 137 96 176 93 210 108 222 125 203 157 204 174 190 191 232 230
Polygon -16777216 false false 212 142 182 128 154 132 140 152 149 162 144 182 167 204 187 206 193 193 190 189 202 174 193 158 202 175 204 158
Line -16777216 false 164 154 182 152
Line -16777216 false 193 152 202 153
Polygon -16777216 false false 60 75 75 90 90 75 105 75 90 45 105 45 120 60 135 60 135 45 120 45 105 45 135 30 165 30 195 45 210 60 225 75 240 75 225 75 210 90 225 75 225 60 210 60 195 75 210 60 195 45 180 45 180 60 180 45 165 60 150 60 150 45 165 45 150 45 150 30 135 30 120 60 105 75

coin tails
false
0
Circle -7500403 true true 15 15 270
Circle -16777216 false false 20 17 260
Line -16777216 false 130 92 171 92
Line -16777216 false 123 79 177 79
Rectangle -7500403 true true 57 101 242 133
Rectangle -16777216 false false 45 180 255 195
Rectangle -16777216 false false 75 120 225 135
Polygon -16777216 false false 81 226 70 241 86 248 93 235 89 232 108 243 97 256 118 247 118 265 123 248 142 247 129 253 130 271 145 269 131 259 162 245 153 262 168 268 197 259 177 255 187 245 174 243 193 235 209 251 193 234 225 244 208 227 240 240 222 218
Rectangle -7500403 true true 91 210 222 226
Polygon -16777216 false false 65 70 91 50 136 35 181 35 226 65 246 86 241 65 196 50 166 35 121 50 91 50 61 95 54 80 61 65
Polygon -16777216 false false 90 135 60 135 60 180 90 180 90 135 120 135 120 180 150 180 150 135 180 135 180 180 210 180 210 135 240 135 240 180 210 180 210 135

computer server
false
0
Rectangle -7500403 true true 75 30 225 270
Line -16777216 false 210 30 210 195
Line -16777216 false 90 30 90 195
Line -16777216 false 90 195 210 195
Rectangle -10899396 true false 184 34 200 40
Rectangle -10899396 true false 184 47 200 53
Rectangle -10899396 true false 184 63 200 69
Line -16777216 false 90 210 90 255
Line -16777216 false 105 210 105 255
Line -16777216 false 120 210 120 255
Line -16777216 false 135 210 135 255
Line -16777216 false 165 210 165 255
Line -16777216 false 180 210 180 255
Line -16777216 false 195 210 195 255
Line -16777216 false 210 210 210 255
Rectangle -7500403 true true 84 232 219 236
Rectangle -16777216 false false 101 172 112 184

computer workstation
false
0
Rectangle -7500403 true true 60 45 240 180
Polygon -7500403 true true 90 180 105 195 135 195 135 210 165 210 165 195 195 195 210 180
Rectangle -16777216 true false 75 60 225 165
Rectangle -7500403 true true 45 210 255 255
Rectangle -10899396 true false 249 223 237 217
Line -16777216 false 60 225 120 225

container
false
0
Rectangle -7500403 false false 0 75 300 225
Rectangle -7500403 true true 0 75 300 225
Line -16777216 false 0 210 300 210
Line -16777216 false 0 90 300 90
Line -16777216 false 150 90 150 210
Line -16777216 false 120 90 120 210
Line -16777216 false 90 90 90 210
Line -16777216 false 240 90 240 210
Line -16777216 false 270 90 270 210
Line -16777216 false 30 90 30 210
Line -16777216 false 60 90 60 210
Line -16777216 false 210 90 210 210
Line -16777216 false 180 90 180 210

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cow skull
false
0
Polygon -7500403 true true 150 90 75 105 60 150 75 210 105 285 195 285 225 210 240 150 225 105
Polygon -16777216 true false 150 150 90 195 90 150
Polygon -16777216 true false 150 150 210 195 210 150
Polygon -16777216 true false 105 285 135 270 150 285 165 270 195 285
Polygon -7500403 true true 240 150 263 143 278 126 287 102 287 79 280 53 273 38 261 25 246 15 227 8 241 26 253 46 258 68 257 96 246 116 229 126
Polygon -7500403 true true 60 150 37 143 22 126 13 102 13 79 20 53 27 38 39 25 54 15 73 8 59 26 47 46 42 68 43 96 54 116 71 126

crate
false
0
Rectangle -7500403 true true 45 45 255 255
Rectangle -16777216 false false 45 45 255 255
Rectangle -16777216 false false 60 60 240 240
Line -16777216 false 180 60 180 240
Line -16777216 false 150 60 150 240
Line -16777216 false 120 60 120 240
Line -16777216 false 210 60 210 240
Line -16777216 false 90 60 90 240
Polygon -7500403 true true 75 240 240 75 240 60 225 60 60 225 60 240
Polygon -16777216 false false 60 225 60 240 75 240 240 75 240 60 225 60

crown
false
0
Rectangle -7500403 true true 45 165 255 240
Polygon -7500403 true true 45 165 30 60 90 165 90 60 132 166 150 60 169 166 210 60 210 165 270 60 255 165
Circle -16777216 true false 222 192 22
Circle -16777216 true false 56 192 22
Circle -16777216 true false 99 192 22
Circle -16777216 true false 180 192 22
Circle -16777216 true false 139 192 22

cylinder
false
0
Circle -7500403 true true 0 0 300

dart
true
0
Polygon -7500403 true true 135 90 150 285 165 90
Polygon -7500403 true true 135 285 105 255 105 240 120 210 135 180 150 165 165 180 180 210 195 240 195 255 165 285
Rectangle -1184463 true false 135 45 165 90
Line -16777216 false 150 285 150 180
Polygon -16777216 true false 150 45 135 45 146 35 150 0 155 35 165 45
Line -16777216 false 135 75 165 75
Line -16777216 false 135 60 165 60

die 1
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 129 129 42

die 2
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 189 189 42

die 3
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 129 129 42
Circle -16777216 true false 189 189 42

die 4
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 69 189 42
Circle -16777216 true false 189 69 42
Circle -16777216 true false 189 189 42

die 5
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 129 129 42
Circle -16777216 true false 69 189 42
Circle -16777216 true false 189 69 42
Circle -16777216 true false 189 189 42

die 6
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 84 69 42
Circle -16777216 true false 84 129 42
Circle -16777216 true false 84 189 42
Circle -16777216 true false 174 69 42
Circle -16777216 true false 174 129 42
Circle -16777216 true false 174 189 42

dimer
true
15
Circle -1 true true 150 120 60
Circle -1 true true 90 120 60
Circle -16777216 false false 89 119 62
Circle -16777216 false false 149 119 62

dimer1
true
15
Circle -7500403 true false 150 45 60
Circle -2674135 true false 90 45 60
Circle -16777216 false false 89 44 62
Circle -16777216 false false 149 44 62
Polygon -1184463 true false 158 167 121 104 120 103 83 167
Polygon -16777216 false false 158 166 121 102 79 166 124 167

dimer1sykactivedimerised
true
4
Circle -2674135 true false 14 120 67
Circle -2674135 true false 82 119 67
Circle -2674135 true false 150 118 67
Circle -2674135 true false 218 120 67
Circle -16777216 false false 11 118 72
Circle -16777216 false false 90 120 0
Circle -16777216 false false 80 118 70
Circle -16777216 false false 148 117 70
Circle -16777216 false false 216 120 70
Polygon -1 true false 105 75
Polygon -13345367 true false 120 120 150 60 75 60 120 120
Polygon -13345367 true false 184 120 225 60 165 60 150 60 186 119
Polygon -16777216 false false 122 121 150 60 76 60 118 117 121 117
Polygon -16777216 false false 152 59 224 59 186 118 151 63
Polygon -13345367 true false 259 120 293 60 223 60 259 120
Polygon -16777216 false false 260 118 293 60 223 60 258 118
Polygon -13345367 true false 45 120 75 60 7 62 45 120
Polygon -16777216 false false 46 117 73 60 6 61 44 118
Rectangle -11221820 true false 102 40 135 75
Rectangle -16777216 false false 102 40 136 74
Rectangle -11221820 true false 136 49 181 64
Rectangle -11221820 true false 169 39 202 74
Rectangle -16777216 false false 169 39 203 73

dimer2syk1active
true
1
Circle -2674135 true true 28 65 74
Circle -2674135 true true 102 65 78
Polygon -10899396 true false 15 210 105 210 60 135 15 210
Polygon -16777216 false false 15 210 15 210 103 209 60 135
Circle -16777216 false false 28 65 74
Circle -16777216 false false 100 64 80
Polygon -10899396 true false 105 210 195 210 150 135 105 210
Polygon -16777216 false false 108 208 195 209 150 134 106 207
Rectangle -11221820 true false 222 193 262 232
Rectangle -11221820 true false 135 195 173 234
Rectangle -16777216 false false 136 197 172 236
Rectangle -11221820 true false 172 206 232 221
Rectangle -16777216 false false 225 195 262 231

dimerdimerdimeridimer3syk
true
10
Circle -2674135 true false 64 135 34
Circle -16777216 false false 90 120 0
Polygon -1 true false 105 75
Polygon -13345367 true true 46 134 60 101 27 101 46 134
Polygon -16777216 false false 45 132 59 100 27 101 46 133
Rectangle -11221820 true false 84 96 116 102
Rectangle -16777216 false false 169 89 184 105
Circle -2674135 true false 97 135 34
Circle -2674135 true false 130 134 34
Circle -2674135 true false 30 135 34
Circle -2674135 true false 164 135 34
Circle -2674135 true false 197 135 34
Circle -2674135 true false 230 136 34
Circle -2674135 true false 264 137 34
Circle -16777216 false false 28 133 38
Circle -16777216 false false 62 134 36
Circle -16777216 false false 97 133 36
Circle -16777216 false false 128 132 36
Circle -16777216 false false 162 133 36
Circle -16777216 false false 197 134 36
Circle -16777216 false false 230 134 36
Circle -16777216 false false 264 136 36
Polygon -13345367 true true 80 135 94 102 61 102 80 135
Polygon -13345367 true true 113 134 127 101 94 101 113 134
Polygon -13345367 true true 148 134 162 101 129 101 148 134
Polygon -13345367 true true 182 136 196 103 163 103 182 136
Polygon -13345367 true true 215 136 229 103 196 103 215 136
Polygon -13345367 true true 247 137 261 104 228 104 247 137
Polygon -13345367 true true 281 136 295 103 262 103 281 136
Polygon -16777216 false false 79 133 93 101 61 102 80 134
Polygon -16777216 false false 113 133 127 101 95 102 114 134
Polygon -16777216 false false 148 132 162 100 130 101 149 133
Polygon -16777216 false false 181 134 195 102 163 103 182 135
Polygon -16777216 false false 215 134 229 102 197 103 216 135
Polygon -16777216 false false 246 135 260 103 228 104 247 136
Polygon -16777216 false false 280 135 294 103 262 104 281 136
Rectangle -11221820 true false 108 90 122 107
Rectangle -11221820 true false 75 90 89 107
Rectangle -16777216 false false 73 90 90 107
Rectangle -16777216 false false 107 90 122 106
Rectangle -11221820 true false 215 99 247 105
Rectangle -11221820 true false 209 94 223 111
Rectangle -11221820 true false 239 93 253 110
Rectangle -11221820 true false 144 98 176 104
Rectangle -16777216 false false 208 94 225 111
Rectangle -16777216 false false 239 93 254 110
Rectangle -11221820 true false 141 93 155 110
Rectangle -16777216 false false 140 93 156 110
Rectangle -11221820 true false 173 92 187 108
Rectangle -16777216 false false 172 92 188 109

dimerisedr0
true
14
Polygon -7500403 true false 90 150 150 60 210 150 105 150 105 150
Line -16777216 true 150 60 90 150
Line -16777216 true 90 150 210 150
Line -16777216 true 150 60 210 150

dimerisedr1
true
14
Polygon -13345367 true false 90 150 150 60 210 150 105 150 105 150
Line -16777216 true 150 60 90 150
Line -16777216 true 90 150 210 150
Line -16777216 true 150 60 210 150

dimerisedr2
true
14
Polygon -1184463 true false 90 150 150 60 210 150 105 150 105 150
Line -16777216 true 150 60 90 150
Line -16777216 true 90 150 210 150
Line -16777216 true 150 60 210 150

dimerisedr3
true
14
Polygon -1184463 true false 90 150 150 60 210 150 105 150 105 150
Line -16777216 true 150 60 90 150
Line -16777216 true 90 150 210 150
Line -16777216 true 150 60 210 150

dimerisedr4
true
14
Polygon -8630108 true false 90 150 150 60 210 150 105 150 105 150
Line -16777216 true 150 60 90 150
Line -16777216 true 90 150 210 150
Line -16777216 true 150 60 210 150

dimerisedr5
true
14
Polygon -8630108 true false 90 150 150 60 210 150 105 150 105 150
Line -16777216 true 150 60 90 150
Line -16777216 true 90 150 210 150
Line -16777216 true 150 60 210 150

dimersykactive
true
15
Circle -2674135 true false 73 65 74
Circle -2674135 true false 147 65 78
Polygon -10899396 true false 60 210 150 210 105 135 60 210
Polygon -16777216 false false 60 210 60 210 148 209 105 135
Rectangle -11221820 true false 90 195 128 234
Circle -16777216 false false 73 65 74
Circle -16777216 false false 145 64 80
Polygon -10899396 true false 150 210 240 210 195 135 150 210
Polygon -16777216 false false 153 208 240 209 195 134 151 207
Rectangle -11221820 true false 127 206 187 221
Rectangle -11221820 true false 177 193 217 232
Rectangle -16777216 false false 91 197 127 236
Rectangle -16777216 false false 180 195 217 231

dog
false
0
Polygon -7500403 true true 300 165 300 195 270 210 183 204 180 240 165 270 165 300 120 300 0 240 45 165 75 90 75 45 105 15 135 45 165 45 180 15 225 15 255 30 225 30 210 60 225 90 225 105
Polygon -16777216 true false 0 240 120 300 165 300 165 285 120 285 10 221
Line -16777216 false 210 60 180 45
Line -16777216 false 90 45 90 90
Line -16777216 false 90 90 105 105
Line -16777216 false 105 105 135 60
Line -16777216 false 90 45 135 60
Line -16777216 false 135 60 135 45
Line -16777216 false 181 203 151 203
Line -16777216 false 150 201 105 171
Circle -16777216 true false 171 88 34
Circle -16777216 false false 261 162 30

dollar bill
false
0
Rectangle -7500403 true true 15 90 285 210
Rectangle -1 true false 30 105 270 195
Circle -7500403 true true 120 120 60
Circle -7500403 true true 120 135 60
Circle -7500403 true true 254 178 26
Circle -7500403 true true 248 98 26
Circle -7500403 true true 18 97 36
Circle -7500403 true true 21 178 26
Circle -7500403 true true 66 135 28
Circle -1 true false 72 141 16
Circle -7500403 true true 201 138 32
Circle -1 true false 209 146 16
Rectangle -16777216 true false 64 112 86 118
Rectangle -16777216 true false 90 112 124 118
Rectangle -16777216 true false 128 112 188 118
Rectangle -16777216 true false 191 112 237 118
Rectangle -1 true false 106 199 128 205
Rectangle -1 true false 90 96 209 98
Rectangle -7500403 true true 60 168 103 176
Rectangle -7500403 true true 199 127 230 133
Line -7500403 true 59 184 104 184
Line -7500403 true 241 189 196 189
Line -7500403 true 59 189 104 189
Line -16777216 false 116 124 71 124
Polygon -1 true false 127 179 142 167 142 160 130 150 126 148 142 132 158 132 173 152 167 156 164 167 174 176 161 193 135 192
Rectangle -1 true false 134 199 184 205

dot
false
0
Circle -7500403 true true 90 90 120

drop
false
0
Circle -7500403 true true 73 133 152
Polygon -7500403 true true 219 181 205 152 185 120 174 95 163 64 156 37 149 7 147 166
Polygon -7500403 true true 79 182 95 152 115 120 126 95 137 64 144 37 150 6 154 165

egg
false
0
Circle -7500403 true true 96 76 108
Circle -7500403 true true 72 104 156
Polygon -7500403 true true 221 149 195 101 106 99 80 148

electric outlet
false
0
Rectangle -7500403 true true 45 0 255 297
Polygon -16777216 false false 120 270 90 240 90 195 120 165 180 165 210 195 210 240 180 270
Rectangle -16777216 true false 169 199 177 236
Rectangle -16777216 true false 169 64 177 101
Polygon -16777216 false false 120 30 90 60 90 105 120 135 180 135 210 105 210 60 180 30
Rectangle -16777216 true false 123 64 131 101
Rectangle -16777216 true false 123 199 131 236
Rectangle -16777216 false false 45 0 255 296

emblem
false
0
Polygon -7500403 true true 0 90 15 120 285 120 300 90
Polygon -7500403 true true 30 135 45 165 255 165 270 135
Polygon -7500403 true true 60 180 75 210 225 210 240 180
Polygon -7500403 true true 150 285 15 45 285 45
Polygon -16777216 true false 75 75 150 210 225 75

exclamation
false
0
Circle -7500403 true true 103 198 95
Polygon -7500403 true true 135 180 165 180 210 30 180 0 120 0 90 30

eyeball
false
0
Circle -1 true false 22 20 248
Circle -7500403 true true 83 81 122
Circle -16777216 true false 122 120 44

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

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

fire department
false
0
Polygon -7500403 true true 150 55 180 60 210 75 240 45 210 45 195 30 165 15 135 15 105 30 90 45 60 45 90 75 120 60
Polygon -7500403 true true 55 150 60 120 75 90 45 60 45 90 30 105 15 135 15 165 30 195 45 210 45 240 75 210 60 180
Polygon -7500403 true true 245 150 240 120 225 90 255 60 255 90 270 105 285 135 285 165 270 195 255 210 255 240 225 210 240 180
Polygon -7500403 true true 150 245 180 240 210 225 240 255 210 255 195 270 165 285 135 285 105 270 90 255 60 255 90 225 120 240
Circle -7500403 true true 60 60 180
Circle -16777216 false false 75 75 150

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

fish 2
false
0
Polygon -1 true false 56 133 34 127 12 105 21 126 23 146 16 163 10 194 32 177 55 173
Polygon -7500403 true true 156 229 118 242 67 248 37 248 51 222 49 168
Polygon -7500403 true true 30 60 45 75 60 105 50 136 150 53 89 56
Polygon -7500403 true true 50 132 146 52 241 72 268 119 291 147 271 156 291 164 264 208 211 239 148 231 48 177
Circle -1 true false 237 116 30
Circle -16777216 true false 241 127 12
Polygon -1 true false 159 228 160 294 182 281 206 236
Polygon -7500403 true true 102 189 109 203
Polygon -1 true false 215 182 181 192 171 177 169 164 152 142 154 123 170 119 223 163
Line -16777216 false 240 77 162 71
Line -16777216 false 164 71 98 78
Line -16777216 false 96 79 62 105
Line -16777216 false 50 179 88 217
Line -16777216 false 88 217 149 230

fish 3
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1184463 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -1 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -1 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -1 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

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

flower budding
false
0
Polygon -7500403 true true 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Polygon -7500403 true true 189 233 219 188 249 173 279 188 234 218
Polygon -7500403 true true 180 255 150 210 105 210 75 240 135 240
Polygon -7500403 true true 180 150 180 120 165 97 135 84 128 121 147 148 165 165
Polygon -7500403 true true 170 155 131 163 175 167 196 136

food
false
0
Polygon -7500403 true true 30 105 45 255 105 255 120 105
Rectangle -7500403 true true 15 90 135 105
Polygon -7500403 true true 75 90 105 15 120 15 90 90
Polygon -7500403 true true 135 225 150 240 195 255 225 255 270 240 285 225 150 225
Polygon -7500403 true true 135 180 150 165 195 150 225 150 270 165 285 180 150 180
Rectangle -7500403 true true 135 195 285 210

footprint human
true
0
Polygon -7500403 true true 111 244 115 272 130 286 151 288 168 277 176 257 177 234 175 195 174 172 170 135 177 104 188 79 188 55 179 45 181 32 185 17 176 1 159 2 154 17 161 32 158 44 146 47 144 35 145 21 135 7 124 9 120 23 129 36 133 49 121 47 100 56 89 73 73 94 74 121 86 140 99 163 110 191
Polygon -7500403 true true 97 37 101 44 111 43 118 35 111 23 100 20 95 25
Polygon -7500403 true true 77 52 81 59 91 58 96 50 88 39 82 37 76 42
Polygon -7500403 true true 63 72 67 79 77 78 79 70 73 63 68 60 63 65

footprint other
true
0
Polygon -7500403 true true 75 195 90 240 135 270 165 270 195 255 225 195 225 180 195 165 177 154 167 139 150 135 132 138 124 151 105 165 76 172
Polygon -7500403 true true 250 136 225 165 210 135 210 120 227 100 241 99
Polygon -7500403 true true 75 135 90 135 105 120 105 75 90 75 60 105
Polygon -7500403 true true 120 122 155 121 161 62 148 40 136 40 118 70
Polygon -7500403 true true 176 126 200 121 206 89 198 61 186 57 166 106
Polygon -7500403 true true 93 69 103 68 102 50
Polygon -7500403 true true 146 34 136 33 137 15
Polygon -7500403 true true 198 55 188 52 189 34
Polygon -7500403 true true 238 92 228 94 229 76

frog top
true
0
Polygon -7500403 true true 146 18 135 30 119 42 105 90 90 150 105 195 135 225 165 225 195 195 210 150 195 90 180 41 165 30 155 18
Polygon -7500403 true true 91 176 67 148 70 121 66 119 61 133 59 111 53 111 52 131 47 115 42 120 46 146 55 187 80 237 106 269 116 268 114 214 131 222
Polygon -7500403 true true 185 62 234 84 223 51 226 48 234 61 235 38 240 38 243 60 252 46 255 49 244 95 188 92
Polygon -7500403 true true 115 62 66 84 77 51 74 48 66 61 65 38 60 38 57 60 48 46 45 49 56 95 112 92
Polygon -7500403 true true 200 186 233 148 230 121 234 119 239 133 241 111 247 111 248 131 253 115 258 120 254 146 245 187 220 237 194 269 184 268 186 214 169 222
Circle -16777216 true false 157 38 18
Circle -16777216 true false 125 38 18

garbage can
false
0
Polygon -16777216 false false 60 240 66 257 90 285 134 299 164 299 209 284 234 259 240 240
Rectangle -7500403 true true 60 75 240 240
Polygon -7500403 true true 60 238 66 256 90 283 135 298 165 298 210 283 235 256 240 238
Polygon -7500403 true true 60 75 66 57 90 30 135 15 165 15 210 30 235 57 240 75
Polygon -7500403 true true 60 75 66 93 90 120 135 135 165 135 210 120 235 93 240 75
Polygon -16777216 false false 59 75 66 57 89 30 134 15 164 15 209 30 234 56 239 75 235 91 209 120 164 135 134 135 89 120 64 90
Line -16777216 false 210 120 210 285
Line -16777216 false 90 120 90 285
Line -16777216 false 125 131 125 296
Line -16777216 false 65 93 65 258
Line -16777216 false 175 131 175 296
Line -16777216 false 235 93 235 258
Polygon -16777216 false false 112 52 112 66 127 51 162 64 170 87 185 85 192 71 180 54 155 39 127 36

ghost
false
0
Polygon -7500403 true true 30 165 13 164 -2 149 0 135 -2 119 0 105 15 75 30 75 58 104 43 119 43 134 58 134 73 134 88 104 73 44 78 14 103 -1 193 -1 223 29 208 89 208 119 238 134 253 119 240 105 238 89 240 75 255 60 270 60 283 74 300 90 298 104 298 119 300 135 285 135 285 150 268 164 238 179 208 164 208 194 238 209 253 224 268 239 268 269 238 299 178 299 148 284 103 269 58 284 43 299 58 269 103 254 148 254 193 254 163 239 118 209 88 179 73 179 58 164
Line -16777216 false 189 253 215 253
Circle -16777216 true false 102 30 30
Polygon -16777216 true false 165 105 135 105 120 120 105 105 135 75 165 75 195 105 180 120
Circle -16777216 true false 160 30 30

hawk
true
0
Polygon -7500403 true true 151 170 136 170 123 229 143 244 156 244 179 229 166 170
Polygon -16777216 true false 152 154 137 154 125 213 140 229 159 229 179 214 167 154
Polygon -7500403 true true 151 140 136 140 126 202 139 214 159 214 176 200 166 140
Polygon -16777216 true false 151 125 134 124 128 188 140 198 161 197 174 188 166 125
Polygon -7500403 true true 152 86 227 72 286 97 272 101 294 117 276 118 287 131 270 131 278 141 264 138 267 145 228 150 153 147
Polygon -7500403 true true 160 74 159 61 149 54 130 53 139 62 133 81 127 113 129 149 134 177 150 206 168 179 172 147 169 111
Circle -16777216 true false 144 55 7
Polygon -16777216 true false 129 53 135 58 139 54
Polygon -7500403 true true 148 86 73 72 14 97 28 101 6 117 24 118 13 131 30 131 22 141 36 138 33 145 72 150 147 147

hex
false
0
Polygon -7500403 true true 0 150 75 30 225 30 300 150 225 270 75 270

hexagonal prism
false
0
Rectangle -7500403 true true 90 90 210 270
Polygon -1 true false 210 270 255 240 255 60 210 90
Polygon -13345367 true false 90 90 45 60 45 240 90 270
Polygon -11221820 true false 45 60 90 30 210 30 255 60 210 90 90 90

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house bungalow
false
0
Rectangle -7500403 true true 210 75 225 255
Rectangle -7500403 true true 90 135 210 255
Rectangle -16777216 true false 165 195 195 255
Line -16777216 false 210 135 210 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 150 75 150 150 75
Line -16777216 false 75 150 225 150
Line -16777216 false 195 120 225 150
Polygon -16777216 false false 165 195 150 195 180 165 210 195
Rectangle -16777216 true false 135 105 165 135

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

i beam
false
0
Polygon -7500403 true true 165 15 240 15 240 45 195 75 195 240 240 255 240 285 165 285
Polygon -7500403 true true 135 15 60 15 60 45 105 75 105 240 60 255 60 285 135 285

key
false
0
Rectangle -7500403 true true 90 120 285 150
Rectangle -7500403 true true 255 135 285 195
Rectangle -7500403 true true 180 135 210 195
Circle -7500403 true true 0 60 150
Circle -16777216 true false 30 90 90

lander
true
0
Polygon -7500403 true true 45 75 150 30 255 75 285 225 240 225 240 195 210 195 210 225 165 225 165 195 135 195 135 225 90 225 90 195 60 195 60 225 15 225 45 75

lander 2
true
0
Polygon -7500403 true true 135 205 120 235 180 235 165 205
Polygon -16777216 false false 135 205 120 235 180 235 165 205
Line -7500403 true 75 30 195 30
Polygon -7500403 true true 195 150 210 165 225 165 240 150 240 135 225 120 210 120 195 135
Polygon -16777216 false false 195 150 210 165 225 165 240 150 240 135 225 120 210 120 195 135
Polygon -7500403 true true 75 75 105 45 195 45 225 75 225 135 195 165 105 165 75 135
Polygon -16777216 false false 75 75 105 45 195 45 225 75 225 120 225 135 195 165 105 165 75 135
Polygon -16777216 true false 217 90 210 75 180 60 180 90
Polygon -16777216 true false 83 90 90 75 120 60 120 90
Polygon -16777216 false false 135 165 120 135 135 75 150 60 165 75 180 135 165 165
Circle -7500403 true true 120 15 30
Circle -16777216 false false 120 15 30
Line -7500403 true 150 0 150 45
Polygon -1184463 true false 90 165 105 210 195 210 210 165
Line -1184463 false 210 165 245 239
Line -1184463 false 237 221 194 207
Rectangle -1184463 true false 221 245 261 238
Line -1184463 false 90 165 55 239
Line -1184463 false 63 221 106 207
Rectangle -1184463 true false 39 245 79 238
Polygon -16777216 false false 90 165 105 210 195 210 210 165
Rectangle -16777216 false false 221 237 262 245
Rectangle -16777216 false false 38 237 79 245

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

leaf 2
false
0
Rectangle -7500403 true true 144 218 156 298
Polygon -7500403 true true 150 263 133 276 102 276 58 242 35 176 33 139 43 114 54 123 62 87 75 53 94 30 104 39 120 9 155 31 180 68 191 56 216 85 235 125 240 173 250 165 248 205 225 247 200 271 176 275

letter opened
false
0
Rectangle -7500403 true true 30 90 270 225
Rectangle -16777216 false false 30 90 270 225
Line -16777216 false 150 30 270 105
Line -16777216 false 30 105 150 30
Line -16777216 false 270 225 181 161
Line -16777216 false 30 225 119 161
Polygon -6459832 true false 30 105 150 30 270 105 150 180
Line -16777216 false 30 105 270 105
Line -16777216 false 270 105 150 180
Line -16777216 false 30 105 150 180

letter sealed
false
0
Rectangle -7500403 true true 30 90 270 225
Rectangle -16777216 false false 30 90 270 225
Line -16777216 false 270 105 150 180
Line -16777216 false 30 105 150 180
Line -16777216 false 270 225 181 161
Line -16777216 false 30 225 119 161

lightning
false
0
Polygon -7500403 true true 120 135 90 195 135 195 105 300 225 165 180 165 210 105 165 105 195 0 75 135

lily pad
false
0
Polygon -7500403 true true 148 151 137 37 119 25 111 36 78 54 40 99 30 137 32 175 56 223 87 251 137 275 157 275 213 250 239 221 257 178 262 137 244 91 210 53 172 37 160 22 154 36
Line -13840069 false 154 151 207 97
Circle -13840069 false false 133 148 26
Line -13840069 false 52 122 134 157
Line -13840069 false 133 171 89 196
Line -13840069 false 147 193 147 254
Line -13840069 false 157 171 205 233
Line -13840069 false 161 161 204 163
Line -13840069 false 141 149 111 72

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

link
true
0
Line -7500403 true 150 0 150 300

llrr
true
1
Circle -2674135 true true 143 46 60
Circle -2674135 true true 83 48 60
Circle -16777216 false false 82 47 62
Circle -16777216 false false 142 45 62
Polygon -10899396 true false 87 158 143 158 116 103 86 157
Polygon -10899396 true false 145 158 201 158 174 103 144 157
Polygon -16777216 false false 143 158 173 102 199 158 144 158
Polygon -16777216 false false 85 158 115 102 142 159 80 163

llrrs
true
0
Polygon -13840069 true false 151 146 220 146 187 86 150 146
Polygon -16777216 false false 158 131 152 146 221 145 188 86
Polygon -13840069 true false 80 148 149 148 116 88 79 148
Polygon -16777216 false false 85 134 79 149 148 148 115 89
Rectangle -16777216 false false 122 141 171 151
Rectangle -7500403 true true 171 135 198 161
Rectangle -7500403 true true 102 134 129 160
Rectangle -7500403 true true 124 142 173 151
Rectangle -16777216 false false 169 135 198 162
Rectangle -16777216 false false 100 135 129 162
Circle -2674135 true false 151 27 67
Circle -16777216 false false 151 26 68
Circle -2674135 true false 84 27 67
Circle -16777216 false false 83 27 68

llrrs*
true
0
Polygon -13840069 true false 151 146 220 146 187 86 150 146
Polygon -16777216 false false 158 131 152 146 221 145 188 86
Polygon -13840069 true false 80 148 149 148 116 88 79 148
Polygon -16777216 false false 85 134 79 149 148 148 115 89
Rectangle -16777216 false false 122 141 171 151
Rectangle -11221820 true false 171 135 198 161
Rectangle -11221820 true false 102 134 129 160
Rectangle -11221820 true false 124 142 173 151
Rectangle -16777216 false false 169 135 198 162
Rectangle -16777216 false false 100 135 129 162
Circle -2674135 true false 151 27 67
Circle -16777216 false false 151 26 68
Circle -2674135 true false 84 27 67
Circle -16777216 false false 83 27 68

logs
false
0
Polygon -7500403 true true 15 241 75 271 89 245 135 271 150 246 195 271 285 121 235 96 255 61 195 31 181 55 135 31 45 181 49 183
Circle -1 true false 132 222 66
Circle -16777216 false false 132 222 66
Circle -1 true false 72 222 66
Circle -1 true false 102 162 66
Circle -7500403 true true 222 72 66
Circle -7500403 true true 192 12 66
Circle -7500403 true true 132 12 66
Circle -16777216 false false 102 162 66
Circle -16777216 false false 72 222 66
Circle -1 true false 12 222 66
Circle -16777216 false false 30 240 30
Circle -1 true false 42 162 66
Circle -16777216 false false 42 162 66
Line -16777216 false 195 30 105 180
Line -16777216 false 255 60 165 210
Circle -16777216 false false 12 222 66
Circle -16777216 false false 90 240 30
Circle -16777216 false false 150 240 30
Circle -16777216 false false 120 180 30
Circle -16777216 false false 60 180 30
Line -16777216 false 195 270 285 120
Line -16777216 false 15 240 45 180
Line -16777216 false 45 180 135 30

lr
true
1
Polygon -1184463 true false 149 155 117 95 87 155 118 156
Polygon -16777216 false false 86 155 85 152 117 94 149 155
Circle -2674135 true true 87 42 60
Circle -16777216 false false 87 41 62

lrr
true
1
Circle -2674135 true true 83 48 60
Circle -16777216 false false 82 47 62
Polygon -10899396 true false 87 158 143 158 116 103 86 157
Polygon -10899396 true false 145 158 201 158 174 103 144 157
Polygon -16777216 false false 143 158 173 102 199 158 144 158
Polygon -16777216 false false 85 158 115 102 142 159 80 163

lrrs
true
0
Polygon -13840069 true false 151 146 220 146 187 86 150 146
Polygon -16777216 false false 158 131 152 146 221 145 188 86
Polygon -13840069 true false 80 148 149 148 116 88 79 148
Polygon -16777216 false false 85 134 79 149 148 148 115 89
Rectangle -16777216 false false 122 141 171 151
Rectangle -7500403 true true 171 135 198 161
Rectangle -7500403 true true 102 134 129 160
Rectangle -7500403 true true 124 142 173 151
Rectangle -16777216 false false 169 135 198 162
Rectangle -16777216 false false 100 135 129 162
Circle -2674135 true false 84 27 67
Circle -16777216 false false 83 27 68

lrrs'
true
0
Polygon -13840069 true false 151 146 220 146 187 86 150 146
Polygon -16777216 false false 158 131 152 146 221 145 188 86
Polygon -13840069 true false 80 148 149 148 116 88 79 148
Polygon -16777216 false false 85 134 79 149 148 148 115 89
Rectangle -16777216 false false 62 141 111 151
Rectangle -7500403 true true 36 135 63 161
Rectangle -7500403 true true 102 134 129 160
Rectangle -7500403 true true 64 142 113 151
Rectangle -16777216 false false 34 135 63 162
Rectangle -16777216 false false 100 135 129 162
Circle -2674135 true false 84 27 67
Circle -16777216 false false 83 27 68

lrrs*
true
0
Polygon -13840069 true false 151 146 220 146 187 86 150 146
Polygon -16777216 false false 158 131 152 146 221 145 188 86
Polygon -13840069 true false 80 148 149 148 116 88 79 148
Polygon -16777216 false false 85 134 79 149 148 148 115 89
Rectangle -16777216 false false 122 141 171 151
Rectangle -11221820 true false 171 135 198 161
Rectangle -11221820 true false 102 134 129 160
Rectangle -11221820 true false 124 142 173 151
Rectangle -16777216 false false 169 135 198 162
Rectangle -16777216 false false 100 135 129 162
Circle -2674135 true false 84 27 67
Circle -16777216 false false 83 27 68

lrrs*'
true
8
Polygon -13840069 true false 151 146 220 146 187 86 150 146
Polygon -16777216 false false 158 131 152 146 221 145 188 86
Polygon -13840069 true false 80 148 149 148 116 88 79 148
Polygon -16777216 false false 85 134 79 149 148 148 115 89
Rectangle -16777216 false false 62 141 111 151
Rectangle -11221820 true true 36 135 63 161
Rectangle -11221820 true true 102 134 129 160
Rectangle -11221820 true true 64 142 113 151
Rectangle -16777216 false false 34 135 63 162
Rectangle -16777216 false false 100 135 129 162
Circle -2674135 true false 84 27 67
Circle -16777216 false false 83 27 68

lrs
true
8
Circle -2674135 true false 76 79 56
Polygon -1184463 true false 70 195 139 195 106 135 69 195
Polygon -16777216 false false 75 180 69 195 138 194 105 135
Circle -16777216 false false 74 77 60
Rectangle -7500403 true false 112 193 161 202
Rectangle -16777216 false false 125 193 174 203
Rectangle -7500403 true false 99 185 126 211
Rectangle -7500403 true false 155 187 182 213
Rectangle -16777216 false false 155 186 184 213
Rectangle -16777216 false false 99 185 128 212

lrs*
true
8
Circle -2674135 true false 76 79 56
Polygon -1184463 true false 70 195 139 195 106 135 69 195
Polygon -16777216 false false 75 180 69 195 138 194 105 135
Circle -16777216 false false 74 77 60
Rectangle -11221820 true true 127 193 176 202
Rectangle -16777216 false false 125 193 174 203
Rectangle -11221820 true true 99 185 126 211
Rectangle -11221820 true true 170 187 197 213
Rectangle -16777216 false false 170 186 199 213
Rectangle -16777216 false false 99 185 128 212

magnet
true
0
Polygon -7500403 true true 120 270 75 270 60 105 60 60 75 30 106 10 150 3 195 10 225 30 240 60 240 105 225 270 180 270 195 105 196 74 184 55 165 45 135 45 115 55 104 75 105 105
Polygon -16777216 true false 219 264 188 264 193 214 224 215
Polygon -16777216 true false 81 264 112 264 107 214 76 215

molecule hydrogen
true
0
Circle -1 true false 138 108 84
Circle -16777216 false false 138 108 84
Circle -1 true false 78 108 84
Circle -16777216 false false 78 108 84

molecule oxygen
true
0
Circle -7500403 true true 120 75 150
Circle -16777216 false false 120 75 150
Circle -7500403 true true 30 75 150
Circle -16777216 false false 30 75 150

molecule water
true
0
Circle -1 true false 183 63 84
Circle -16777216 false false 183 63 84
Circle -7500403 true true 75 75 150
Circle -16777216 false false 75 75 150
Circle -1 true false 33 63 84
Circle -16777216 false false 33 63 84

monomer
true
15
Circle -1 true true 120 120 60
Circle -16777216 false false 119 119 62

monomer2syk1active_crosslink
true
1
Circle -2674135 true true 73 65 74
Polygon -10899396 true false 60 210 150 210 105 135 60 210
Polygon -16777216 false false 60 210 60 210 148 209 105 135
Rectangle -11221820 true false 0 195 38 234
Circle -16777216 false false 73 65 74
Rectangle -11221820 true false 37 206 97 221
Rectangle -11221820 true false 87 193 127 232
Rectangle -16777216 false false 1 197 37 236
Rectangle -16777216 false false 90 195 127 231
Polygon -10899396 true false 150 210 240 210 195 135 150 210
Polygon -16777216 false false 150 210 150 210 238 209 195 135

monomer2syk1active_non
true
1
Circle -2674135 true true 73 65 74
Polygon -10899396 true false 60 210 150 210 105 135 60 210
Polygon -16777216 false false 60 210 60 210 148 209 105 135
Circle -16777216 false false 73 65 74
Polygon -10899396 true false 150 210 240 210 195 135 150 210
Polygon -16777216 false false 150 210 150 210 238 209 195 135
Rectangle -11221820 true false 177 193 217 232
Rectangle -16777216 false false 180 195 217 231
Rectangle -11221820 true false 127 206 187 221
Rectangle -11221820 true false 90 195 128 234
Rectangle -16777216 false false 91 197 127 236

monomersykactive
true
1
Circle -2674135 true true 76 79 56
Polygon -1184463 true false 70 195 139 195 106 135 69 195
Polygon -16777216 false false 75 180 69 195 138 194 105 135
Circle -16777216 false false 74 77 60
Rectangle -11221820 true false 127 193 176 202
Rectangle -16777216 false false 125 193 174 203
Rectangle -11221820 true false 99 185 126 211
Rectangle -11221820 true false 170 187 197 213
Rectangle -16777216 false false 170 186 199 213
Rectangle -16777216 false false 99 185 128 212

monomersykactivedimerised
true
1
Circle -2674135 true true 73 65 74
Circle -2674135 true true 147 65 78
Polygon -10899396 true false 60 210 150 210 105 135 60 210
Polygon -16777216 false false 60 210 60 210 148 209 105 135
Rectangle -11221820 true false 90 195 128 234
Circle -16777216 false false 73 65 74
Circle -16777216 false false 145 64 80
Polygon -10899396 true false 150 210 240 210 195 135 150 210
Polygon -16777216 false false 153 208 240 209 195 134 151 207
Rectangle -11221820 true false 127 206 187 221
Rectangle -11221820 true false 177 193 217 232
Rectangle -16777216 false false 91 197 127 236
Rectangle -16777216 false false 180 195 217 231

monster
false
0
Polygon -7500403 true true 75 150 90 195 210 195 225 150 255 120 255 45 180 0 120 0 45 45 45 120
Circle -16777216 true false 165 60 60
Circle -16777216 true false 75 60 60
Polygon -7500403 true true 225 150 285 195 285 285 255 300 255 210 180 165
Polygon -7500403 true true 75 150 15 195 15 285 45 300 45 210 120 165
Polygon -7500403 true true 210 210 225 285 195 285 165 165
Polygon -7500403 true true 90 210 75 285 105 285 135 165
Rectangle -7500403 true true 135 165 165 270

moon
false
0
Polygon -7500403 true true 175 7 83 36 25 108 27 186 79 250 134 271 205 274 281 239 207 233 152 216 113 185 104 132 110 77 132 51

moose
false
0
Polygon -7500403 true true 196 228 198 297 180 297 178 244 166 213 136 213 106 213 79 227 73 259 50 257 49 229 38 197 26 168 26 137 46 120 101 122 147 102 181 111 217 121 256 136 294 151 286 169 256 169 241 198 211 188
Polygon -7500403 true true 74 258 87 299 63 297 49 256
Polygon -7500403 true true 25 135 15 186 10 200 23 217 25 188 35 141
Polygon -7500403 true true 270 150 253 100 231 94 213 100 208 135
Polygon -7500403 true true 225 120 204 66 207 29 185 56 178 27 171 59 150 45 165 90
Polygon -7500403 true true 225 120 249 61 241 31 265 56 272 27 280 59 300 45 285 90

moose-face
false
0
Circle -7566196 true true 101 110 95
Circle -7566196 true true 111 170 77
Polygon -7566196 true true 135 243 140 267 144 253 150 272 156 250 158 258 161 241
Circle -16777216 true false 127 222 9
Circle -16777216 true false 157 222 8
Circle -1 true false 118 143 16
Circle -1 true false 159 143 16
Polygon -7566196 true true 106 135 88 135 71 111 79 95 86 110 111 121
Polygon -7566196 true true 205 134 190 135 185 122 209 115 212 99 218 118
Polygon -7566196 true true 118 118 95 98 69 84 23 76 8 35 27 19 27 40 38 47 48 16 55 23 58 41 71 35 75 15 90 19 86 38 100 49 111 76 117 99
Polygon -7566196 true true 167 112 190 96 221 84 263 74 276 30 258 13 258 35 244 38 240 11 230 11 226 35 212 39 200 15 192 18 195 43 169 64 165 92

mortar pestle
false
0
Polygon -7500403 true true 60 150 30 150 30 165 45 165 45 195 60 225 90 255 150 270 210 255 240 225 255 195 255 165 270 165 270 150
Polygon -6459832 true false 75 150 30 105 15 105 15 90 45 60 60 60 60 75 150 150
Line -16777216 false 45 120 75 90
Line -16777216 false 105 150 125 128

mouse side
false
0
Polygon -7500403 true true 38 162 24 165 19 174 22 192 47 213 90 225 135 230 161 240 178 262 150 246 117 238 73 232 36 220 11 196 7 171 15 153 37 146 46 145
Polygon -7500403 true true 289 142 271 165 237 164 217 185 235 192 254 192 259 199 245 200 248 203 226 199 200 194 155 195 122 185 84 187 91 195 82 192 83 201 72 190 67 199 62 185 46 183 36 165 40 134 57 115 74 106 60 109 90 97 112 94 92 93 130 86 154 88 134 81 183 90 197 94 183 86 212 95 211 88 224 83 235 88 248 97 246 90 257 107 255 97 270 120
Polygon -16777216 true false 234 100 220 96 210 100 214 111 228 116 239 115
Circle -16777216 true false 246 117 20
Line -7500403 true 270 153 282 174
Line -7500403 true 272 153 255 173
Line -7500403 true 269 156 268 177

mouse top
true
0
Polygon -7500403 true true 144 238 153 255 168 260 196 257 214 241 237 234 248 243 237 260 199 278 154 282 133 276 109 270 90 273 83 283 98 279 120 282 156 293 200 287 235 273 256 254 261 238 252 226 232 221 211 228 194 238 183 246 168 246 163 232
Polygon -7500403 true true 120 78 116 62 127 35 139 16 150 4 160 16 173 33 183 60 180 80
Polygon -7500403 true true 119 75 179 75 195 105 190 166 193 215 165 240 135 240 106 213 110 165 105 105
Polygon -7500403 true true 167 69 184 68 193 64 199 65 202 74 194 82 185 79 171 80
Polygon -7500403 true true 133 69 116 68 107 64 101 65 98 74 106 82 115 79 129 80
Polygon -16777216 true false 163 28 171 32 173 40 169 45 166 47
Polygon -16777216 true false 137 28 129 32 127 40 131 45 134 47
Polygon -16777216 true false 150 6 143 14 156 14
Line -7500403 true 161 17 195 10
Line -7500403 true 160 22 187 20
Line -7500403 true 160 22 201 31
Line -7500403 true 140 22 99 31
Line -7500403 true 140 22 113 20
Line -7500403 true 139 17 105 10

music notes 1
false
0
Polygon -7500403 true true 75 210 96 212 118 218 131 229 135 238 135 243 131 251 118 261 96 268 75 270 55 268 33 262 19 251 15 242 15 238 19 229 33 218 54 212
Rectangle -7500403 true true 120 90 135 255
Polygon -7500403 true true 225 165 246 167 268 173 281 184 285 193 285 198 281 206 268 216 246 223 225 225 205 223 183 217 169 206 165 197 165 193 169 184 183 173 204 167
Polygon -7500403 true true 120 60 120 105 285 45 285 0
Rectangle -7500403 true true 270 15 285 195

music notes 2
false
0
Polygon -7500403 true true 135 195 156 197 178 203 191 214 195 223 195 228 191 236 178 246 156 253 135 255 115 253 93 247 79 236 75 227 75 223 79 214 93 203 114 197
Rectangle -7500403 true true 180 30 195 225

music notes 3
false
0
Polygon -7500403 true true 135 195 156 197 178 203 191 214 195 223 195 228 191 236 178 246 156 253 135 255 115 253 93 247 79 236 75 227 75 223 79 214 93 203 114 197
Rectangle -7500403 true true 180 30 195 225
Polygon -7500403 true true 194 66 210 80 242 93 271 94 293 84 301 68 269 69 238 60 213 46 197 34 193 30

orbit 1
true
0
Circle -7500403 true true 116 11 67
Circle -7500403 false true 41 41 218

orbit 2
true
0
Circle -7500403 true true 116 221 67
Circle -7500403 true true 116 11 67
Circle -7500403 false true 44 44 212

orbit 3
true
0
Circle -7500403 true true 116 11 67
Circle -7500403 true true 26 176 67
Circle -7500403 true true 206 176 67
Circle -7500403 false true 45 45 210

orbit 4
true
0
Circle -7500403 true true 116 11 67
Circle -7500403 true true 116 221 67
Circle -7500403 true true 221 116 67
Circle -7500403 false true 45 45 210
Circle -7500403 true true 11 116 67

orbit 5
true
0
Circle -7500403 true true 116 11 67
Circle -7500403 true true 13 89 67
Circle -7500403 true true 178 206 67
Circle -7500403 true true 53 204 67
Circle -7500403 true true 220 91 67
Circle -7500403 false true 45 45 210

orbit 6
true
0
Circle -7500403 true true 116 11 67
Circle -7500403 true true 26 176 67
Circle -7500403 true true 206 176 67
Circle -7500403 false true 45 45 210
Circle -7500403 true true 26 58 67
Circle -7500403 true true 206 58 67
Circle -7500403 true true 116 221 67

paintbrush
false
0
Polygon -1 true false 87 191 103 218 238 53 223 38
Polygon -13345367 true false 104 204 104 218 239 53 235 47
Polygon -7500403 true true 99 173 83 175 71 186 64 207 52 235 45 251 77 238 108 227 124 205 118 185

pencil
false
0
Polygon -7500403 true true 255 60 255 90 105 240 90 225
Polygon -7500403 true true 60 195 75 210 240 45 210 45
Polygon -7500403 true true 90 195 105 210 255 60 240 45
Polygon -6459832 true false 90 195 60 195 45 255 105 240 105 210
Polygon -16777216 true false 45 255 74 248 75 240 60 225 51 225

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

pentamer
true
15
Circle -1 true true -4 116 67
Circle -1 true true 56 116 67
Circle -1 true true 116 116 67
Circle -1 true true 176 116 67
Circle -1 true true 236 116 67
Circle -16777216 false false -4 116 67
Circle -16777216 false false 56 116 68
Circle -16777216 false false 116 116 68
Circle -16777216 false false 175 116 68
Circle -16777216 false false 235 116 70

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person construction
false
0
Rectangle -7500403 true true 123 76 176 95
Polygon -1 true false 105 90 60 195 90 210 115 162 184 163 210 210 240 195 195 90
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Circle -7500403 true true 110 5 80
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -955883 true false 180 90 195 90 195 165 195 195 150 195 150 120 180 90
Polygon -955883 true false 120 90 105 90 105 165 105 195 150 195 150 120 120 90
Rectangle -16777216 true false 135 114 150 120
Rectangle -16777216 true false 135 144 150 150
Rectangle -16777216 true false 135 174 150 180
Polygon -955883 true false 105 42 111 16 128 2 149 0 178 6 190 18 192 28 220 29 216 34 201 39 167 35
Polygon -6459832 true false 54 253 54 238 219 73 227 78
Polygon -16777216 true false 15 285 15 255 30 225 45 225 75 255 75 270 45 285

person doctor
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13345367 true false 135 90 150 105 135 135 150 150 165 135 150 105 165 90
Polygon -7500403 true true 105 90 60 195 90 210 135 105
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 105 90 60 195 90 210 114 156 120 195 90 270 210 270 180 195 186 155 210 210 240 195 195 90 165 90 150 150 135 90
Line -16777216 false 150 148 150 270
Line -16777216 false 196 90 151 149
Line -16777216 false 104 90 149 149
Circle -1 true false 180 0 30
Line -16777216 false 180 15 120 15
Line -16777216 false 150 195 165 195
Line -16777216 false 150 240 165 240
Line -16777216 false 150 150 165 150

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

person graduate
false
0
Circle -16777216 false false 39 183 20
Polygon -1 true false 50 203 85 213 118 227 119 207 89 204 52 185
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -8630108 true false 90 19 150 37 210 19 195 4 105 4
Polygon -8630108 true false 120 90 105 90 60 195 90 210 120 165 90 285 105 300 195 300 210 285 180 165 210 210 240 195 195 90
Polygon -1184463 true false 135 90 120 90 150 135 180 90 165 90 150 105
Line -2674135 false 195 90 150 135
Line -2674135 false 105 90 150 135
Polygon -1 true false 135 90 150 105 165 90
Circle -1 true false 104 205 20
Circle -1 true false 41 184 20
Circle -16777216 false false 106 206 18
Line -2674135 false 208 22 208 57

person lumberjack
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -2674135 true false 60 196 90 211 114 155 120 196 180 196 187 158 210 211 240 196 195 91 165 91 150 106 150 135 135 91 105 91
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -6459832 true false 174 90 181 90 180 195 165 195
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -6459832 true false 126 90 119 90 120 195 135 195
Rectangle -6459832 true false 45 180 255 195
Polygon -16777216 true false 255 165 255 195 240 225 255 240 285 240 300 225 285 195 285 165
Line -16777216 false 135 165 165 165
Line -16777216 false 135 135 165 135
Line -16777216 false 90 135 120 135
Line -16777216 false 105 120 120 120
Line -16777216 false 180 120 195 120
Line -16777216 false 180 135 210 135
Line -16777216 false 90 150 105 165
Line -16777216 false 225 165 210 180
Line -16777216 false 75 165 90 180
Line -16777216 false 210 150 195 165
Line -16777216 false 180 105 210 180
Line -16777216 false 120 105 90 180
Line -16777216 false 150 135 150 165
Polygon -2674135 true false 100 30 104 44 189 24 185 10 173 10 166 1 138 -1 111 3 109 28

person police
false
0
Polygon -1 true false 124 91 150 165 178 91
Polygon -13345367 true false 134 91 149 106 134 181 149 196 164 181 149 106 164 91
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -13345367 true false 120 90 105 90 60 195 90 210 116 158 120 195 180 195 184 158 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Polygon -13345367 true false 150 26 110 41 97 29 137 -1 158 6 185 0 201 6 196 23 204 34 180 33
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Rectangle -16777216 true false 109 183 124 227
Rectangle -16777216 true false 176 183 195 205
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Polygon -1184463 true false 172 112 191 112 185 133 179 133
Polygon -1184463 true false 175 6 194 6 189 21 180 21
Line -1184463 false 149 24 197 24
Rectangle -16777216 true false 101 177 122 187
Rectangle -16777216 true false 179 164 183 186

person service
false
0
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -2674135 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -2674135 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Polygon -2674135 true false 155 91 128 77 128 101
Rectangle -16777216 true false 118 129 141 140
Polygon -2674135 true false 145 91 172 77 172 101

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

petals
false
0
Circle -7500403 true true 117 12 66
Circle -7500403 true true 116 221 67
Circle -7500403 true true 41 41 67
Circle -7500403 true true 11 116 67
Circle -7500403 true true 41 191 67
Circle -7500403 true true 191 191 67
Circle -7500403 true true 221 116 67
Circle -7500403 true true 191 41 67
Circle -7500403 true true 60 60 180

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

plant medium
false
0
Rectangle -7500403 true true 135 165 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 165 120 120 150 90 180 120 165 165

plant small
false
0
Rectangle -7500403 true true 135 240 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 240 120 195 150 165 180 195 165 240

police
false
0
Circle -7500403 false true 45 45 210
Polygon -7500403 true true 96 225 150 60 206 224 63 120 236 120
Polygon -7500403 true true 120 120 195 120 180 180 180 185 113 183
Polygon -7500403 false true 30 15 0 45 15 60 30 90 30 105 15 165 3 209 3 225 15 255 60 270 75 270 99 256 105 270 120 285 150 300 180 285 195 270 203 256 240 270 255 270 285 255 294 225 294 210 285 165 270 105 270 90 285 60 300 45 270 15 225 30 210 30 150 15 90 30 75 30

pumpkin
false
0
Polygon -7500403 false true 148 30 107 33 74 44 33 58 15 105 0 150 30 240 105 285 135 285 150 270 165 285 195 285 255 255 300 150 268 62 225 43 196 36
Polygon -7500403 true true 33 58 0 150 30 240 105 285 135 285 150 270 165 285 195 285 255 255 300 150 268 62 226 43 194 36 148 32 105 35
Polygon -16777216 false false 108 40 75 57 42 101 32 177 79 253 124 285 133 285 147 268 122 222 103 176 107 131 122 86 140 52 154 42 193 66 204 101 216 158 212 209 188 256 164 278 163 283 196 285 234 255 257 199 268 137 251 84 229 52 191 41 163 38 151 41
Polygon -6459832 true false 133 50 171 50 167 32 155 15 146 2 117 10 126 23 130 33
Polygon -16777216 false false 117 10 127 26 129 35 132 49 170 49 168 32 154 14 145 1

pushpin
false
0
Polygon -7500403 true true 130 158 105 180 93 205 119 196 142 173
Polygon -16777216 true false 121 112 111 128 109 143 112 158 123 175 138 184 156 189 169 188 186 177 199 158 139 98
Circle -7500403 true true 126 86 90
Polygon -16777216 true false 159 103 152 114 151 125 152 135 158 144 169 150 182 151 194 149 207 142 238 111 191 72
Polygon -16777216 true false 187 56 177 72 175 87 178 102 189 119 204 128 222 133 235 132 252 121 265 102 205 42
Circle -7500403 true true 190 30 90

rabbit
false
0
Polygon -7500403 true true 61 150 76 180 91 195 103 214 91 240 76 255 61 270 76 270 106 255 132 209 151 210 181 210 211 240 196 255 181 255 166 247 151 255 166 270 211 270 241 255 240 210 270 225 285 165 256 135 226 105 166 90 91 105
Polygon -7500403 true true 75 164 94 104 70 82 45 89 19 104 4 149 19 164 37 162 59 153
Polygon -7500403 true true 64 98 96 87 138 26 130 15 97 36 54 86
Polygon -7500403 true true 49 89 57 47 78 4 89 20 70 88
Circle -16777216 true false 37 103 16
Line -16777216 false 44 150 104 150
Line -16777216 false 39 158 84 175
Line -16777216 false 29 159 57 195
Polygon -5825686 true false 0 150 15 165 15 150
Polygon -5825686 true false 76 90 97 47 130 32
Line -16777216 false 180 210 165 180
Line -16777216 false 165 180 180 165
Line -16777216 false 180 165 225 165
Line -16777216 false 180 210 210 240

rec_dimer1
true
15
Circle -1 true true 90 120 60
Circle -16777216 false false 89 119 62
Polygon -10899396 true false 120 120 150 60 81 61 120 120
Polygon -10899396 true false 180 120 210 60 141 61 180 120
Polygon -16777216 false false 120 121 150 60 80 59 120 121
Polygon -16777216 false false 180 121 210 60 140 59 180 121

receptor
true
0
Polygon -7500403 true true 90 150 150 60 210 150 105 150 105 150

receptor-with-border
true
0
Polygon -7500403 true true 90 150 150 60 210 150 105 150 105 150
Line -1184463 false 150 60 90 150
Line -1184463 false 90 150 210 150
Line -1184463 false 150 60 210 150

receptors
true
15
Rectangle -1 true true 105 15 195 285
Polygon -7500403 true false 150 150
Line -16777216 false 105 15 195 15
Line -16777216 false 105 15 105 285
Line -16777216 false 195 15 195 285
Line -16777216 false 105 285 195 285

rocket
true
0
Polygon -7500403 true true 120 165 75 285 135 255 165 255 225 285 180 165
Polygon -1 true false 135 285 105 135 105 105 120 45 135 15 150 0 165 15 180 45 195 105 195 135 165 285
Rectangle -7500403 true true 147 176 153 288
Polygon -7500403 true true 120 45 180 45 165 15 150 0 135 15
Line -7500403 true 105 105 135 120
Line -7500403 true 135 120 165 120
Line -7500403 true 165 120 195 105
Line -7500403 true 105 135 135 150
Line -7500403 true 135 150 165 150
Line -7500403 true 165 150 195 135

rr
true
0
Polygon -10899396 true false 120 105 90 150 150 150
Line -16777216 false 120 105 90 150
Line -16777216 false 120 105 150 150
Line -16777216 false 210 150 90 150
Polygon -10899396 true false 180 105 150 150 210 150
Line -16777216 false 180 105 210 150
Line -16777216 false 180 105 150 150

rrs
true
0
Polygon -13840069 true false 115 150 184 150 151 90 114 150
Polygon -16777216 false false 120 135 114 150 183 149 150 90
Rectangle -7500403 true true 97 148 146 157
Polygon -13840069 true false 55 150 124 150 91 90 54 150
Polygon -16777216 false false 60 135 54 150 123 149 90 90
Rectangle -16777216 false false 105 148 154 158
Rectangle -7500403 true true 140 142 167 168
Rectangle -16777216 false false 139 142 168 169
Rectangle -7500403 true true 84 140 111 166
Rectangle -16777216 false false 82 140 111 167

rrs'
true
0
Polygon -13840069 true false 115 150 184 150 151 90 114 150
Polygon -16777216 false false 120 135 114 150 183 149 150 90
Rectangle -7500403 true true 157 148 206 157
Rectangle -16777216 false false 155 178 204 188
Rectangle -7500403 true true 144 140 171 166
Rectangle -7500403 true true 200 142 227 168
Rectangle -16777216 false false 200 141 229 168
Rectangle -16777216 false false 144 140 173 167
Polygon -13840069 true false 55 150 124 150 91 90 54 150
Polygon -16777216 false false 60 135 54 150 123 149 90 90

rrs*
true
8
Polygon -13840069 true false 115 150 184 150 151 90 114 150
Polygon -16777216 false false 120 135 114 150 183 149 150 90
Rectangle -11221820 true true 97 148 146 157
Polygon -13840069 true false 55 150 124 150 91 90 54 150
Polygon -16777216 false false 60 135 54 150 123 149 90 90
Rectangle -16777216 false false 105 148 154 158
Rectangle -11221820 true true 140 142 167 168
Rectangle -16777216 false false 139 142 168 169
Rectangle -11221820 true true 84 140 111 166
Rectangle -16777216 false false 82 140 111 167
Rectangle -16777216 false false 110 148 140 157

rrs*'
true
8
Polygon -13840069 true false 115 150 184 150 151 90 114 150
Polygon -16777216 false false 120 135 114 150 183 149 150 90
Rectangle -11221820 true true 157 148 206 157
Rectangle -16777216 false false 155 178 204 188
Rectangle -11221820 true true 144 140 171 166
Rectangle -11221820 true true 200 142 227 168
Rectangle -16777216 false false 200 141 229 168
Rectangle -16777216 false false 144 140 173 167
Polygon -13840069 true false 55 150 124 150 91 90 54 150
Polygon -16777216 false false 60 135 54 150 123 149 90 90

rs
true
0
Polygon -16777216 true false 115 150 184 150 151 90 114 150
Polygon -16777216 false false 120 135 114 150 183 149 150 90
Rectangle -7500403 true true 157 148 206 157
Rectangle -16777216 false false 155 148 204 158
Rectangle -7500403 true true 144 140 171 166
Rectangle -7500403 true true 200 142 227 168
Rectangle -16777216 false false 200 141 229 168
Rectangle -16777216 false false 144 140 173 167

rs*
true
8
Polygon -16777216 true false 115 150 184 150 151 90 114 150
Polygon -16777216 false false 120 135 114 150 183 149 150 90
Rectangle -11221820 true true 157 148 206 157
Rectangle -16777216 false false 170 148 219 158
Rectangle -11221820 true true 144 140 171 166
Rectangle -11221820 true true 200 142 227 168
Rectangle -16777216 false false 200 141 229 168
Rectangle -16777216 false false 144 140 173 167

sailboat side
false
0
Line -16777216 false 0 240 120 210
Polygon -7500403 true true 0 239 270 254 270 269 240 284 225 299 60 299 15 254
Polygon -1 true false 15 240 30 195 75 120 105 90 105 225
Polygon -1 true false 135 75 165 180 150 240 255 240 285 225 255 150 210 105
Line -16777216 false 105 90 120 60
Line -16777216 false 120 45 120 240
Line -16777216 false 150 240 120 240
Line -16777216 false 135 75 120 60
Polygon -7500403 true true 120 60 75 45 120 30
Polygon -16777216 false false 105 90 75 120 30 195 15 240 105 225
Polygon -16777216 false false 135 75 165 180 150 240 255 240 285 225 255 150 210 105
Polygon -16777216 false false 0 239 60 299 225 299 240 284 270 269 270 254

shark
false
0
Polygon -7500403 true true 283 153 288 149 271 146 301 145 300 138 247 119 190 107 104 117 54 133 39 134 10 99 9 112 19 142 9 175 10 185 40 158 69 154 64 164 80 161 86 156 132 160 209 164
Polygon -7500403 true true 199 161 152 166 137 164 169 154
Polygon -7500403 true true 188 108 172 83 160 74 156 76 159 97 153 112
Circle -16777216 true false 256 129 12
Line -16777216 false 222 134 222 150
Line -16777216 false 217 134 217 150
Line -16777216 false 212 134 212 150
Polygon -7500403 true true 78 125 62 118 63 130
Polygon -7500403 true true 121 157 105 161 101 156 106 152

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

sheep 2
false
0
Polygon -7500403 true true 209 183 194 198 179 198 164 183 164 174 149 183 89 183 74 168 59 198 44 198 29 185 43 151 28 121 44 91 59 80 89 80 164 95 194 80 254 65 269 80 284 125 269 140 239 125 224 153 209 168
Rectangle -7500403 true true 180 195 195 225
Rectangle -7500403 true true 45 195 60 225
Rectangle -16777216 true false 180 225 195 240
Rectangle -16777216 true false 45 225 60 240
Polygon -7500403 true true 245 60 250 72 240 78 225 63 230 51
Polygon -7500403 true true 25 72 40 80 42 98 22 91
Line -16777216 false 270 137 251 122
Line -16777216 false 266 90 254 90

spider
true
0
Polygon -7500403 true true 134 255 104 240 96 210 98 196 114 171 134 150 119 135 119 120 134 105 164 105 179 120 179 135 164 150 185 173 199 195 203 210 194 240 164 255
Line -7500403 true 167 109 170 90
Line -7500403 true 170 91 156 88
Line -7500403 true 130 91 144 88
Line -7500403 true 133 109 130 90
Polygon -7500403 true true 167 117 207 102 216 71 227 27 227 72 212 117 167 132
Polygon -7500403 true true 164 210 158 194 195 195 225 210 195 285 240 210 210 180 164 180
Polygon -7500403 true true 136 210 142 194 105 195 75 210 105 285 60 210 90 180 136 180
Polygon -7500403 true true 133 117 93 102 84 71 73 27 73 72 88 117 133 132
Polygon -7500403 true true 163 140 214 129 234 114 255 74 242 126 216 143 164 152
Polygon -7500403 true true 161 183 203 167 239 180 268 239 249 171 202 153 163 162
Polygon -7500403 true true 137 140 86 129 66 114 45 74 58 126 84 143 136 152
Polygon -7500403 true true 139 183 97 167 61 180 32 239 51 171 98 153 137 162

spinner
true
0
Polygon -7500403 true true 150 0 105 75 195 75
Polygon -7500403 true true 135 74 135 150 139 159 147 164 154 164 161 159 165 151 165 74

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

squirrel
false
0
Polygon -7500403 true true 87 267 106 290 145 292 157 288 175 292 209 292 207 281 190 276 174 277 156 271 154 261 157 245 151 230 156 221 171 209 214 165 231 171 239 171 263 154 281 137 294 136 297 126 295 119 279 117 241 145 242 128 262 132 282 124 288 108 269 88 247 73 226 72 213 76 208 88 190 112 151 107 119 117 84 139 61 175 57 210 65 231 79 253 65 243 46 187 49 157 82 109 115 93 146 83 202 49 231 13 181 12 142 6 95 30 50 39 12 96 0 162 23 250 68 275
Polygon -16777216 true false 237 85 249 84 255 92 246 95
Line -16777216 false 221 82 213 93
Line -16777216 false 253 119 266 124
Line -16777216 false 278 110 278 116
Line -16777216 false 149 229 135 211
Line -16777216 false 134 211 115 207
Line -16777216 false 117 207 106 211
Line -16777216 false 91 268 131 290
Line -16777216 false 220 82 213 79
Line -16777216 false 286 126 294 128
Line -16777216 false 193 284 206 285

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

strawberry
false
0
Polygon -7500403 false true 149 47 103 36 72 45 58 62 37 88 35 114 34 141 84 243 122 290 151 280 162 288 194 287 239 227 284 122 267 64 224 45 194 38
Polygon -7500403 true true 72 47 38 88 34 139 85 245 122 289 150 281 164 288 194 288 239 228 284 123 267 65 225 46 193 39 149 48 104 38
Polygon -10899396 true false 136 62 91 62 136 77 136 92 151 122 166 107 166 77 196 92 241 92 226 77 196 62 226 62 241 47 166 57 136 32
Polygon -16777216 false false 135 62 90 62 135 75 135 90 150 120 166 107 165 75 196 92 240 92 225 75 195 61 226 62 239 47 165 56 135 30
Line -16777216 false 105 120 90 135
Line -16777216 false 75 120 90 135
Line -16777216 false 75 150 60 165
Line -16777216 false 45 150 60 165
Line -16777216 false 90 180 105 195
Line -16777216 false 120 180 105 195
Line -16777216 false 120 225 105 240
Line -16777216 false 90 225 105 240
Line -16777216 false 120 255 135 270
Line -16777216 false 120 135 135 150
Line -16777216 false 135 210 150 225
Line -16777216 false 165 180 180 195

suit club
false
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122

suit diamond
false
0
Polygon -7500403 true true 150 15 45 150 150 285 255 150

suit heart
false
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135

suit spade
false
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210

sun
false
0
Circle -7500403 true true 75 75 150
Polygon -7500403 true true 300 150 240 120 240 180
Polygon -7500403 true true 150 0 120 60 180 60
Polygon -7500403 true true 150 300 120 240 180 240
Polygon -7500403 true true 0 150 60 120 60 180
Polygon -7500403 true true 60 195 105 240 45 255
Polygon -7500403 true true 60 105 105 60 45 45
Polygon -7500403 true true 195 60 240 105 255 45
Polygon -7500403 true true 240 195 195 240 255 255

syk
true
0
Rectangle -7500403 true true 45 120 90 165
Rectangle -7500403 true true 210 120 255 165
Rectangle -7500403 true true 90 135 210 150
Rectangle -16777216 false false 45 120 90 165
Rectangle -16777216 false false 210 120 255 165

syk-old
true
15
Rectangle -1 true true 15 105 105 195
Rectangle -1 true true 195 105 285 195
Rectangle -7500403 true false 105 135 195 165
Rectangle -16777216 false false 15 105 105 195
Rectangle -16777216 false false 195 105 285 195
Rectangle -16777216 false false 105 135 195 165

sykfactive
true
15
Rectangle -11221820 true false 15 105 105 195
Rectangle -11221820 true false 195 105 285 195
Rectangle -7500403 true false 105 135 195 165
Rectangle -16777216 false false 15 105 105 195
Rectangle -16777216 false false 195 105 285 195
Rectangle -16777216 false false 105 135 195 165

tank
true
0
Rectangle -7500403 true true 144 0 159 105
Rectangle -6459832 true false 195 45 255 255
Rectangle -16777216 false false 195 45 255 255
Rectangle -6459832 true false 45 45 105 255
Rectangle -16777216 false false 45 45 105 255
Line -16777216 false 45 75 255 75
Line -16777216 false 45 105 255 105
Line -16777216 false 45 60 255 60
Line -16777216 false 45 240 255 240
Line -16777216 false 45 225 255 225
Line -16777216 false 45 195 255 195
Line -16777216 false 45 150 255 150
Polygon -7500403 true true 90 60 60 90 60 240 120 255 180 255 240 240 240 90 210 60
Rectangle -16777216 false false 135 105 165 120
Polygon -16777216 false false 135 120 105 135 101 181 120 225 149 234 180 225 199 182 195 135 165 120
Polygon -16777216 false false 240 90 210 60 211 246 240 240
Polygon -16777216 false false 60 90 90 60 89 246 60 240
Polygon -16777216 false false 89 247 116 254 183 255 211 246 211 237 89 236
Rectangle -16777216 false false 90 60 210 90
Rectangle -16777216 false false 143 0 158 105

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

telephone
false
0
Polygon -7500403 true true 75 273 60 255 60 195 84 165 75 165 45 150 45 120 60 90 105 75 195 75 240 90 255 120 255 150 223 165 215 165 240 195 240 255 226 274
Polygon -16777216 false false 75 273 60 255 60 195 105 135 105 120 105 105 120 105 120 120 180 120 180 105 195 105 195 135 240 195 240 255 225 273
Polygon -16777216 false false 81 165 74 165 44 150 44 120 59 90 104 75 194 75 239 90 254 120 254 150 218 167 194 135 194 105 179 105 179 120 119 120 119 105 104 105 104 135 81 166 78 165
Rectangle -16777216 false false 120 165 135 180
Rectangle -16777216 false false 165 165 180 180
Rectangle -16777216 false false 142 165 157 180
Rectangle -16777216 false false 165 188 180 203
Rectangle -16777216 false false 142 188 157 203
Rectangle -16777216 false false 120 188 135 203
Rectangle -16777216 false false 120 210 135 225
Rectangle -16777216 false false 142 210 157 225
Rectangle -16777216 false false 165 210 180 225
Rectangle -16777216 false false 120 233 135 248
Rectangle -16777216 false false 142 233 157 248
Rectangle -16777216 false false 165 233 180 248

tetramer
true
15
Circle -1 true true 14 120 67
Circle -1 true true 82 119 67
Circle -1 true true 150 118 67
Circle -1 true true 218 120 67
Circle -16777216 false false 11 118 72
Circle -16777216 false false 90 120 0
Circle -16777216 false false 80 118 70
Circle -16777216 false false 148 117 70
Circle -16777216 false false 216 120 70

tetramer1
true
15
Circle -1 true true 14 120 67
Circle -1 true true 82 119 67
Circle -1 true true 150 118 67
Circle -1 true true 218 120 67
Circle -16777216 false false 11 118 72
Circle -16777216 false false 90 120 0
Circle -16777216 false false 80 118 70
Circle -16777216 false false 148 117 70
Circle -16777216 false false 216 120 70
Polygon -1184463 true false 53 122 53 122 94 59 17 59 53 122
Polygon -16777216 false false 53 120 95 57 15 59 52 119

tetramer2
true
15
Circle -1 true true 14 120 67
Circle -1 true true 82 119 67
Circle -1 true true 150 118 67
Circle -1 true true 218 120 67
Circle -16777216 false false 11 118 72
Circle -16777216 false false 90 120 0
Circle -16777216 false false 80 118 70
Circle -16777216 false false 148 117 70
Circle -16777216 false false 216 120 70
Polygon -1 true true 105 75
Polygon -1184463 true false 120 120 150 60 75 60 120 120
Polygon -1184463 true false 184 120 225 60 165 60 150 60 186 119
Polygon -16777216 false false 122 121 150 60 76 60 118 117 121 117
Polygon -16777216 false false 152 59 224 59 186 118 151 63

tetramer3
true
15
Circle -1 true true 14 120 67
Circle -1 true true 82 119 67
Circle -1 true true 150 118 67
Circle -1 true true 218 120 67
Circle -16777216 false false 11 118 72
Circle -16777216 false false 90 120 0
Circle -16777216 false false 80 118 70
Circle -16777216 false false 148 117 70
Circle -16777216 false false 216 120 70
Polygon -1 true true 105 75
Polygon -1184463 true false 120 120 150 60 75 60 120 120
Polygon -1184463 true false 184 120 225 60 165 60 150 60 186 119
Polygon -16777216 false false 122 121 150 60 76 60 118 117 121 117
Polygon -16777216 false false 152 59 224 59 186 118 151 63
Polygon -1184463 true false 259 120 293 60 223 60 259 120
Polygon -16777216 false false 260 118 293 60 223 60 258 118

tetramer4
true
15
Circle -1 true true 14 120 67
Circle -1 true true 82 119 67
Circle -1 true true 150 118 67
Circle -1 true true 218 120 67
Circle -16777216 false false 11 118 72
Circle -16777216 false false 90 120 0
Circle -16777216 false false 80 118 70
Circle -16777216 false false 148 117 70
Circle -16777216 false false 216 120 70
Polygon -1 true true 105 75
Polygon -1184463 true false 120 120 150 60 75 60 120 120
Polygon -1184463 true false 184 120 225 60 165 60 150 60 186 119
Polygon -16777216 false false 122 121 150 60 76 60 118 117 121 117
Polygon -16777216 false false 152 59 224 59 186 118 151 63
Polygon -1184463 true false 259 120 293 60 223 60 259 120
Polygon -16777216 false false 260 118 293 60 223 60 258 118
Polygon -1184463 true false 45 120 75 60 7 62 45 120
Polygon -16777216 false false 46 117 73 60 6 61 44 118

tile brick
false
0
Rectangle -1 true false 0 0 300 300
Rectangle -7500403 true true 15 225 150 285
Rectangle -7500403 true true 165 225 300 285
Rectangle -7500403 true true 75 150 210 210
Rectangle -7500403 true true 0 150 60 210
Rectangle -7500403 true true 225 150 300 210
Rectangle -7500403 true true 165 75 300 135
Rectangle -7500403 true true 15 75 150 135
Rectangle -7500403 true true 0 0 60 60
Rectangle -7500403 true true 225 0 300 60
Rectangle -7500403 true true 75 0 210 60

tile log
false
0
Rectangle -7500403 true true 0 0 300 300
Line -16777216 false 0 30 45 15
Line -16777216 false 45 15 120 30
Line -16777216 false 120 30 180 45
Line -16777216 false 180 45 225 45
Line -16777216 false 225 45 165 60
Line -16777216 false 165 60 120 75
Line -16777216 false 120 75 30 60
Line -16777216 false 30 60 0 60
Line -16777216 false 300 30 270 45
Line -16777216 false 270 45 255 60
Line -16777216 false 255 60 300 60
Polygon -16777216 false false 15 120 90 90 136 95 210 75 270 90 300 120 270 150 195 165 150 150 60 150 30 135
Polygon -16777216 false false 63 134 166 135 230 142 270 120 210 105 116 120 88 122
Polygon -16777216 false false 22 45 84 53 144 49 50 31
Line -16777216 false 0 180 15 180
Line -16777216 false 15 180 105 195
Line -16777216 false 105 195 180 195
Line -16777216 false 225 210 165 225
Line -16777216 false 165 225 60 225
Line -16777216 false 60 225 0 210
Line -16777216 false 300 180 264 191
Line -16777216 false 255 225 300 210
Line -16777216 false 16 196 116 211
Line -16777216 false 180 300 105 285
Line -16777216 false 135 255 240 240
Line -16777216 false 240 240 300 255
Line -16777216 false 135 255 105 285
Line -16777216 false 180 0 240 15
Line -16777216 false 240 15 300 0
Line -16777216 false 0 300 45 285
Line -16777216 false 45 285 45 270
Line -16777216 false 45 270 0 255
Polygon -16777216 false false 150 270 225 300 300 285 228 264
Line -16777216 false 223 209 255 225
Line -16777216 false 179 196 227 183
Line -16777216 false 228 183 266 192

tile stones
false
0
Polygon -7500403 true true 0 240 45 195 75 180 90 165 90 135 45 120 0 135
Polygon -7500403 true true 300 240 285 210 270 180 270 150 300 135 300 225
Polygon -7500403 true true 225 300 240 270 270 255 285 255 300 285 300 300
Polygon -7500403 true true 0 285 30 300 0 300
Polygon -7500403 true true 225 0 210 15 210 30 255 60 285 45 300 30 300 0
Polygon -7500403 true true 0 30 30 0 0 0
Polygon -7500403 true true 15 30 75 0 180 0 195 30 225 60 210 90 135 60 45 60
Polygon -7500403 true true 0 105 30 105 75 120 105 105 90 75 45 75 0 60
Polygon -7500403 true true 300 60 240 75 255 105 285 120 300 105
Polygon -7500403 true true 120 75 120 105 105 135 105 165 165 150 240 150 255 135 240 105 210 105 180 90 150 75
Polygon -7500403 true true 75 300 135 285 195 300
Polygon -7500403 true true 30 285 75 285 120 270 150 270 150 210 90 195 60 210 15 255
Polygon -7500403 true true 180 285 240 255 255 225 255 195 240 165 195 165 150 165 135 195 165 210 165 255

tile water
false
0
Rectangle -7500403 true true -1 0 299 300
Polygon -1 true false 105 259 180 290 212 299 168 271 103 255 32 221 1 216 35 234
Polygon -1 true false 300 161 248 127 195 107 245 141 300 167
Polygon -1 true false 0 157 45 181 79 194 45 166 0 151
Polygon -1 true false 179 42 105 12 60 0 120 30 180 45 254 77 299 93 254 63
Polygon -1 true false 99 91 50 71 0 57 51 81 165 135
Polygon -1 true false 194 224 258 254 295 261 211 221 144 199

tooth
false
0
Polygon -7500403 true true 75 30 60 45 45 75 45 90 60 135 73 156 75 170 60 240 60 270 75 285 90 285 105 255 135 180 150 165 165 165 180 185 195 270 210 285 240 270 245 209 244 179 237 154 237 143 255 90 255 60 225 30 210 30 180 45 135 45 90 30
Polygon -7500403 false true 75 30 60 45 45 75 45 90 60 135 73 158 74 170 60 240 60 270 75 285 90 285 105 255 135 180 150 165 165 165 177 183 195 270 210 285 240 270 245 210 244 179 236 153 236 144 255 90 255 60 225 30 210 30 180 45 135 45 90 30 75 30

train
false
0
Rectangle -7500403 true true 30 105 240 150
Polygon -7500403 true true 240 105 270 30 180 30 210 105
Polygon -7500403 true true 195 180 270 180 300 210 195 210
Circle -7500403 true true 0 165 90
Circle -7500403 true true 240 225 30
Circle -7500403 true true 90 165 90
Circle -7500403 true true 195 225 30
Rectangle -7500403 true true 0 30 105 150
Rectangle -16777216 true false 30 60 75 105
Polygon -7500403 true true 195 180 165 150 240 150 240 180
Rectangle -7500403 true true 135 75 165 105
Rectangle -7500403 true true 225 120 255 150
Rectangle -16777216 true false 30 203 150 218

train freight boxcar
false
0
Rectangle -7500403 true true 10 100 290 195
Rectangle -16777216 false false 9 99 289 195
Circle -16777216 true false 253 195 30
Circle -16777216 true false 220 195 30
Circle -16777216 true false 50 195 30
Circle -16777216 true false 17 195 30
Rectangle -16777216 true false 290 180 299 195
Rectangle -16777216 true false 105 90 135 90
Rectangle -16777216 true false 1 180 10 195
Rectangle -16777216 false false 105 105 195 180
Line -16777216 false 150 105 150 180

train freight engine
false
0
Rectangle -7500403 true true 0 180 300 195
Polygon -7500403 true true 281 194 282 134 278 126 165 120 165 105 15 105 15 150 15 195 15 210 285 210
Polygon -955883 true false 281 179 263 150 225 150 15 150 15 135 270 135 282 148
Circle -16777216 true false 17 195 30
Circle -16777216 true false 50 195 30
Circle -16777216 true false 205 195 30
Circle -16777216 true false 238 195 30
Rectangle -7500403 true true 164 90 224 195
Rectangle -16777216 true false 176 98 214 120
Line -7500403 true 196 90 196 150
Rectangle -16777216 false false 165 90 225 180
Rectangle -16777216 false false 0 195 300 180
Rectangle -1 true false 11 111 18 118
Rectangle -1 true false 280 131 287 138
Rectangle -16777216 true false 91 195 201 212
Rectangle -16777216 true false 1 180 10 195
Line -16777216 false 290 150 291 182
Rectangle -7500403 true true 88 97 119 106
Rectangle -7500403 true true 42 96 73 105
Line -16777216 false 165 105 15 105
Rectangle -16777216 true false 165 90 195 90
Line -16777216 false 252 116 237 116
Rectangle -1184463 true false 199 85 208 92
Rectangle -16777216 true false 290 180 299 195
Line -16777216 false 224 98 165 98

train freight hopper empty
false
0
Circle -16777216 true false 253 195 30
Circle -16777216 true false 220 195 30
Circle -16777216 true false 50 195 30
Circle -16777216 true false 17 195 30
Rectangle -16777216 true false 105 90 135 90
Rectangle -16777216 true false 285 180 294 195
Polygon -7500403 true true 15 105 15 120 45 180 45 195 255 195 255 180 285 120 285 105
Rectangle -7500403 false true 15 105 285 195
Rectangle -16777216 true false 6 180 15 195
Polygon -7500403 true true 90 195 105 210 120 195
Polygon -7500403 true true 135 195 150 210 165 195
Polygon -7500403 true true 180 195 195 210 210 195
Polygon -16777216 false false 15 105 15 120 45 180 45 195 255 195 255 180 285 120 285 105
Line -16777216 false 60 105 60 195
Line -16777216 false 240 105 240 195
Line -16777216 false 180 105 180 195
Line -16777216 false 120 105 120 195

train freight hopper full
false
0
Circle -16777216 true false 253 195 30
Circle -16777216 true false 220 195 30
Circle -16777216 true false 50 195 30
Circle -16777216 true false 17 195 30
Rectangle -16777216 true false 105 90 135 90
Rectangle -16777216 true false 285 180 294 195
Polygon -7500403 true true 15 105 15 120 45 180 45 195 255 195 255 180 285 120 285 105
Rectangle -7500403 false true 15 105 285 195
Rectangle -16777216 true false 6 180 15 195
Polygon -7500403 true true 90 195 105 210 120 195
Polygon -7500403 true true 135 195 150 210 165 195
Polygon -7500403 true true 180 195 195 210 210 195
Polygon -16777216 false false 15 105 15 120 45 180 45 195 255 195 255 180 285 120 285 105
Line -16777216 false 60 105 60 195
Line -16777216 false 240 105 240 195
Line -16777216 false 180 105 180 195
Line -16777216 false 120 105 120 195
Polygon -6459832 true false 15 106 60 83 97 75 133 66 186 76 235 79 285 106

train passenger car
false
0
Polygon -7500403 true true 15 206 15 150 15 135 30 120 270 120 285 135 285 150 285 206 270 210 30 210
Circle -16777216 true false 240 195 30
Circle -16777216 true false 210 195 30
Circle -16777216 true false 60 195 30
Circle -16777216 true false 30 195 30
Rectangle -16777216 true false 30 140 268 165
Line -7500403 true 60 135 60 165
Line -7500403 true 60 135 60 165
Line -7500403 true 90 135 90 165
Line -7500403 true 120 135 120 165
Line -7500403 true 150 135 150 165
Line -7500403 true 180 135 180 165
Line -7500403 true 210 135 210 165
Line -7500403 true 240 135 240 165
Rectangle -16777216 true false 5 195 19 207
Rectangle -16777216 true false 281 195 295 207
Rectangle -13345367 true false 15 165 285 173
Rectangle -2674135 true false 15 180 285 188

train passenger engine
false
0
Rectangle -7500403 true true 0 180 300 195
Polygon -7500403 true true 283 161 274 128 255 114 231 105 165 105 15 105 15 150 15 195 15 210 285 210
Circle -16777216 true false 17 195 30
Circle -16777216 true false 50 195 30
Circle -16777216 true false 220 195 30
Circle -16777216 true false 253 195 30
Rectangle -16777216 false false 0 195 300 180
Rectangle -1 true false 11 111 18 118
Rectangle -1 true false 270 129 277 136
Rectangle -16777216 true false 91 195 210 210
Rectangle -16777216 true false 1 180 10 195
Line -16777216 false 290 150 291 182
Rectangle -16777216 true false 165 90 195 90
Rectangle -16777216 true false 290 180 299 195
Polygon -13345367 true false 285 180 267 158 239 135 180 120 15 120 16 113 180 113 240 120 270 135 282 154
Polygon -2674135 true false 284 179 267 160 239 139 180 127 15 127 16 120 180 120 240 127 270 142 282 161
Rectangle -16777216 true false 210 115 254 135
Line -7500403 true 225 105 225 150
Line -7500403 true 240 105 240 150

train switcher engine
false
0
Polygon -7500403 true true 45 210 45 180 45 150 53 130 151 123 248 131 255 150 255 195 255 210 60 210
Circle -16777216 true false 225 195 30
Circle -16777216 true false 195 195 30
Circle -16777216 true false 75 195 30
Circle -16777216 true false 45 195 30
Line -7500403 true 150 135 150 165
Rectangle -7500403 true true 120 90 180 195
Rectangle -16777216 true false 132 98 170 120
Line -7500403 true 150 90 150 150
Rectangle -16777216 false false 120 90 180 180
Rectangle -7500403 true true 30 180 270 195
Rectangle -16777216 false false 30 180 270 195
Line -16777216 false 270 150 270 180
Rectangle -1 true false 245 131 252 138
Rectangle -1 true false 48 131 55 138
Polygon -16777216 true false 255 179 227 169 227 158 255 168
Polygon -16777216 true false 255 162 227 152 227 141 255 151
Polygon -16777216 true false 45 162 73 152 73 141 45 151
Polygon -16777216 true false 45 179 73 169 73 158 45 168
Rectangle -16777216 true false 112 195 187 210
Rectangle -16777216 true false 264 180 279 195
Rectangle -16777216 true false 21 180 36 195
Line -16777216 false 30 150 30 180
Line -16777216 false 120 98 180 98

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

tree pine
false
0
Rectangle -6459832 true false 120 225 180 300
Polygon -7500403 true true 150 240 240 270 150 135 60 270
Polygon -7500403 true true 150 75 75 210 150 195 225 210
Polygon -7500403 true true 150 7 90 157 150 142 210 157 150 7

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Line -16777216 false 150 30 15 255
Line -16777216 false 150 30 285 255
Line -16777216 false 285 255 15 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

trimer
true
15
Circle -1 true true 51 117 67
Circle -1 true true 116 116 67
Circle -1 true true 182 118 66
Circle -16777216 false false 51 117 67
Circle -16777216 false false 116 115 68
Circle -16777216 false false 182 118 66

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

truck cab only
false
0
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Rectangle -1 true false 291 158 300 173

truck cab top
true
0
Rectangle -7500403 true true 70 45 227 120
Polygon -7500403 true true 150 8 118 10 96 17 90 30 75 135 75 195 90 210 150 210 210 210 225 195 225 135 209 30 201 17 179 10
Polygon -16777216 true false 94 135 118 119 184 119 204 134 193 141 110 141
Line -16777216 false 130 14 168 14
Line -16777216 false 130 18 168 18
Line -16777216 false 130 11 168 11
Line -16777216 false 185 29 194 112
Line -16777216 false 115 29 106 112
Line -16777216 false 195 225 210 240
Line -16777216 false 105 225 90 240
Polygon -16777216 true false 210 195 195 195 195 150 210 143
Polygon -16777216 false false 90 143 90 195 105 195 105 150 90 143
Polygon -16777216 true false 90 195 105 195 105 150 90 143
Line -7500403 true 210 180 195 180
Line -7500403 true 90 180 105 180
Line -16777216 false 212 44 213 124
Line -16777216 false 88 44 87 124
Line -16777216 false 223 130 193 112
Rectangle -7500403 true true 225 133 244 139
Rectangle -7500403 true true 56 133 75 139
Rectangle -7500403 true true 120 210 180 240
Rectangle -7500403 true true 93 238 210 270
Rectangle -16777216 true false 200 217 224 278
Rectangle -16777216 true false 76 217 100 278
Circle -16777216 false false 135 240 30
Line -16777216 false 77 130 107 112
Rectangle -16777216 false false 107 149 192 210
Rectangle -1 true false 180 9 203 17
Rectangle -1 true false 97 9 120 17

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

turtle 2
true
0
Polygon -10899396 true false 132 85 134 64 130 57 132 32 151 22 171 33 173 57 169 65 172 87
Polygon -10899396 true false 165 210 195 210 240 240 240 255 210 285 195 255
Polygon -10899396 true false 90 210 60 240 60 255 90 285 105 255 120 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 209 225 155 275 143 275 89 225 74 135 88 99
Polygon -16777216 true false 151 21 142 26 159 26
Line -16777216 false 160 35 164 51
Polygon -16777216 true false 161 38 162 46 167 45
Line -16777216 false 169 63 156 69
Line -16777216 false 134 64 144 69
Line -16777216 false 143 69 156 69
Polygon -16777216 true false 139 38 138 46 133 45
Line -16777216 false 140 35 136 51
Polygon -10899396 true false 195 90 225 75 255 75 270 90 285 120 285 150 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 45 75 30 90 15 120 15 150 60 105 75 105 90 105

ufo side
false
0
Polygon -1 true false 0 150 15 180 60 210 120 225 180 225 240 210 285 180 300 150 300 135 285 120 240 105 195 105 150 105 105 105 60 105 15 120 0 135
Polygon -16777216 false false 105 105 60 105 15 120 0 135 0 150 15 180 60 210 120 225 180 225 240 210 285 180 300 150 300 135 285 120 240 105 210 105
Polygon -7500403 true true 60 131 90 161 135 176 165 176 210 161 240 131 225 101 195 71 150 60 105 71 75 101
Circle -16777216 false false 255 135 30
Circle -16777216 false false 180 180 30
Circle -16777216 false false 90 180 30
Circle -16777216 false false 15 135 30
Circle -7500403 true true 15 135 30
Circle -7500403 true true 90 180 30
Circle -7500403 true true 180 180 30
Circle -7500403 true true 255 135 30
Polygon -16777216 false false 150 59 105 70 75 100 60 130 90 160 135 175 165 175 210 160 240 130 225 100 195 70

ufo top
false
0
Circle -1 true false 15 15 270
Circle -16777216 false false 15 15 270
Circle -7500403 true true 75 75 150
Circle -16777216 false false 75 75 150
Circle -7500403 true true 60 60 30
Circle -7500403 true true 135 30 30
Circle -7500403 true true 210 60 30
Circle -7500403 true true 240 135 30
Circle -7500403 true true 210 210 30
Circle -7500403 true true 135 240 30
Circle -7500403 true true 60 210 30
Circle -7500403 true true 30 135 30
Circle -16777216 false false 30 135 30
Circle -16777216 false false 60 210 30
Circle -16777216 false false 135 240 30
Circle -16777216 false false 210 210 30
Circle -16777216 false false 240 135 30
Circle -16777216 false false 210 60 30
Circle -16777216 false false 135 30 30
Circle -16777216 false false 60 60 30

van side
false
0
Polygon -7500403 true true 26 147 18 125 36 61 161 61 177 67 195 90 242 97 262 110 273 129 260 149
Circle -16777216 true false 43 123 42
Circle -16777216 true false 194 124 42
Polygon -16777216 true false 45 68 37 95 183 96 169 69
Line -7500403 true 62 65 62 103
Line -7500403 true 115 68 120 100
Polygon -1 true false 271 127 258 126 257 114 261 109
Rectangle -16777216 true false 19 131 27 142

van top
true
0
Polygon -7500403 true true 90 117 71 134 228 133 210 117
Polygon -7500403 true true 150 8 118 10 96 17 85 30 84 264 89 282 105 293 149 294 192 293 209 282 215 265 214 31 201 17 179 10
Polygon -16777216 true false 94 129 105 120 195 120 204 128 180 150 120 150
Polygon -16777216 true false 90 270 105 255 105 150 90 135
Polygon -16777216 true false 101 279 120 286 180 286 198 281 195 270 105 270
Polygon -16777216 true false 210 270 195 255 195 150 210 135
Polygon -1 true false 201 16 201 26 179 20 179 10
Polygon -1 true false 99 16 99 26 121 20 121 10
Line -16777216 false 130 14 168 14
Line -16777216 false 130 18 168 18
Line -16777216 false 130 11 168 11
Line -16777216 false 185 29 194 112
Line -16777216 false 115 29 106 112
Line -7500403 false 210 180 195 180
Line -7500403 false 195 225 210 240
Line -7500403 false 105 225 90 240
Line -7500403 false 90 180 105 180

warning
false
0
Polygon -7500403 true true 0 240 15 270 285 270 300 240 165 15 135 15
Polygon -16777216 true false 180 75 120 75 135 180 165 180
Circle -16777216 true false 129 204 42

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

wolf 2
false
0
Rectangle -7500403 true true 195 106 285 150
Rectangle -7500403 true true 195 90 255 105
Polygon -7500403 true true 240 90 217 44 196 90
Polygon -16777216 true false 234 89 218 59 203 89
Rectangle -1 true false 240 93 252 105
Rectangle -16777216 true false 242 96 249 104
Rectangle -16777216 true false 241 125 285 139
Polygon -1 true false 285 125 277 138 269 125
Polygon -1 true false 269 140 262 125 256 140
Rectangle -7500403 true true 45 120 195 195
Rectangle -7500403 true true 45 114 185 120
Rectangle -7500403 true true 165 195 180 270
Rectangle -7500403 true true 60 195 75 270
Polygon -7500403 true true 45 105 15 30 15 75 45 150 60 120

wolf 3
false
0
Polygon -7500403 true true 105 180 75 180 45 75 45 0 105 45 195 45 255 0 255 75 225 180 195 180 165 300 135 300 105 180 75 180
Polygon -16777216 true false 225 90 210 135 150 90
Polygon -16777216 true false 75 90 90 135 150 90

wolf 4
false
0
Polygon -7500403 true true 105 75 105 45 45 0 30 45 45 60 60 90
Polygon -7500403 true true 45 165 30 135 45 120 15 105 60 75 105 60 180 60 240 75 285 105 255 120 270 135 255 165 270 180 255 195 255 210 240 195 195 225 210 255 180 300 120 300 90 255 105 225 60 195 45 210 45 195 30 180
Polygon -16777216 true false 120 300 135 285 120 270 120 255 180 255 180 270 165 285 180 300
Polygon -16777216 true false 240 135 180 165 180 135
Polygon -16777216 true false 60 135 120 165 120 135
Polygon -7500403 true true 195 75 195 45 255 0 270 45 255 60 240 90
Polygon -16777216 true false 225 75 210 60 210 45 255 15 255 45 225 60
Polygon -16777216 true false 75 75 90 60 90 45 45 15 45 45 75 60

wolf 5
false
0
Polygon -7500403 true true 135 285 165 285 270 90 30 90 135 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Polygon -1 true false 225 150 180 195 165 165
Polygon -1 true false 75 150 120 195 135 165
Polygon -1 true false 135 285 135 255 150 240 165 255 165 285

wolf 6
false
0
Polygon -7500403 true true 105 75 105 45 45 0 30 45 45 60 60 90
Polygon -7500403 true true 45 165 30 135 45 120 15 105 60 75 105 60 180 60 240 75 285 105 255 120 270 135 255 165 270 180 255 195 255 210 240 195 195 225 210 255 180 300 120 300 90 255 105 225 60 195 45 210 45 195 30 180
Polygon -16777216 true false 120 300 135 285 120 270 120 255 180 255 180 270 165 285 180 300
Polygon -7500403 true true 195 75 195 45 255 0 270 45 255 60 240 90
Polygon -16777216 true false 225 75 210 60 210 45 255 15 255 45 225 60
Polygon -16777216 true false 75 75 90 60 90 45 45 15 45 45 75 60
Circle -16777216 true false 88 118 32
Circle -16777216 true false 178 118 32

wolf 7
false
0
Circle -16777216 true false 183 138 24
Circle -16777216 true false 93 138 24
Polygon -7500403 true true 30 105 30 150 90 195 120 270 120 300 180 300 180 270 210 195 270 150 270 105 210 75 90 75
Polygon -7500403 true true 255 105 285 60 255 0 210 45 195 75
Polygon -7500403 true true 45 105 15 60 45 0 90 45 105 75
Circle -16777216 true false 90 135 30
Circle -16777216 true false 180 135 30
Polygon -16777216 true false 120 300 150 255 180 300

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
