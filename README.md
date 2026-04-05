# Kiss the Brainrot - Roblox Game

A Roblox game where players walk up to popular Italian brainrot characters
and kiss them for coins, combos, and glory on the leaderboard.

## Quick Start

### Prerequisites
- [Rojo](https://rojo.space/) 7.x installed
- Roblox Studio

### Setup
```bash
git clone <repo-url>
cd aitest
rojo serve
```

In Roblox Studio, connect to the Rojo server via the Rojo plugin.
All files sync automatically.

### Build (no Rojo live sync)
```bash
rojo build -o game.rbxl
```
Open `game.rbxl` in Studio. The `.gitignore` excludes `.rbxl` files.

## Project Structure

```
default.project.json            Rojo config
src/
  server/
    Init.server.lua             Server bootstrap (service init order)
    Services/
      RemoteService.lua         Creates and manages all RemoteEvents
      DataService.lua           Player data persistence (DataStore)
      CharacterService.lua      Character definitions + kiss tracking
      ModelService.lua          Procedural 3D NPC model builder
      WorldService.lua          Italian-themed world builder
      KissService.lua           Core gameplay loop + validation
      LeaderboardService.lua    OrderedDataStore top 50 tracking
  client/
    Init.client.lua             Client bootstrap (controller wiring)
    Controllers/
      UIController.lua          Full cartoony HUD + popups + panels
      AnimationController.lua   TweenService NPC reaction animations
      KissController.lua        ProximityPrompt input handling
      VFXController.lua         Hearts, sparkles, beams, coin popups
      SoundController.lua       Sound effects with pitch variation
      LeaderboardController.lua Animated leaderboard sidebar
  shared/
    Modules/
      Config.lua                All tunable game constants
      ReactionData.lua          Per-character reaction text pools
      RateLimiter.lua           Sliding window rate limiter
      CharacterAppearance.lua   Visual specs for original 6 characters
      UITheme.lua               Colors, fonts, UI helper functions
      TweenPresets.lua          20+ named TweenInfo presets
    Remotes/
      init.lua                  Centralized RemoteEvent definitions
  tests/
    TestRunner.server.lua       8 test cases
```

## Running Tests

1. Sync the project with Rojo into Studio
2. In Studio, open ServerStorage > Tests > TestRunner
3. Run the game (Play Solo or Play)
4. Check the Output window for test results

Tests run automatically on server start and cover:
- Proximity check (rejects far players)
- Cooldown enforcement
- Combo increment + reset logic
- Super Kiss 10x multiplier math
- DataService default schema merge
- LeaderboardService top-10 limit
- Rate limiter blocking after 20 requests
- CharacterService milestone at every 100 kisses

## How It Works

### Server Init Order
1. **RemoteService** - Creates all 7 RemoteEvents
2. **DataService** - Connects to DataStore
3. **CharacterService** - Registers 14 character definitions
4. **ModelService** - Builds 8 NPC models from BaseParts
5. **WorldService** - Builds Italian plaza, pedestals, lighting
6. **KissService** - Wires RequestKiss handler
7. **LeaderboardService** - Connects to OrderedDataStore

### Player Join Flow
1. DataService loads saved data (or creates defaults)
2. Server fires `CoinsUpdate` with starting coin count
3. Server fires `LeaderboardUpdate` with current top 10
4. Client UI initializes with real data

### Kiss Flow
1. Player walks within 10 studs of NPC
2. ProximityPrompt appears ("Kiss!")
3. Player activates prompt (instant, no hold)
4. Server validates: proximity, cooldown (0.8s), rate limit (20/10s)
5. Server processes: awards coins, checks combo, rolls for Super Kiss (2%)
6. Server fires remotes: KissReaction, ComboUpdate, (SuperKissEvent)
7. Server fires BindableEvent for WorldService heart burst
8. Client plays: NPC animation, UI popup, VFX, sound

## Characters

| Name | Rarity | Unique Feature |
|------|--------|----------------|
| Tralalero Tralala | Common | - |
| Bombardino Coccodrillo | Common | - |
| Tung Tung Tung Sahur | Uncommon | - |
| Brr Brr Patapim | Uncommon | - |
| Cappuccino Assassino | Rare | - |
| Ballerina Cappuccina | Rare | - |
| Pizzicato Pangolino | Common | Scale plates (wedge parts) |
| Bombardino Bufalo | Uncommon | Horns (cylinders) |
| Trombettino Tartaruga | Common | Dome shell |
| Cappellino Capibara | Common | Flat cap + brim |
| Fischietto Fenicottero | Uncommon | Beak (wedge) |
| Urlando Unicorno | Rare | Horn + rainbow mane |
| Saltellino Salamandra | Uncommon | Black spots |
| Magnifico Macarone | Rare | Pasta ridges + crown |

The first 6 characters are defined in CharacterService/ReactionData but don't have
ModelService 3D models (they need workspace models placed manually or via a future
ModelService extension). The last 8 have full procedural models.

## Swapping Placeholder Models for Real Meshes

All NPC models are built from BaseParts in `ModelService.lua`. To replace with
real meshes:

1. Create your mesh model in Blender/Studio
2. Export as `.rbxm` or build in Studio
3. In `ModelService.lua`, replace the `buildCharacterModel()` call for that
   character with loading your mesh:
   ```lua
   local model = game.ServerStorage.CharacterMeshes:FindFirstChild(spec.Name):Clone()
   model.Name = spec.Name
   ```
4. Ensure your model has:
   - A `PrimaryPart` named `HumanoidRootPart` (anchored)
   - A part named `Head` (for BillboardGui + particles)
   - A part named `Body` (for ProximityPrompt)
5. The rest of the game (animations, VFX, UI) references these part
   names and will work automatically

## Configuration

All tunable constants are in `src/shared/Modules/Config.lua`:

| Key | Default | Description |
|-----|---------|-------------|
| KISS_COOLDOWN | 0.8 | Seconds between kisses per player |
| COMBO_WINDOW | 3 | Seconds before combo resets |
| SUPER_KISS_CHANCE | 0.02 | 2% chance per kiss |
| BASE_KISS_COINS | 10 | Coins per normal kiss |
| PROXIMITY_RANGE | 10 | Studs required to kiss |
| LEADERBOARD_UPDATE_INTERVAL | 30 | Seconds between leaderboard refreshes |
| MILESTONE_INTERVAL | 100 | Global kisses before milestone announcement |
| AUTO_SAVE_INTERVAL | 60 | Seconds between auto-saves |
| RATE_LIMIT_MAX | 20 | Max kiss requests per window |
| RATE_LIMIT_WINDOW | 10 | Rate limit window in seconds |
| DEBUG_MODE | false | Enable verbose logging |
