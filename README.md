# B0XazUniversal

Unified Roblox runtime organized as a phased, dependency-injected module graph.
This repository currently contains the **complete layout as documented,
load-bearing scaffolds**: every module defines its responsibility, public API
surface, and boot phase, with bodies erroring as `not implemented (scaffold)`.

## Layout

```text
B0XazUniversal/
├── init.luau                          # Unified Bootstrap & Startup Orchestrator
│
├── Core/                              # Core Infrastructure & Engine Foundations
│   ├── Environment.luau               # Platform API Bridge (executor detect, C-crypto, Input, Network)
│   ├── Disposer.luau                  # Atomic Janitor/Maid lifecycle & resource cleaner
│   ├── EventBus.luau                  # Decoupled type-safe publish/subscribe signal broker
│   ├── StateStore.luau                # Central Reactive Observable State & Tier Capability Gate
│   ├── TaskScheduler.luau             # Prioritized lifecycle pipeline (PreSim, Heartbeat, RenderStepped)
│   └── ServiceContainer.luau          # Central Dependency Injection & Module Registry
│
├── Locomotion/                        # Physics, Movement & Locomotion Subsystems
│   ├── LocomotionService.luau         # Speed, JumpPower, InfJump, CFrame displacement, Fling & TP
│   └── FlightService.luau             # Modern Constraint Flight (LinearVelocity) with Gyro fallbacks
│
├── Combat/                            # Targeting & Weapon Mechanics
│   ├── AimbotService.luau             # Zero-allocation WindMouse/Linear aimer, CFrame & Mouse smoothing
│   ├── TriggerbotService.luau         # O(1) cursor ray/spatial validation & auto-fire executor
│   └── TargetFilter.luau              # Shared validation (Teams, Friends, Whitelist, ForceField, Wallcheck)
│
├── Visuals/                           # Drawing API & Visual Overlays
│   ├── DrawingPool.luau               # Recycled Drawing primitive pool (zero memory fragmentation)
│   ├── ESPController.luau             # Optimized 2D Skeletal & Box ESP, 3D Highlights, dirty-checked text
│   └── OverlayController.luau         # FOV circle, non-allocating Speedlines, FPS & Ping telemetry
│
├── Services/                          # Business Logic & Core Background Services
│   ├── KeyService.luau                # Supabase License Validator, HWID, native C-Crypt persistence
│   ├── ConfigService.luau             # Schema-driven JSON serialization, auto-save engine, profile manager
│   ├── PlayerTracker.luau             # Character lifecycle observers, camera spectate, player filtering
│   └── OptimizerService.luau          # Single-pass texture/material stripper, shadow & particle optimizer
│
├── UI/                                # Modern Responsive UI Engine
│   ├── DOM.luau                       # Fast ASCII byte element constructor, stroke/padding builders
│   ├── ThemeEngine.luau               # Reactive color tokens, WCAG contrast tone generation, preset themes
│   ├── UIEngine.luau                  # Window manager, DraggableComponent controller, Toast notifications
│   ├── Modals/                        # Standalone Overlay Views
│   │   ├── KeyAuthModal.luau          # License key verification dialog
│   │   └── ConfigShareModal.luau      # Two-way JSON import & clipboard export modal
│   ├── Components/                    # Modular Reusable UI Widgets
│   │   ├── Toggle.luau  ├── Slider.luau   ├── Dropdown.luau  ├── ColorPicker.luau
│   │   ├── Keybind.luau ├── Textbox.luau  └── Button.luau
│   └── Tabs/                          # Feature View Mounts (Model-View-Presenter)
│       ├── CombatTab.luau             # Aimbot, FOV, WindMouse, Prediction, Triggerbot controls
│       ├── VisualsTab.luau            # ESP toggles, skeletal settings, chams, lighting controls
│       ├── MovementTab.luau           # Speed, jump, flight parameters, position bookmarks
│       ├── PlayersTab.luau            # Player list, search filter, whitelist, spectate & fling controls
│       ├── UtilityTab.luau            # Performance boosters, hitboxes, spinbot, server hopper
│       ├── GameTab.luau               # Dynamic plugin UI injector & PlaceId metadata
│       └── SettingsTab.luau           # Profile saving/loading, UI scale, theme manager, license info
│
└── Plugins/                           # Polymorphic Game-Specific Extensions
    ├── PluginRegistry.luau            # O(1) PlaceId & UniverseId hash-lookup registry
    ├── PluginManager.luau             # Plugin loader & lifecycle coordinator
    └── PrisonLife/                     # Prison Life Plugin (155615604)
        ├── Manifest.luau              # Weapon spawns, map coordinates, door definitions
        ├── WorldPhase.luau            # Zero-overhead door/fence collision bypass & neon glow
        ├── WeaponMods.luau            # Reactive gun attribute modifier (Spread, FireRate, Auto, Range)
        └── Mechanics.luau             # Non-allocating weapon macro, punch aura & super-punch
```

## Boot order (see `init.luau`)

| Phase | Modules |
|-------|---------|
| 0 Environment | `Core/Environment` |
| 1 Core | `ServiceContainer` → `Disposer` → `EventBus` → `StateStore` → `TaskScheduler` |
| 2 Services | `KeyService` → `ConfigService` → `PlayerTracker` → `OptimizerService` |
| 3 Subsystems | `Locomotion`, `Flight`, `TargetFilter`, `Aimbot`, `Triggerbot`, `DrawingPool`, `ESP`, `Overlay` |
| 4 Interface | `DOM` → `ThemeEngine` → `UIEngine` → Modals → Tabs |
| 5 Plugins | `PluginRegistry` → `PluginManager` (resolves active game plugin) |

## Conventions

- **No direct requires between siblings** — everything resolves through `Core/ServiceContainer`.
- **No direct `RunService` connections in features** — all per-frame work binds to `Core/TaskScheduler`.
- **Every disposable resource is owned by `Core/Disposer`** — connections, instances, threads.
- **Components contract**: `New(parent, props) -> Handle` with `Set/Get/OnChange/Destroy`.
- **Tabs are pure presenters** — they bind `StateStore` paths, never call services.
- **Plugin modules implement** `Init(ctx) -> Start(ctx) -> Stop()`.

## Status

All modules are scaffolds: documented API surfaces that raise
`not implemented (scaffold)` until filled in. Implementation can proceed
module-by-module in boot order.
