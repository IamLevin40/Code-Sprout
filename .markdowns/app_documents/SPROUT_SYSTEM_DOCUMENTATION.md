# Code Sprout - Sprout & Farming System Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Architecture Overview](#architecture-overview)
3. [Core Data Models](#core-data-models)
4. [Farm Grid System](#farm-grid-system)
5. [Crop Growth System](#crop-growth-system)
6. [Drone System](#drone-system)
7. [Research & Progression System](#research--progression-system)
8. [Inventory Management](#inventory-management)
9. [Persistence & Data Flow](#persistence--data-flow)
10. [UI Layer Architecture](#ui-layer-architecture)
11. [Game Economy](#game-economy)
12. [Workflow Diagrams](#workflow-diagrams)
13. [Key Features](#key-features)

---

## System Overview

**Code Sprout** is an educational gamification platform that teaches programming through farming simulation. The sprout and farming system is the core gameplay mechanic where users write code to control a drone that manages crops on a virtual farm.

### Purpose
- **Educational**: Teach programming concepts through interactive farming tasks
- **Gamified**: Provide progression, rewards, and unlockable content
- **Language-Agnostic**: Support multiple programming languages (C++, C#, Java, JavaScript, Python)

### Core Components
1. **Farm Grid**: Dynamic expandable grid-based farm system (1x1 to 10x10)
2. **Drone Control**: Programmable drone for farm operations (tilling, watering, planting, harvesting)
3. **Crop System**: Time-based growth system with multiple crop types
4. **Research Lab**: Progression system for unlocking features and expansions
5. **Inventory**: Item management for seeds, crops, and resources
6. **XP & Ranking**: Experience-based progression with rank system

---

## Architecture Overview

### System Layers

```
┌─────────────────────────────────────────────────────────────┐
│                       Presentation Layer                      │
│  (FarmPage, Widgets, UI Controls, Visual Components)         │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                      Business Logic Layer                     │
│  (FarmState, ResearchState, Models, Game Mechanics)          │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                        Service Layer                          │
│  (FarmProgressService, FirestoreService, LocalStorage)       │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                         Data Layer                            │
│         (Firebase Firestore, Local Storage, Schemas)         │
└─────────────────────────────────────────────────────────────┘
```

### Design Patterns Used
- **Singleton Pattern**: Schema loaders (`FarmDataSchema`, `ResearchItemsSchema`)
- **State Management**: `ChangeNotifier` pattern (`FarmState`, `ResearchState`)
- **Repository Pattern**: Service layer abstracts data sources
- **Factory Pattern**: Interpreter creation based on language
- **Observer Pattern**: UI listens to state changes

---

## Core Data Models

### 1. PlotState Enum
Represents the state of a farm plot:
```dart
enum PlotState {
  normal,   // Default untilled soil (brown)
  tilled,   // Prepared for planting (dark soil)
  watered,  // Watered and ready (wet soil appearance)
}
```

### 2. CropType Enum
Available crop types with corresponding growth characteristics:
```dart
enum CropType {
  wheat,      // 5s growth, 1 harvest, entry-level
  carrot,     // 7s growth, 2-3 harvest
  potato,     // 5s growth, 1 harvest
  beetroot,   // 12.5s growth, 1 harvest
  radish,     // 5s growth, 1 harvest
  onion,      // 7s growth, 1 harvest
  lettuce,    // 10s growth, 1 harvest
  tomato,     // 15s growth, 4-5 harvest
  garlic,     // 12.5s growth, 2-3 harvest
}
```

### 3. SeedType Enum
Corresponding seeds for each crop:
```dart
enum SeedType {
  wheat_seeds,    // Corresponds to CropType.wheat
  carrot_seeds,   // Corresponds to CropType.carrot
  // ... one seed type per crop type
}
```

### 4. Direction Enum
Cardinal directions for drone movement:
```dart
enum Direction {
  north,  // +Y direction
  south,  // -Y direction
  east,   // +X direction
  west,   // -X direction
}
```

### 5. DroneState Enum
Visual states of the drone:
```dart
enum DroneState {
  normal,      // Idle/moving (blue drone)
  tilling,     // Performing till operation
  watering,    // Performing water operation
  planting,    // Performing plant operation
  harvesting,  // Performing harvest operation
}
```

### 6. PlantedCrop Class
Represents a crop instance on a plot:
```dart
class PlantedCrop {
  final CropType cropType;
  final DateTime plantedAt;        // When seed was placed
  DateTime? growthStartedAt;       // When watering occurred (growth begins)
  
  // Computed Properties:
  - Duration elapsedTime          // Time since growth started
  - bool isGrown                  // Check if fully mature
  - int currentStage              // Current growth stage (1-based)
  - int totalStages               // Total stages for this crop
  - String currentStageImage      // Asset path for current stage
  - double growthProgress         // 0.0 to 1.0
  - Duration remainingTime        // Time until fully grown
}
```

**Key Behavior**:
- Crop is planted but **doesn't grow** until watered (`growthStartedAt` is set)
- Growth stages are time-based and evenly distributed
- Visual representation changes as crop matures

### 7. FarmPlot Class
Represents a single grid cell:
```dart
class FarmPlot {
  final int x;                    // Grid X coordinate
  final int y;                    // Grid Y coordinate
  PlotState state;                // Current plot state
  PlantedCrop? crop;              // Planted crop (if any)
  
  // Permission Checks:
  - bool canTill()                // Can be tilled
  - bool canWater()               // Can be watered
  - bool canPlant()               // Ready for planting
  - bool canHarvest()             // Crop ready to harvest
}
```

**State Transition Rules**:
1. `normal` → `tilled` (via till operation)
2. `tilled` → `watered` (via water operation)
3. `tilled` → `tilled + crop` (via plant operation)
4. `watered` → `normal` (after harvest)

### 8. DronePosition Class
Tracks drone location and state:
```dart
class DronePosition {
  int x, y;                       // Grid position (integer)
  DroneState state;               // Visual state
  double animatedX, animatedY;    // Smooth animation position
}
```

---

## Farm Grid System

### Grid Architecture

**Coordinate System**:
- Origin (0, 0) is at **bottom-left** corner
- X increases to the **right** (East)
- Y increases **upward** (North)
- Display Y is inverted for rendering (top-down view)

**Grid Expansion**:
- Starts at **1x1** (single plot)
- Expands through **research completion**
- Maximum size: **10x10** (100 plots)
- Expansion preserves existing plots and crops

### Dynamic Grid Sizing

```dart
void expandGrid(int newWidth, int newHeight) {
  // Create new grid with increased dimensions
  // Preserve existing plots in their positions
  // Initialize new plots as PlotState.normal
  // Ensure drone stays within bounds
}
```

**Expansion Conditions** (from Research):
```
farm_3x3_farmland  → 3x3 grid (requires 5 wheat)
farm_4x4_farmland  → 4x4 grid (requires 45 wheat, 80 carrot)
farm_5x5_farmland  → 5x5 grid (requires 320 carrot, 120 potato)
...
farm_10x10_farmland → 10x10 grid (ultimate expansion)
```

### Area Operations

Starting from single-plot operations, research unlocks **area operations**:

**Till Area** (`till_grid` conditions):
- 1x1 (default) → single plot
- 3x3 area → 9 plots centered on drone
- 5x5 area → 25 plots centered on drone
- Area effect centered on drone position

**Water Area** (`water_grid` conditions):
- Similar expansion to tilling
- Waters all tillable plots in area

**Plant Area** (`plant_grid` conditions):
- Priority-based planting pattern:
  1. **Center** (drone position)
  2. **Plus pattern** (cardinal directions)
  3. **Cross pattern** (diagonal directions)
  4. Alternates plus/cross in expanding rings
- Consumes 1 seed per planted plot
- Stops when out of seeds or plantable plots

**Harvest Area** (`harvest_grid` conditions):
- Harvests all mature crops in area
- Accumulates items by crop type
- Awards XP for all harvested crops

---

## Crop Growth System

### Growth Mechanics

**Two-Phase Growth Model**:

1. **Planting Phase**:
   - Seed is placed on plot
   - Crop exists but **growth is paused**
   - `growthStartedAt` is `null`

2. **Growing Phase**:
   - Triggered by watering
   - `growthStartedAt` set to current time
   - Real-time growth begins

### Growth Stages

Each crop has **3-6 visual stages** defined in schema:

```json
{
  "wheat": {
    "growth_duration": 5.0,
    "crop_stages": {
      "1": "assets/images/crops/wheat/wheat_stage_1.png",
      "2": "assets/images/crops/wheat/wheat_stage_2.png",
      "3": "assets/images/crops/wheat/wheat_stage_3.png"
    }
  }
}
```

**Stage Calculation**:
```
stageProgress = elapsedTime / growthDuration
currentStage = floor(stageProgress * (stageCount - 1)) + 1
```

Example: Wheat (5 seconds, 3 stages)
- Stage 1: 0.0s - 2.5s
- Stage 2: 2.5s - 5.0s
- Stage 3: 5.0s+ (fully grown)

### Growth Update Timer

```dart
Timer.periodic(Duration(seconds: 1), (_) {
  // Check all plots for crops
  // Trigger UI update if any crops exist
  // Efficient: only notifies when necessary
});
```

### Harvest System

**Harvest Quantities** (randomized):
```
wheat:    1-1  (always 1)
carrot:   2-3  (random between 2 and 3)
tomato:   4-5  (random between 4 and 5)
```

**Harvest Workflow**:
1. Check if crop is fully grown (`isGrown == true`)
2. Check if harvest permission exists (research-based)
3. Generate random quantity from range
4. Add items to user inventory
5. Award XP based on crop type
6. Reset plot to `PlotState.normal`
7. Remove crop from plot

---

## Drone System

### Drone Operations

**Core Functions**:
```
move(Direction)      - Move to adjacent plot
till()               - Prepare plot for planting
water()              - Water plot (start growth)
plant(SeedType)      - Plant seed on prepared plot
harvest()            - Harvest mature crop
```

### Operation Durations (milliseconds)

From `farm_data_schema.txt`:
```json
{
  "drone_work_duration": {
    "general": 200,
    "move(direction)": 400,
    "till()": 300,
    "water()": 500,
    "plant(seedType)": 300,
    "harvest()": 300
  }
}
```

### Movement System

**Grid Movement**:
- Validates bounds before moving
- Updates integer grid position
- Triggers smooth animation

**Smooth Animation** (ease-in-out):
```dart
Future<void> animateDroneMove(Direction direction) {
  // 12 animation steps
  // Ease-in-out curve: t < 0.5 ? 2*t² : -1 + (4-2t)*t
  // Updates animatedX, animatedY for smooth visual transition
  // Duration: moveDuration milliseconds
}
```

### Visual States

Each operation has distinct visual representation:
- **Normal**: Blue drone sprite
- **Tilling**: Drone with tilling animation
- **Watering**: Drone with water particles
- **Planting**: Drone with seed dropping
- **Harvesting**: Drone with harvest basket

---

## Research & Progression System

### Research Categories

#### 1. **Crop Research**
Unlocks new crops for cultivation:

```
crop_wheat (entry-level)
  ↓
crop_carrot (requires 35 wheat)
  ↓
crop_potato (requires 45 wheat, 90 carrot)
  ↓
crop_beetroot (requires 120 carrot, 60 potato)
  ↓
crop_radish → crop_onion → crop_lettuce → crop_tomato → crop_garlic
```

**Crop Research Features**:
- `item_unlocks`: Seeds and crops added to inventory
- `plant_enabled`: Seeds that can be planted
- `harvest_enabled`: Crops that can be harvested
- `item_purchases`: Seeds that can be bought with coins
- `purchase_amount`: Cost per seed purchase
- `experience_gain_points`: XP per harvested item

#### 2. **Farm Research**
Expands farm capabilities:

**Farmland Expansion**:
```
farm_3x3_farmland  → 3x3 grid
farm_4x4_farmland  → 4x4 grid
...
farm_10x10_farmland → 10x10 grid
```

**Operation Area Expansion**:
```
farm_till_3x3      → Till 3x3 area
farm_water_3x3     → Water 3x3 area
farm_plant_3x3     → Plant 3x3 area
farm_harvest_3x3   → Harvest 3x3 area
...
farm_till_5x5, farm_water_5x5, etc.
```

**Conditions Unlocked**:
```json
{
  "conditions_unlocked": {
    "farm_plot_grid": { "x": 3, "y": 3 },
    "till_grid": { "x": 3, "y": 3 },
    "water_grid": { "x": 3, "y": 3 },
    "plant_grid": { "x": 3, "y": 3 },
    "harvest_grid": { "x": 3, "y": 3 }
  }
}
```

#### 3. **Functions Research**
Unlocks programming functions for the drone (handled by interpreter system).

### Research States

**Crop Research States**:
```dart
enum CropResearchState {
  purchase,        // Can buy seeds (research completed)
  toBeResearched,  // Prerequisites met, can research
  locked,          // Prerequisites not met
}
```

**Farm Research States**:
```dart
enum FarmResearchState {
  unlocked,        // Research completed
  toBeResearched,  // Prerequisites met
  locked,          // Prerequisites not met
}
```

### Research Requirements

**Prerequisite System**:
```dart
bool arePredecessorsMet(
  List<String> predecessorIds,
  Set<String> completedResearchIds
) {
  // All predecessors must be completed
  return predecessorIds.every((id) => completedResearchIds.contains(id));
}
```

**Inventory Requirements**:
```dart
bool areRequirementsMet(
  Map<String, int> requirements,
  Map<String, dynamic> userData
) {
  // Check if user has enough items
  // Example: { "wheat": 50, "carrot": 100 }
  for (item, requiredQty in requirements) {
    if (userInventory[item] < requiredQty) return false;
  }
  return true;
}
```

### Research Completion Workflow

1. **Validate Prerequisites**: Check predecessor researches
2. **Validate Requirements**: Check inventory items
3. **Deduct Items**: Remove required items from inventory
4. **Mark Completed**: Add research ID to completed set
5. **Unlock Items**: Mark inventory items as unlocked (for crops)
6. **Apply Conditions**: Expand grid or enable area operations (for farm)
7. **Persist State**: Save to Firestore
8. **Notify UI**: Trigger state listeners

---

## Inventory Management

### Inventory Structure

**Schema-Driven Design**:
```json
{
  "wheat_seeds": {
    "name": "Wheat Seeds",
    "icon": "assets/images/icons/.../wheat_seeds.png",
    "sell_amount": 1,
    "is_locked": false,
    "quantity": 10
  },
  "wheat": {
    "name": "Wheat",
    "icon": "assets/images/icons/.../wheat.png",
    "sell_amount": 5,
    "is_locked": false,
    "quantity": 0
  }
}
```

### Item Categories

1. **Seeds** (plantable):
   - wheat_seeds, carrot_seeds, potato_seeds, etc.
   - Used for planting operations
   - Consumed during `plant()` operations

2. **Crops** (harvestable):
   - wheat, carrot, potato, etc.
   - Gained from harvest operations
   - Used for research requirements
   - Can be sold for coins

### Locked/Unlocked System

- **Initially Locked**: Only wheat_seeds and wheat are unlocked
- **Research Unlocks**: Completing crop research unlocks corresponding items
- **Persistence**: Lock state stored in user data

### Inventory Operations

**Update Quantity**:
```dart
Future<UserData> updateInventoryQuantity({
  required UserData userData,
  required String itemId,
  required int delta,  // Can be positive or negative
}) async {
  // Validate item is unlocked
  if (isLocked) throw Exception('Item is locked');
  
  // Update quantity (minimum 0)
  newQuantity = max(0, currentQuantity + delta);
  
  // Persist to Firestore
  await userData.updateFields({
    'sproutProgress.inventory.$itemId.quantity': newQuantity
  });
  
  return refreshedUserData;
}
```

**Selling Items**:
```dart
// User sells crop for coins
// Quantity decreases, coins increase
coins += (quantity * sellAmount);
```

---

## Persistence & Data Flow

### Data Storage Architecture

**Three-Layer Persistence**:

1. **In-Memory State** (`FarmState`, `ResearchState`)
   - Active game state
   - Immediately reflects user actions
   - Notifies listeners for UI updates

2. **Local Storage** (Shared Preferences)
   - Cache for offline access
   - Fast reads for app startup
   - Reduced Firestore reads

3. **Remote Storage** (Firebase Firestore)
   - Source of truth
   - Cross-device synchronization
   - Persistent across sessions

### Farm Progress Schema

**Firestore Structure**:
```
users/{userId}/farmProgress/grid
{
  "gridInfo": {
    "x": 3,
    "y": 3
  },
  "dronePosition": {
    "x": 1,
    "y": 2
  },
  "plotInfo": {
    "(0,0)": {
      "plotState": "tilled",
      "cropInfo": {}
    },
    "(1,1)": {
      "plotState": "watered",
      "cropInfo": {
        "cropType": "wheat",
        "cropDuration": 3  // seconds elapsed since growth started
      }
    }
  }
}
```

**Key Design Decisions**:
- **Coordinate Keys**: String format "(x,y)" for Firebase compatibility
- **Duration Storage**: Elapsed seconds (not timestamps) for time-travel debugging
- **Capped Durations**: Don't store beyond crop's max growth duration (optimization)

### Research Progress Schema

**Firestore Structure**:
```
users/{userId}/farmProgress/research
{
  "crop_researches": ["crop_wheat", "crop_carrot"],
  "farm_researches": ["farm_3x3_farmland", "farm_till_3x3"],
  "functions_researches": ["func_move", "func_till"]
}
```

### Save Triggers

**Automatic Saves**:
- Farm state changes (plot modified, crop planted, etc.)
- Research completion
- Inventory changes
- Harvesting operations

**Debouncing Strategy**:
- Local updates: Immediate
- Remote updates: Fire-and-forget
- Pending saves retry on connectivity restore

### Load Workflow

**App Initialization**:
```
1. Load from Local Storage (fast)
2. Initialize FarmState with cached data
3. Load from Firestore (background)
4. Reconcile differences (Firestore wins)
5. Update Local Storage cache
```

**Farm Progress Restoration**:
```dart
void applyProgressToFarmState({
  required FarmState farmState,
  required Map<String, dynamic> progress,
}) {
  // 1. Expand grid to saved dimensions
  farmState.expandGrid(savedWidth, savedHeight);
  
  // 2. Restore drone position
  farmState.dronePosition.x = savedX;
  farmState.dronePosition.y = savedY;
  
  // 3. Restore each plot
  for (coord, plotData in plotInfo) {
    plot.state = parsePlotState(plotData['plotState']);
    if (plotData['cropInfo']['cropType']) {
      // Reconstruct growth start time from duration
      growthStartedAt = DateTime.now() - Duration(seconds: cropDuration);
      plot.crop = PlantedCrop(...);
    }
  }
}
```

---

## UI Layer Architecture

### Layer System (Z-Index Order)

**Layer 1: Farm Grid View** (Bottom)
- Infinite scrollable viewport
- Pan and zoom controls
- Plot rendering
- Drone overlay

**Layer 2: Control Layer**
- Top bar (back, title, coins, language)
- Zoom controls
- Farm action buttons
- Bottom controls

**Layer 3: Execution Log Overlay**
- Slide-up animation
- Console output display
- Auto-scroll behavior

**Layer 4: Code Editor Overlay**
- Full-screen slide-up
- Syntax highlighting
- Line execution indicators
- File management

**Layer 5: Research Lab Overlay**
- Full-screen slide-up
- Research tree display
- Progress tracking

**Layer 6: Notifications** (Topmost)
- Success/error messages
- Toast-style notifications

### Interactive Viewport

**Features**:
- **Pan**: Drag to move camera
- **Zoom**: Pinch-to-zoom and mouse wheel
- **Center**: Reset to grid center
- **Bounds**: Infinite scrolling (no limits)

**Scale Limits**:
- Minimum: 0.5x (zoomed out)
- Maximum: 3.0x (zoomed in)
- Default: 1.0x

### Responsive Controls

**Farm Top Controls**:
- Run/Stop button (file selector)
- Execution log toggle
- Clear farm button

**Farm Bottom Controls**:
- Drone Code (opens editor)
- Inventory (opens dialog)
- Research (opens lab)

### Animation System

**Slide Animations**:
```dart
AnimatedPositioned(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  top: showEditor ? 96 : MediaQuery.of(context).size.height,
  // Slides from bottom to visible position
)
```

**Opacity Animations**:
```dart
AnimatedOpacity(
  duration: Duration(milliseconds: 200),
  opacity: showLog ? 1.0 : 0.0,
  // Fades in/out execution log
)
```

**Drone Animation**:
- Smooth ease-in-out movement
- 12 interpolation steps
- State-based sprite changes

---

## Game Economy

### Currency System

**Coins**:
- Earned by selling crops
- Used to purchase seeds
- Stored in user data: `coins.totalAmount`

**Experience Points (XP)**:
- Gained from harvesting crops
- Contributes to rank progression
- Each crop type has XP value

### Selling Mechanics

**Sell Values** (per item):
```
wheat_seeds: 1 coin
wheat: 5 coins
carrot_seeds: 2 coins
carrot: 6 coins
potato_seeds: 4 coins
potato: 14 coins
...
```

**Selling Formula**:
```
coinsGained = quantity × sellAmount
```

### Purchasing Mechanics

**Purchase System**:
- Only available after completing corresponding crop research
- Purchase amount defined in research schema
- Unlimited purchases (if coins available)

**Purchase Formula**:
```
costPerSeed = research.purchaseAmount
totalCost = quantity × costPerSeed
```

### Rank System

**XP-Based Progression**:
```
Each rank requires cumulative XP
Rank 1 → Rank 2: 50 XP
Rank 2 → Rank 3: 150 XP (cumulative)
...
```

**XP Gains**:
```
wheat harvest:    +2 XP per item
carrot harvest:   +4 XP per item
potato harvest:   +7 XP per item
...
tomato harvest:   +21 XP per item
```

---

## Workflow Diagrams

### 1. Crop Lifecycle

```
┌───────────────┐
│  User writes  │
│  drone code   │
└───────┬───────┘
        │
        ▼
┌───────────────┐      ┌─────────────────┐
│  plant()      │─────▶│  Crop placed    │
│  operation    │      │  Growth paused  │
└───────────────┘      └────────┬────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  water()        │
                       │  operation      │
                       └────────┬────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  Growth starts  │
                       │  Timer begins   │
                       └────────┬────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  Crop matures   │
                       │  (stages 1→N)   │
                       └────────┬────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  harvest()      │
                       │  operation      │
                       └────────┬────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │  Items to inventory   │
                    │  XP awarded           │
                    │  Plot reset           │
                    └───────────────────────┘
```

### 2. Research Progression Flow

```
┌──────────────────┐
│  User opens      │
│  Research Lab    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  View research   │
│  tree by type    │
│  (Crop/Farm)     │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────┐
│  Select research item        │
│  Check prerequisites:        │
│  - Predecessor researches    │
│  - Inventory requirements    │
└────────┬─────────────────────┘
         │
         ▼
    ┌────────────┐
    │ All met?   │──No──▶ Show locked state
    └─────┬──────┘
          │Yes
          ▼
┌──────────────────┐
│  User confirms   │
│  research        │
└────────┬─────────┘
         │
         ▼
┌────────────────────────────┐
│  Deduct items from         │
│  inventory                 │
└────────┬───────────────────┘
         │
         ▼
┌────────────────────────────┐
│  Mark research complete    │
│  Save to Firestore         │
└────────┬───────────────────┘
         │
         ▼
┌────────────────────────────┐
│  Apply effects:            │
│  - Unlock inventory items  │
│  - Expand grid             │
│  - Enable area operations  │
└────────┬───────────────────┘
         │
         ▼
┌────────────────────────────┐
│  Show success notification │
│  Update UI                 │
└────────────────────────────┘
```

### 3. Farm State Persistence Flow

```
┌────────────────┐
│  User action   │
│  (till, plant, │
│   harvest)     │
└───────┬────────┘
        │
        ▼
┌────────────────────┐
│  FarmState update  │
│  (in-memory)       │
└───────┬────────────┘
        │
        ▼
┌────────────────────┐
│  notifyListeners() │
└───────┬────────────┘
        │
        ├─────────────────────┐
        │                     │
        ▼                     ▼
┌──────────────┐    ┌─────────────────┐
│  UI updates  │    │  Save trigger   │
└──────────────┘    └────────┬────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  Convert to JSON │
                    │  Firestore format│
                    └────────┬─────────┘
                             │
                  ┌──────────┴──────────┐
                  │                     │
                  ▼                     ▼
         ┌────────────────┐    ┌──────────────┐
         │ Save to Local  │    │ Save to      │
         │ Storage        │    │ Firestore    │
         │ (immediate)    │    │ (background) │
         └────────────────┘    └──────────────┘
```

### 4. Grid Expansion Flow

```
┌──────────────────┐
│  User completes  │
│  farm research   │
└────────┬─────────┘
         │
         ▼
┌──────────────────────┐
│  Check conditions_   │
│  unlocked in schema  │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│  farm_plot_grid      │
│  condition found?    │
└────────┬─────────────┘
         │Yes
         ▼
┌──────────────────────┐
│  Extract new         │
│  dimensions (x, y)   │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│  Call expandGrid()   │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────────────┐
│  Create new grid:            │
│  - Preserve existing plots   │
│  - Initialize new plots      │
│  - Adjust drone position     │
└────────┬─────────────────────┘
         │
         ▼
┌──────────────────────┐
│  notifyListeners()   │
│  UI rebuilds         │
└──────────────────────┘
```

---

## Key Features

### 1. Real-Time Crop Growth
- Background timer updates crop stages every second
- Visual feedback shows growth progress
- No active interaction needed during growth phase

### 2. Research-Gated Progression
- Crops locked until researched
- Grid expansion controlled by research
- Area operations scale with progression

### 3. Priority-Based Planting
- Intelligent seeding pattern for area planting
- Center-first, then expanding rings
- Efficient seed consumption

### 4. Smooth Animations
- Ease-in-out drone movement
- Slide animations for overlays
- Responsive zoom and pan

### 5. Offline Capability
- Local storage caching
- Pending save retry mechanism
- Graceful connectivity handling

### 6. Multi-Language Support
- Language-specific research descriptions
- Code syntax per selected language
- Unified backend for all languages

### 7. Economic Balance
- Crop value scales with growth time
- Research costs increase progressively
- XP gain proportional to difficulty

### 8. Persistent State
- Farm grid saved to Firestore
- Crop growth duration preserved
- Research progress tracked

### 9. Visual Feedback
- Drone state animations
- Plot state visual differences
- Crop stage imagery
- Execution log for debugging

### 10. Modular Architecture
- Separate concerns (models, services, UI)
- Schema-driven configuration
- Testable components

---

## Technical Specifications

### Performance Optimizations

1. **Lazy Loading**: Schemas loaded on-demand
2. **Debounced Saves**: Prevents excessive Firestore writes
3. **Selective Notifications**: Only updates when crops present
4. **Capped Durations**: Storage optimization for mature crops
5. **Viewport Culling**: Renders only visible plots (future optimization)

### Error Handling

1. **Fail-Safe Defaults**: Research permissions default to allow on error
2. **Graceful Degradation**: Shows error screen if loading fails
3. **Retry Mechanism**: Pending saves retry on connectivity restore
4. **User Feedback**: Notifications for all critical operations

### Security Considerations

1. **Server-Side Validation**: Research requirements checked server-side (future)
2. **Inventory Locking**: Prevents modification of locked items
3. **Bounds Checking**: Validates drone movements and operations
4. **Data Sanitization**: All user inputs validated

---

## Future Enhancements

### Potential Features
- **Multiplayer**: Shared farms or trading system
- **Achievements**: Badge system for milestones
- **Seasons**: Time-based events and bonuses
- **Pests**: Challenges requiring defensive code
- **Weather System**: Environmental factors affecting growth
- **Advanced Algorithms**: Pathfinding, optimization challenges
- **Leaderboards**: Competitive farming efficiency rankings

---

## Conclusion

The Code Sprout sprout and farming system is a comprehensive, schema-driven educational platform that gamifies programming learning through farming simulation. Its modular architecture, persistent state management, and progression systems create an engaging learning environment while maintaining code quality and scalability.

**Key Strengths**:
- ✅ Educational focus with real programming languages
- ✅ Engaging progression through research system
- ✅ Robust state management and persistence
- ✅ Smooth animations and responsive UI
- ✅ Scalable architecture for future expansion
- ✅ Comprehensive error handling and offline support

---

**Document Version**: 1.0  
**Last Updated**: November 27, 2025  
**Maintained By**: Code Sprout Development Team
