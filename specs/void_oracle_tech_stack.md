**VOID ORACLE**

*Technical Stack Specification*

──────────────────────────────

Godot 4 \| GDScript \| 6--12 Month Roadmap

**1. Platform Decision**

> *Verdict: Godot 4 with GDScript, targeting Web (itch.io) first, then
> Steam, then Mobile. Single codebase exports to all three.*

The key driver from the GDD is that Void Oracle\'s physics simulation is
the game. Every peg has its own restitution and friction coefficient.
Balls need real momentum transfer and angular deflection. Corruption
needs to spread organically. This is not logic that belongs in a browser
JS app --- it belongs in a purpose-built game engine with a native
physics pipeline.

Godot 4\'s physics engine (backed by Jolt Physics in 4.3+) handles
exactly this simulation model. More importantly, Godot exports a single
project to HTML5/WebGL, Windows, macOS, iOS, and Android --- which maps
perfectly to the \"all of the above eventually\" distribution goal.

  -----------------------------------------------------------------------------
  **Factor**       **Godot 4**       **Web                  **Unity**
                                     (Phaser/Matter.js)**   
  ---------------- ----------------- ---------------------- -------------------
  Physics quality  Jolt-backed,      Matter.js --- adequate Box2D ---
                   native 2D physics but JS-limited         excellent, but
                                                            overkill cost

  All-platform     Native: Web,      Web only; mobile       Yes, but royalty
  export           Desktop, Mobile   requires wrapper       risk on revenue

  GDScript AI      Excellent ---     N/A                    C# --- also good
  assistance       vast training                            
                   data                                     

  Shader/VFX       Full GLSL         Canvas2D --- limited   Full ShaderLab ---
  pipeline         shaders, GPU                             complex
                   particles                                

  Save system      Built-in          localStorage ---       PlayerPrefs or
                   FileAccess + JSON fragile                custom

  Time to first    Fast --- scene    Fastest --- just       Slower --- heavy
  prototype        system is         HTML/JS                editor
                   intuitive                                

  Licensing cost   Free, open source Free                   Free tier with 5%
                   (MIT)                                    royalty \>\$200k
  -----------------------------------------------------------------------------

**2. Core Technology Stack**

  -----------------------------------------------------------------------
  **Layer**     **Technology**      **Version**   **Purpose**
  ------------- ------------------- ------------- -----------------------
  Engine        Godot               4.3+          Core game engine,
                                                  physics, rendering,
                                                  input, export

  Language      GDScript            2.0 (Godot 4) All game logic,
                                                  systems, and UI
                                                  scripting

  Physics       Jolt Physics (via   4.3+          Ball simulation, peg
                Godot)              integrated    collisions,
                                                  restitution/friction

  Rendering     Godot Compatibility 4.x           WebGL2-compatible,
                Renderer                          works on web +
                                                  desktop + mobile

  Shaders       Godot Shading       4.x           Corruption spread, glow
                Language                          effects, peg mutation
                (GLSL-like)                       visuals

  Particles     GPUParticles2D      4.x           Ball trails, corruption
                                                  ink, blessed sparkles,
                                                  rot spores

  Audio         Godot               4.x           Per-peg tone system,
                AudioStreamPlayer                 procedural ambient
                                                  layering

  Save/Load     FileAccess + JSON   4.x           Ghost Board
                                                  persistence, run state,
                                                  meta-progression

  Version       Git + GitHub        Latest        Source control; .import
  Control                                         files handled via
                                                  .gitignore
  -----------------------------------------------------------------------

**3. Physics Implementation**

> *The physics sim IS the game. Every parameter in this section maps
> directly to a GDD mechanic. Tune these numbers obsessively.*

**Ball Physics (RigidBody2D)**

Each ball is a RigidBody2D node with a CircleShape2D collider. Godot\'s
physics engine handles all collision detection and response natively.

  --------------------------------------------------------------------------------------------
  **Parameter**   **Godot Property**                        **Default     **Notes**
                                                            Value**       
  --------------- ----------------------------------------- ------------- --------------------
  Gravity scale   RigidBody2D.gravity_scale                 1.4           Slightly boosted
                                                                          from 1.0 for
                                                                          snappier drops

  Ball mass       RigidBody2D.mass                          1.0 kg        Consistent across
                                                                          all ball types

  Linear damping  RigidBody2D.linear_damp                   0.05          Minimal air
                                                                          resistance --- keep
                                                                          it chaotic

  Max velocity    ProjectSettings physics/2d/max_velocity   4000 px/s     Cap to prevent
                                                                          tunneling through
                                                                          thin pegs

  Physics ticks   ProjectSettings                           120           Double default (60)
                  physics/common/physics_ticks_per_second                 for precise
                                                                          collision detection

  CCD mode        RigidBody2D.continuous_cd                 Cast Ray      Prevents fast ball
                                                                          tunneling through
                                                                          pegs
  --------------------------------------------------------------------------------------------

**Peg Physics (StaticBody2D)**

Each peg is a StaticBody2D with a CircleShape2D. The PhysicsMaterial
resource on each peg type defines its unique feel:

  ---------------------------------------------------------------------------
  **Peg Type**     **Restitution   **Friction**   **Behavioral Notes**
                   (bounce)**                     
  ---------------- --------------- -------------- ---------------------------
  Stone Peg        0.6             0.1            Baseline --- predictable,
  (default)                                       satisfying thunk

  Bone Peg         0.5             0.05           Slick --- ball slides off
                                                  at sharp angles

  Fungal Peg       0.4             0.45           Sticky --- ball clings,
                                                  loses momentum, drops steep

  Ember Peg        0.9             0.05           Hyper-elastic --- ball
                                                  rockets off unpredictably

  Eye Peg          0.6             0.1            Standard physics; special
                                                  behavior is scripted

  Heart Peg        0.7             0.15           Soft bounce --- feels
                                                  organic, slightly
                                                  unpredictable

  Void Rift Peg    0.0             0.0            Ball disappears on contact
                                                  (teleport scripted)

  Oracle Peg       0.6             0.1            Standard physics; ball
                                                  split is scripted on
                                                  contact
  ---------------------------------------------------------------------------

**Collision Signal Architecture**

The entire game\'s event system is driven by physics collision signals.
Every peg listens for ball contact:

> \# Base peg script --- all peg types extend this
>
> func \_on_body_entered(body: RigidBody2D) -\> void:
>
> if body.is_in_group(\"ball\"):
>
> EventBus.emit_signal(\"peg_hit\", self, body)
>
> \_on_peg_hit(body) \# Override in child classes
>
> \_try_mutate() \# Check mutation thresholds
>
> \_update_visual() \# Shader param update

An EventBus (global AutoLoad singleton) broadcasts peg_hit events to the
synergy checker, enemy system, mutation engine, and audio manager
simultaneously --- decoupled, clean, and easy to extend.

**4. Shaders & Visual Effects**

> *The GDD calls for corruption spreading \"like ink in water.\" This is
> a shader problem. The entire aesthetic lives here.*

**Critical Shaders to Build**

**Shader 1 --- Peg State Shader (Most Important)**

A single CanvasItem shader on every peg that accepts a float uniform
corruption_level (0.0 = pure blessed, 1.0 = fully cursed). The shader
interpolates between gold veining, neutral stone, crimson cracking, and
bioluminescent green pustules based on this value. Mutation state is
just corruption_level = 0.5 with a secondary uniform.

> // Peg state shader (simplified)
>
> uniform float corruption_level : hint_range(0.0, 1.0) = 0.0;
>
> uniform float mutation_pulse = 0.0; // animated sine wave
>
> // Lerp between blessed_color -\> neutral -\> cursed_color in
> fragment()

**Shader 2 --- Corruption Spread (Board-Level)**

A full-board ShaderMaterial on the background layer. Uses a Texture2D
\"corruption map\" --- a low-res (64x64) image updated by GDScript each
time a peg becomes cursed. The shader blurs and bleeds the corruption
texture to create the ink-in-water spread. GDScript updates the texture;
the shader makes it beautiful.

**Shader 3 --- Ball Trail**

Line2D following the ball\'s last N positions, with a custom shader that
fades opacity and shifts color from white → ghost blue toward the tail.
GPUParticles2D emitting from ball position for sparkle/rot particles
depending on ball state.

**VFX Node Structure**

  ------------------------------------------------------------------------
  **Effect**       **Godot Node**     **Implementation Notes**
  ---------------- ------------------ ------------------------------------
  Ball ghost trail Line2D + shader    Store last 20 positions in array;
                                      update each physics frame

  Peg hit burst    GPUParticles2D     One-shot particle burst on peg_hit
                   (per peg)          signal; color from peg state

  Corruption ink   Background +       Update 64x64 Image, set as shader
  spread           ShaderMaterial     uniform Texture2D

  Blessed sparkle  CPUParticles2D     Looping slow emission on Blessed
  aura             (lightweight)      pegs; pause when Dormant

  Rot spore spread GPUParticles2D     Emits from Fungal/Rot pegs;
                   (board-level)      triggered by Necrotic Bloom synergy

  Screen           FullScreen         Wobble/ripple uniform animated
  distortion       ShaderMaterial     during boss phase transitions
  (boss)                              
  ------------------------------------------------------------------------

**5. Save System & Ghost Boards**

> *Ghost Boards are the game\'s most emotionally resonant system. The
> save architecture needs to capture complete board state with zero data
> loss.*

**What Gets Saved**

A Ghost Board is a snapshot of the complete board state at the moment of
death. It must capture everything needed to recreate the board as a
challenge encounter in a future run.

  --------------------------------------------------------------------------------
  **Data**           **Type**              **Example Value**
  ------------------ --------------------- ---------------------------------------
  Board version      String                \"1.0\" --- for future migration

  Timestamp          int (Unix)            1735689600

  Run seed           int                   847293 --- for recreating procedural
                                           elements

  Zone reached       int                   2

  Peg layout         Array\[Dictionary\]   \[{pos: Vector2, type: \"fungal\",
                                           state: \"mutant\", level: 3}, \...\]

  Active synergies   Array\[String\]       \[\"necrotic_bloom\", \"void_choir\"\]

  Stability at death float                 12.5

  Total drops taken  int                   47

  Relics held        Array\[String\]       \[\"rot_crown\", \"void_marble\"\]
  --------------------------------------------------------------------------------

**Save File Structure**

All persistence uses Godot\'s FileAccess with JSON serialization. Stored
in user:// (platform-appropriate AppData/Documents location, works on
web via IndexedDB):

> user://
>
> void_oracle/
>
> meta.json \# Unlocks, void shards, oracle classes
>
> ghost_boards/
>
> ghost_001.json \# Most recent death
>
> ghost_002.json \# Second most recent
>
> \... \# Keep last 10 ghosts max
>
> settings.json \# Audio, display prefs

**GhostBoardManager (AutoLoad Singleton)**

A global singleton handles all save/load operations. Key methods:

> \# AutoLoad: GhostBoardManager
>
> func save_ghost(board_state: Dictionary) -\> void
>
> func load_ghost(index: int) -\> Dictionary
>
> func get_active_ghost() -\> Dictionary \# For current run encounter
>
> func rotate_ghosts() -\> void \# Shift indices, cull oldest
>
> *Web export note: Godot\'s user:// path maps to IndexedDB in HTML5
> builds automatically. Ghost Board persistence works on web out of the
> box --- no extra code needed.*

**6. Procedural Board Generation**

**What Gets Procedurally Generated**

Three distinct systems use procedural generation: the run map, the peg
draft pool, and the initial board layout per run. Each uses a seeded
random number generator so runs can be replicated by seed.

**Run Map Generation**

The map is a directed acyclic graph (DAG) with 3 zones of 8--10 nodes
each, generated fresh each run:

> \# MapGenerator.gd
>
> func generate_map(seed: int) -\> MapGraph:
>
> var rng = RandomNumberGenerator.new()
>
> rng.seed = seed
>
> \# Generate 3 columns per zone, 2-4 nodes each
>
> \# Connect with 1-3 branching paths
>
> \# Guarantee: 1 shop per zone, 1 rest per zone, boss at end
>
> \# Weight elite/event nodes by player board state

The key innovation: node type weighting reads the current board state. A
board with 4+ Rot pegs increases the chance of a Mycologist event by
40%. A board with Void Choir active increases Void node frequency. The
map reacts to you.

**Board State Seeding**

  ------------------------------------------------------------------------
  **System**         **Seeding Strategy**     **Reset Timing**
  ------------------ ------------------------ ----------------------------
  Run map layout     New seed per run (stored Each new run
                     in run state)            

  Peg draft choices  Derived from run seed +  Each encounter
                     encounter index          

  Shop inventory     Derived from run seed +  Each shop visit
                     shop visit count         

  Chaos drop type    True random (no seed)    Each chaos drop event

  Enemy attack       True random (no seed)    Each enemy turn
  targeting                                   

  Ghost Board        Derived from run seed    Locked at run start
  encounter slot                              
  ------------------------------------------------------------------------

**Peg Placement Algorithm**

The board is a grid of valid peg slots (approximately 8 columns x 12
rows = 96 slots, staggered like a real pachinko board). On run start,
15--20 slots are pre-filled based on the Oracle Class. The draft then
fills slots the player chooses.

Constraint rules for procedural initial placement: no two Ember pegs
adjacent (chain fire risk at start), at least 2 empty columns for Void
Channels, Heart pegs prefer center columns. These constraints prevent
trivially broken or trivially weak starting states.

**7. Godot Project Structure**

**Scene Tree Architecture**

> res://
>
> scenes/
>
> game/
>
> Board.tscn \# Main game scene --- physics world
>
> Ball.tscn \# RigidBody2D ball prefab
>
> pegs/
>
> BasePeg.tscn \# Extended by all peg types
>
> StonePeg.tscn
>
> FungalPeg.tscn
>
> \# \... one scene per peg type
>
> BoardUI.tscn \# HUD overlay (stability, gold, etc)
>
> map/
>
> RunMap.tscn \# Slay the Spire-style node map
>
> MapNode.tscn \# Individual map node
>
> menus/
>
> MainMenu.tscn
>
> RunSummary.tscn \# Death screen / ghost board preview
>
> scripts/
>
> autoloads/
>
> EventBus.gd \# Global signal hub
>
> GhostBoardManager.gd
>
> RunState.gd \# Current run data singleton
>
> SynergyChecker.gd \# Watches board, fires synergy signals
>
> pegs/
>
> BasePeg.gd
>
> FungalPeg.gd \# Extends BasePeg
>
> \# \...
>
> systems/
>
> MutationEngine.gd
>
> EnemyAI.gd
>
> DraftSystem.gd
>
> MapGenerator.gd
>
> shaders/
>
> peg_state.gdshader
>
> corruption_spread.gdshader
>
> ball_trail.gdshader
>
> assets/
>
> audio/ textures/ fonts/

**AutoLoad Singletons (Global Systems)**

  ------------------------------------------------------------------------
  **Singleton**       **Responsibility**
  ------------------- ----------------------------------------------------
  EventBus            All cross-system signals. Physics → game logic
                      decoupling. Every major event passes through here.

  RunState            Current run data: board layout, gold, stability,
                      active synergies, map progress, seed.

  GhostBoardManager   Serialize/deserialize ghost boards. Load ghost for
                      current run encounter.

  SynergyChecker      Subscribes to EventBus peg_hit. Counts tags. Fires
                      synergy_activated / synergy_broken signals.

  AudioManager        Per-peg tone system. Subscribes to peg_hit, plays
                      tone based on peg type + state.

  MutationEngine      Tracks hit counts per peg. Manages blessed/cursed
                      axis. Triggers state transitions.
  ------------------------------------------------------------------------

**8. Export & Platform Targets**

  -----------------------------------------------------------------------------------
  **Platform**   **Godot Export  **Distribution**   **Timeline**   **Key
                 Template**                                        Considerations**
  -------------- --------------- ------------------ -------------- ------------------
  Web (HTML5)    Web export      itch.io            MVP launch     Use Compatibility
                 template                                          renderer; test on
                                                                   mobile browsers
                                                                   too

  Windows        Windows export  Steam / itch.io    After MVP      Ship as ZIP; Steam
                 template                                          via Steamworks SDK
                                                                   plugin

  macOS          macOS export    Steam / itch.io    After MVP      Requires Apple
                 template                                          notarization for
                                                                   Gatekeeper; budget
                                                                   time for this

  Android        Android export  Google Play        Post-1.0       Needs touch input
                 template                                          layer; portrait
                                                                   orientation lock

  iOS            iOS export      App Store          Post-1.0       Requires Mac +
                 template                                          Xcode for build;
                                                                   Apple dev license
                                                                   (\$99/yr)
  -----------------------------------------------------------------------------------

> *Recommended renderer: Compatibility (not Forward+). Compatibility
> targets WebGL2, which is the lowest common denominator --- it works on
> web, mobile, and desktop equally. Forward+ has better visuals but
> breaks web/mobile export.*

**9. Development Tooling**

**Required Tools**

-   **Godot 4.3+** --- Download from godotengine.org. No installation
    needed --- unzip and run.

-   **Git + GitHub** --- Version control. Add .gitignore for Godot
    (godot.gitignore template on GitHub).

-   **VS Code + godot-tools extension** --- Much better GDScript editing
    than Godot\'s built-in editor for large projects.

-   **Claude Code** --- AI pair programming --- works excellently with
    GDScript given the large training corpus.

**Recommended Addons (via Godot Asset Library)**

  -----------------------------------------------------------------------
  **Addon**        **Purpose**                        **Asset Library**
  ---------------- ---------------------------------- -------------------
  Phantom Camera   Smooth camera system for board     Yes
                   pan/zoom effects                   

  GodotSteam       Steam achievements, leaderboards   Yes
                   (add post-MVP)                     

  Dialogic         Branching event/story text if      Yes
                   needed for oracle events           

  Betsy (Behavior  Enemy AI behavior trees ---        Yes
  Trees)           cleaner than nested if/else        
  -----------------------------------------------------------------------

**Debug & Tuning Tools to Build Early**

-   **Physics Debug Overlay** --- Toggle that shows all collider shapes,
    ball velocity vectors, and peg hit counts. Essential for tuning.

-   **Peg State Inspector** --- Click any peg in-game to see its
    corruption_level, hit_count, active synergy tags. Saves hours.

-   **Drop Replay** --- Record and replay the last drop exactly.
    Critical for debugging edge cases in physics.

-   **Synergy Console** --- Overlay showing all active synergies and
    their current peg counts. Visible during dev builds.

**10. Development Milestones**

  -----------------------------------------------------------------------
  **Milestone**    **Deliverable**                   **Est. Duration**
  ---------------- --------------------------------- --------------------
  M1 --- Physics   Board with pegs, real ball        2--3 weeks
  Sandbox          physics, all peg                  
                   friction/restitution values       
                   tuned. No game logic.             

  M2 --- Core      EventBus, MutationEngine,         3--4 weeks
  Systems          SynergyChecker wired up. Pegs     
                   change state on hit. Synergies    
                   fire.                             

  M3 --- Single    One enemy type (Corruptor). Drop  2--3 weeks
  Encounter        phase → result phase → board      
                   phase loop working. No map yet.   

  M4 --- Ghost     Death saves a ghost. Ghost can be 2 weeks
  Board MVP        loaded and manifests as a board   
                   encounter. Save/load stable.      

  M5 --- Map & Run Procedural map. 3 enemy types.    4--5 weeks
  Loop             Shop. Draft system. Full run from 
                   start to Zone 1 boss.             

  M6 --- Full Game All 3 zones, all 3 bosses, all    6--8 weeks
                   peg types, all synergies.         
                   Meta-progression unlocks.         

  M7 --- Polish &  All shaders complete. Audio       3--4 weeks
  Web Export       system. Web export tested.        
                   itch.io page live.                

  M8 --- Steam     Windows/Mac builds. Steam page.   3--4 weeks
                   Achievements via GodotSteam.      
                   Steamworks integration.           
  -----------------------------------------------------------------------

> *Total estimated timeline: 25--37 weeks (6--9 months). This fits the
> \"build it right\" 6--12 month window with room for iteration,
> playtesting, and the inevitable scope surprises.*

*--- END OF TECH SPEC ---*

Void Oracle Tech Stack v1.0 \| Godot 4 + GDScript
