**VOID ORACLE**

*A Roguelike Pachinko Game*

──────────────────────────────

Game Design Specification v1.0

*The Board is the Character*

**1. Concept & Vision**

> *You are an Oracle. The board before you is not a game --- it is a
> living ritual machine, breathing and mutating with every drop.
> Something ancient watches from the void between the pegs.*

Void Oracle is a physics-driven roguelike where the pachinko board
itself is the player\'s character. There is no avatar walking through a
dungeon. Instead, the player builds, mutates, and defends a living board
across a run of encounters, boss fights, and eldritch events --- all
resolved through the chaos of a real physics simulation.

The central tension: pegs grow more powerful as they mutate, but
mutation pulls them toward corruption. A blessed peg and a cursed peg
can chain-react for spectacular rewards --- or catastrophic failure.
Every run, the player must decide how deep into the void they dare to
reach.

**Core Pillars**

-   **Living Architecture:** The Board IS You --- no character sheet, no
    HP bar. Your board\'s state is your life force.

-   **True Physics:** Physics-first --- all outcomes emerge from real
    ball simulation: gravity, momentum, collision.

-   **Haunted Persistence:** Runs are short (30--45 min), but your ghost
    board haunts every future playthrough.

-   **Duality as Design:** Risk/reward flows from the blessed/cursed
    duality baked into every peg choice.

**2. Core Game Loop**

**Run Structure**

Each run is a sequence of nodes on a procedurally-generated map (Slay
the Spire-style path). The player navigates the map choosing which
encounters to face. Nodes react dynamically to the current state of the
board --- a board with many Rot pegs will attract different events than
a board full of Golden pegs.

  -----------------------------------------------------------------------
  **Phase**        **Description**                      **Duration**
  ---------------- ------------------------------------ -----------------
  Drop Phase       Launch 1--5 balls from the top.      \~20 sec
                   Physics resolves. Pockets score      
                   damage, healing, or resources.       

  Result Phase     Outcomes applied. Pegs may mutate,   \~5 sec
                   grow, crack, or bloom from the       
                   drop\'s impact.                      

  Board Phase      Draft new pegs/items. Shop may       \~60 sec
                   appear. Chaos drops can land         
                   mid-board.                           

  Navigation Phase Choose next node on the map.         \~20 sec
                   Branching events may react to board  
                   state.                               
  -----------------------------------------------------------------------

**The Map**

-   Procedural path with 3--5 branching routes per zone, 3 zones per run

-   Node types: Combat, Elite Combat, Event, Shop, Rest (board repair),
    Boss

-   Events read your board --- \"A wandering mycologist stares at your
    Rot pegs\...\" triggers unique choices

-   Path choice is strategic: risky routes toward Elites offer better
    peg rewards

**Victory & Defeat**

-   Victory: Defeat the Final Oracle at the end of Zone 3

-   Defeat: Your board\'s Stability reaches 0 (pegs destroyed faster
    than they can regenerate)

> *On defeat, your board layout is saved as a Ghost Board. In future
> runs, at one random moment, your ghost board will manifest as a
> challenge encounter --- your old sins made physical.*

**3. The Board System**

**Board Anatomy**

The board is a vertical rectangular play field. It has permanent walls,
a launch zone at the top, and a row of scoring pockets at the bottom.
Everything between is populated by pegs the player places and manages.

  -----------------------------------------------------------------------
  **Component**      **Description**
  ------------------ ----------------------------------------------------
  Launch Zone        Top area. Player aims and releases balls. Angle and
                     timing are the primary skill expression.

  Peg Field          The main body. Player-owned pegs occupy this space.
                     Enemies can corrupt or destroy them.

  Void Channels      Gaps deliberately left open. Balls falling through
                     Void Channels collect Void Essence.

  Pockets            Bottom row. Fixed positions. Each pocket has a type
                     (Damage, Heal, Gold, Void, Chaos).

  Board Frame        The walls. Can be upgraded with runes. Certain
                     bosses crack the frame itself.
  -----------------------------------------------------------------------

**Stability**

Stability is the board\'s health. It starts at 100 per run. Enemies
reduce Stability by corrupting, shattering, or eating pegs. Certain peg
synergies passively regenerate Stability. Reaching 0 ends the run.

**4. Peg System**

> *Every peg is alive. It remembers every ball that has touched it. It
> grows. It hungers.*

**Peg States**

All pegs exist on a Blessing--Corruption axis. A peg begins Neutral and
shifts with each ball contact and environmental effect.

  ----------------------------------------------------------------------------
  **State**          **Effect on      **Passive Effect** **Visual**
                     Ball**                              
  ------------------ ---------------- ------------------ ---------------------
  Dormant            Standard         None               Grey, inert
                     deflection                          

  Blessed            Deflects with    Slowly heals       Gold shimmer
                     gold sparkle;    adjacent pegs      
                     adds +1 chain                       
                     bonus                               

  Cursed             Deflects with    Slowly corrupts    Crimson glow
                     red pulse; ball  adjacent pegs      
                     gains Rot charge                    

  Mutant             Wild deflection  Spreads mutation   Green pustules
  (Blessed+Cursed)   angle; triggers  spores             
                     chain reaction                      

  Void-Touched       Ball phases      Generates Void     Dark with stars
                     through,         Essence passively  
                     teleports to                        
                     random pocket                       

  Shattered          No deflection;   Reduces nearby     Cracked, dark
                     ball passes      pegs\' bonus       
                     through                             
  ----------------------------------------------------------------------------

**Peg Tiers**

Pegs are also tiered by their base type, which determines what bonuses
they offer when triggered:

  -------------------------------------------------------------------------
  **Tier**    **Peg Type**    **Primary Bonus**        **Synergy Tag**
  ----------- --------------- ------------------------ --------------------
  Common      Stone Peg       Minimal deflection, +1   Foundation
                              Gold                     

  Common      Bone Peg        +2 damage to current     Death
                              enemy                    

  Uncommon    Fungal Peg      Grows over time; +1      Growth
                              Stability on contact     

  Uncommon    Ember Peg       Ignites adjacent pegs;   Fire
                              chains for +fire dmg     

  Rare        Eye Peg         Watches the ball; grants Void
                              prophetic vision of      
                              pockets                  

  Rare        Heart Peg       Pumps ichor; heals board Blood
                              for 5 Stability on       
                              contact                  

  Legendary   Oracle Peg      Splits ball into 3 on    All
                              contact                  

  Legendary   Void Rift Peg   Ball that touches it     Void
                              drops directly into best 
                              pocket                   
  -------------------------------------------------------------------------

**Mutation & Growth (Biological Mechanic)**

Fungal and Growth-tagged pegs spread. After every 3 drops, each Growth
peg has a chance to spawn an adjacent Sprout peg in an empty slot. Left
unchecked, Growth pegs will tile the board --- powerful, but they decay
into Rot pegs if the board is losing.

> *Rot pegs are cursed Growth pegs. They spread necrosis. They attract
> the Mycologist boss. They can be devastating if synergized correctly,
> or catastrophic if ignored.*

**5. Synergy System**

Synergies activate when 3+ pegs of matching tags are present on the
board simultaneously. They are passive bonuses that scale with the
number of qualifying pegs.

  ------------------------------------------------------------------------------
  **Synergy**    **Required   **Effect at 3   **Effect at 6    **Curse Risk**
                 Tags**       pegs**          pegs**           
  -------------- ------------ --------------- ---------------- -----------------
  Necrotic Bloom Death +      Rot pegs deal 3 All pegs         Rot spreads 2x
                 Growth       damage on       regenerate 1     faster
                              contact         Stability/drop   

  Cursed Flame   Fire +       Burning pegs    Ball moves 20%   Board takes 5
                 Cursed       corrupt         faster, doubles  dmg/drop
                              adjacent on     damage           
                              ignite                           

  Void Choir     Void x3      Every 5th ball  Void Balls open  Void consumes 1
                              becomes a Void  an extra pocket  Blessed peg/run
                              Ball            slot             

  Bleeding       Blood +      Stone pegs heal Board gains      Heart pegs slowly
  Architecture   Foundation   1 Stability on  Regen 2 passive  rot
                              contact                          

  The Profane    Void + Death Eye pegs show   Bone pegs deal   Eye pegs blind
  Eye                         enemy next move double vs        randomly
                                              revealed moves   
  ------------------------------------------------------------------------------

> *Synergies are the heart of build-crafting. A Necrotic Bloom + Cursed
> Flame combo is terrifyingly powerful --- and almost guaranteed to
> corrupt your board within 3 fights. Risk/reward made systemic.*

**6. Enemies & Boss Design**

**Enemy Philosophy**

Enemies do not have a separate combat board. They attack YOUR board
directly --- they are threats to your architecture. Combat is
asymmetric: you are always on the offensive with drops, but enemies are
eating your defenses between drops.

**Enemy Archetypes**

  ------------------------------------------------------------------------
  **Type**      **Board Interaction**       **Defeated By**
  ------------- --------------------------- ------------------------------
  Corruptor     Each turn, turns 1 random   Dealing enough damage via
                Blessed peg Cursed          Damage pockets

  Wrecker       Each turn, physically       High burst damage before board
                shatters 1 peg (removes it) degrades

  Spawner       Drops enemy balls mid-turn  Damage + having Void pockets
                that bounce against your    to eat enemy balls
                pegs                        

  Leech         Steals Gold from your       Fast kill or owning no Gold
                pockets each turn           pockets (adaptive build)

  Mycologist    Accelerates Rot spread;     Purging all Rot pegs before
                converts Growth to Rot      fight, or Void Choir build
  ------------------------------------------------------------------------

**Boss Encounters**

Each zone ends with a Boss. Bosses are multi-phase encounters with
unique board interactions. They are designed to punish
over-specialization and force adaptive play.

**Zone 1 Boss --- The Gardener**

A Corruptor-class entity that obsessively \"prunes\" blessed pegs,
converting them to Dormant, and cultivating Rot in cleared spaces. Phase
2: begins placing enemy-owned Thorn pegs that cannot be removed --- only
navigated around.

> *Counter: Void-Touched pegs make the Gardener\'s pruning ineffective.
> She cannot perceive Void pegs as \"garden.\"*

**Zone 2 Boss --- The Architect of Ruin**

A Wrecker-class entity that systematically destroys the board frame.
Cracks spread from the walls inward. Phase 2: cracks become live Void
Channels --- extremely dangerous but harvestable for massive Void
Essence.

> *Counter: Blood + Foundation synergy passively repairs cracks. Or
> embrace the chaos and pivot to a Void Choir build mid-fight.*

**Zone 3 Boss --- The Final Oracle**

All three archetypes combined. The Final Oracle mirrors your board: it
has a ghost of your own layout reflected and attacking you. Every peg
synergy you\'ve built, she has built too. Phase 3: she reveals she is
the ghost of your best-ever run.

> *The Final Oracle is designed to be impossible to \"hard counter.\"
> She adapts. Victory requires either perfect execution or a build so
> degenerate she cannot mirror it.*

**7. Meta-Progression & Ghost System**

**The Ghost Board**

When a run ends in defeat, the board\'s layout --- every peg type,
state, position, and mutation level --- is saved as a Ghost Board. Ghost
Boards are stored persistently across all runs.

Once per run, at a random point (weighted toward late Zone 2), the
player\'s most recently defeated Ghost Board manifests as a bonus
challenge encounter: \"A Shadow Stirs --- Your Past Returns.\"

  -----------------------------------------------------------------------
  **Ghost Board State**  **Challenge Behavior**
  ---------------------- ------------------------------------------------
  Mostly Blessed pegs    The ghost board heals the enemy it accompanies
                         every drop

  Mostly Cursed pegs     The ghost board damages your board each turn
                         (acts as a Corruptor)

  High Mutation (Mutant  Ghost board fires chaos balls that randomize
  pegs)                  your peg states on hit

  Void-heavy             Ghost board steals one of your ball drops per
                         encounter

  Shattered / degraded   Ghost board is weak --- this is your mercy run
  -----------------------------------------------------------------------

**Permanent Unlocks**

Between runs, players earn Void Shards from boss kills and high-score
drops. Shards unlock:

-   New peg types added to the draft pool

-   New event card sets (reactive to specific board states)

-   New boss variants (The Gardener becomes The Overgarden at unlock
    tier 3)

-   Starter Relics --- one passive item carried into every run of a
    given \"class\"

**Oracle Classes (Runs)**

After clearing the game once, Oracle Classes unlock --- essentially
starting conditions that bias the draft pool and starting board layout.
Examples:

  -----------------------------------------------------------------------
  **Class**        **Starting Board**         **Draft Bias**
  ---------------- -------------------------- ---------------------------
  The Naturalist   4 Fungal Pegs pre-placed   Growth, Blood pegs more
                                              common

  The Doomsayer    2 Bone Pegs, 1 Cursed Peg  Death, Void pegs more
                   pre-placed                 common

  The Architect    Board frame pre-runed (+10 Foundation, Fire pegs more
                   Stability)                 common

  The Void-Walker  1 Void Rift Peg pre-placed Void, Eye pegs more common
                   (center)                   
  -----------------------------------------------------------------------

**8. Board Modification Loop**

**Three Modification Vectors**

Board modification happens through three simultaneous channels, creating
the layered feeling of a living machine:

**1. Drafting (After Each Combat)**

Present 3 randomly drawn pegs or items. Player picks one. The peg is
placed in an empty slot of their choosing. Items are passive effects
(relics) not placed on the board.

**2. Shop Economy (Every \~4 nodes)**

A shop appears offering pegs, relics, and services. Services include:
Bless a peg (+1 tier toward Blessed), Purify a peg (reset to Dormant),
Remove a peg (free a slot), and Transmute (sacrifice 2 pegs to create 1
of the next tier).

**3. Chaos Drops (Random Trigger)**

After any drop, there is a 15% chance of a Chaos Drop: a special ball
falls from an unusual angle with a special property. Chaos Drop types
include:

  -----------------------------------------------------------------------
  **Chaos Drop Type** **Effect**
  ------------------- ---------------------------------------------------
  Blessing Rain       Ball leaves a trail of Blessed dust --- every peg
                      it touches gains Blessed state

  Corruption Wave     Every peg the ball touches shifts one step toward
                      Cursed

  Spore Cloud         Ball explodes on landing, converting 3 random empty
                      slots to Fungal Pegs

  Void Marble         Ball ignores all pegs, goes directly to a random
                      pocket --- double value

  Echo Ball           Replays the exact previous drop path, but with
                      inverted gravity (bounces up first)
  -----------------------------------------------------------------------

**9. Technical & Platform Notes**

**Platform**

Primary target: Browser / Web Game. Built for accessibility and instant
play without installation. Secondary: potential mobile port after
initial release.

**Physics Engine**

Core physics simulation using Matter.js or Rapier (WASM). All ball-peg
collisions are real physics: momentum transfer, angular deflection,
friction coefficients per peg type. No scripted outcomes.

  -----------------------------------------------------------------------
  **Physics Parameter**  **Design Value**
  ---------------------- ------------------------------------------------
  Gravity                Standard Earth gravity (\~9.8m/s²), slightly
                         increased for snappy feel

  Ball Restitution       0.6 default; Void pegs 0.0; Ember pegs 0.9
  (bounciness)           

  Peg Friction           0.1 default; Fungal pegs 0.4 (sticky); Bone pegs
                         0.05 (slick)

  Ball Count per Drop    1 to 5 (scales with ball inventory, earned
                         through drops)

  Board Resolution       600x900px logical, renderer-scalable
  -----------------------------------------------------------------------

**Scope & MVP**

Recommended MVP scope for a first playable prototype:

-   1 zone, 1 boss (The Gardener)

-   10 peg types (3 common, 4 uncommon, 2 rare, 1 legendary)

-   3 synergies

-   Basic ghost board persistence (localStorage/IndexedDB)

-   Map with 8--10 nodes

-   Draft system + basic shop

-   No Oracle Classes in MVP

**10. Aesthetic Direction**

> *The board should feel like it is breathing. Pegs should twitch when a
> ball is near. The void between them should pulse. Every run should
> feel like communing with something that barely tolerates your
> presence.*

**Visual Language**

-   Dark backgrounds --- deep navy-black with faint star-field texture

-   Pegs are organic, not geometric --- they look grown, not
    manufactured

-   Ball trails leave ghostly after-images that fade slowly

-   Corruption spreads like ink in water --- slow, inevitable, beautiful

-   Blessed state: gold veins. Cursed state: crimson cracks. Mutant:
    bioluminescent green pustules.

**Audio Direction**

-   Peg hits: each type has a unique resonant tone. The board is an
    instrument.

-   Blessed pegs: bell-like, clear. Cursed pegs: bass drone. Mutant
    pegs: dissonant chord.

-   Ambience: deep space, low hum, occasional distant whisper

-   Boss music: atonal, building in complexity with each phase

**Key Inspiration**

-   Peglin --- peg-based roguelike, but Void Oracle is darker and more
    physics-authentic

-   Slay the Spire --- map navigation and draft-based progression

-   Caves of Qud --- biological mutation and emergent systems horror

-   Hades --- tight run structure, narrative that reacts to player state

*--- END OF SPECIFICATION ---*

Void Oracle GDD v1.0
