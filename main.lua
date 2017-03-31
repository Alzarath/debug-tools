local DebugTools = RegisterMod("Debug Tools",1)

local ModdedCollectibleType = {
  COLLECTIBLE_BROKEN_DEBUG_TOOLS = Isaac.GetItemIdByName("Broken Debug Tools")
}

local GridEntities = {
  Average = {
    {Type = GridEntityType.GRID_ROCK,           Variant = 0,
     Sprite = "gfx/grid/grid_rock.anm2",        Sound = SoundEffect.SOUND_ROCK_CRUMBLE},
    {Type = GridEntityType.GRID_POOP,           Variant = 0,
     Sprite = "gfx/grid/grid_poop.anm2",        Sound = SoundEffect.SOUND_PLOP}
  },
  Uncommon = {
    {Type = GridEntityType.GRID_ROCK_BOMB,      Variant = 0,
     Sprite = "gfx/grid/grid_rock.anm2",        Sound = SoundEffect.SOUND_ROCK_CRUMBLE},
    {Type = GridEntityType.GRID_SPIKES,         Variant = 0,
    Sprite = "gfx/grid/grid_spikes.anm2",        Sound = SoundEffect.SOUND_METAL_BLOCKBREAK}
  },
  Rare = {
    {Type = GridEntityType.GRID_TNT,            Variant = 0,
    Sprite = "gfx/grid/grid_tnt.anm2",          Sound = SoundEffect.SOUND_PLOP},
    {Type = GridEntityType.GRID_TRAPDOOR,       Variant = 2,
     Sprite = "gfx/grid/door_11_trapdoor.anm2", Sound = SoundEffect.SOUND_DOOR_HEAVY_OPEN}
  }
}

local HeldItem = {
  Sound = 0,
  Type = 0,
  Variant = 0
}
local HoldingItem = false
local GridIndex = 0
local RenderedSprite = Sprite()

function DebugTools:NewGame()
  -- Reset variables
  HeldItem.Sound = 0
  HeldItem.Type = 0
  HeldItem.Variant = 0
  HoldingItem = false
  GridIndex = 0
end
DebugTools:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, DebugTools.NewGame)

function DebugTools:UseBrokenDebugTools(CollectibleType)
  local Player = Isaac.GetPlayer(0)
  local Room = Game():GetRoom()

  if not HoldingItem then
    -- Randomly select what sort of rarity the item should have
    local RandomNumber = math.random(1, 100)

    if RandomNumber <= 60 then
      -- Randomly selects a grid entity of the selected rarity
      RandomNumber = math.random(1, 100)
      if RandomNumber <= 50 then -- Spawn rock
        HeldItem.Sound = GridEntities.Average[1].Sound
        HeldItem.Type = GridEntities.Average[1].Type
        HeldItem.Variant = GridEntities.Average[1].Variant
        RenderedSprite:Load(GridEntities.Average[1].Sprite, true)
        RenderedSprite:Play("normal", true)
      else -- Spawn poop
        HeldItem.Sound = GridEntities.Average[2].Sound
        HeldItem.Type = GridEntities.Average[2].Type
        HeldItem.Variant = GridEntities.Average[2].Variant
        RenderedSprite:Load(GridEntities.Average[2].Sprite, true)
        RenderedSprite:Play("State1", true)
      end
    elseif RandomNumber <= 90 then
      -- Randomly selects a grid entity of the selected rarity
      RandomNumber = math.random(1, 100)
      if RandomNumber <= 50 then -- Spawn rock bomb
        HeldItem.Sound = GridEntities.Uncommon[1].Sound
        HeldItem.Type = GridEntities.Uncommon[1].Type
        HeldItem.Variant = GridEntities.Uncommon[1].Variant
        RenderedSprite:Load(GridEntities.Uncommon[1].Sprite, true)
        RenderedSprite:Play("bombrock", true)
      else -- Spawn spike trap
        HeldItem.Sound = GridEntities.Uncommon[2].Sound
        HeldItem.Type = GridEntities.Uncommon[2].Type
        HeldItem.Variant = GridEntities.Uncommon[2].Variant
        RenderedSprite:Load(GridEntities.Uncommon[2].Sprite, true)
        RenderedSprite:Play("Spikes01", true)
      end
    else
      -- Randomly selects a grid entity of the selected rarity
      RandomNumber = math.random(1, 100)
      if RandomNumber <= 50 then -- Spawn TNT
        HeldItem.Sound = GridEntities.Rare[1].Sound
        HeldItem.Type = GridEntities.Rare[1].Type
        HeldItem.Variant = GridEntities.Rare[1].Variant
        RenderedSprite:Load(GridEntities.Rare[1].Sprite, true)
        RenderedSprite:Play("Idle", true)
      else -- Spawn trap door
        HeldItem.Sound = GridEntities.Rare[2].Sound
        HeldItem.Type = GridEntities.Rare[2].Type
        HeldItem.Variant = GridEntities.Rare[2].Variant
        RenderedSprite:Load(GridEntities.Rare[2].Sprite, true)
        RenderedSprite:Play("Closed", true)
      end
    end
    -- Sets the transparency of the rendered grid entity
    RenderedSprite.Color = Color(0.5, 0.5, 1.0, 0.5, RenderedSprite.Color.RO, RenderedSprite.Color.GO, RenderedSprite.Color.BO)

    -- Inform PostRender that a grid entity should be rendered
    HoldingItem = true
    -- Make the player animate 'using' the item
    Player:AnimateCollectible(CollectibleType, "LiftItem", "PlayerPickup")
  else
    Room:SpawnGridEntity(GridIndex, HeldItem.Type, HeldItem.Variant, Room:GetSpawnSeed(), 0)
    SFXManager():Play(HeldItem.Sound, 1.0, 0, false, 1.0)

    -- Inform PostRender that a a grid entity should no longer be rendered
    HoldingItem = false
    -- Clear the player's animating the item
    Player:AnimateCollectible(CollectibleType, "HideItem", "PlayerPickup")
  end
end
DebugTools:AddCallback(ModCallbacks.MC_USE_ITEM, DebugTools.UseBrokenDebugTools, ModdedCollectibleType.COLLECTIBLE_BROKEN_DEBUG_TOOLS)

function DebugTools:NewRoom()
  local Player = Isaac.GetPlayer(0)

  if HoldingItem then
    HoldingItem = false
    Player:SetActiveCharge(0)
  end
end
DebugTools:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DebugTools.NewRoom)

function DebugTools:PostUpdate()
  local Player = Isaac.GetPlayer(0)

  if HoldingItem and Player:GetActiveCharge() <= 0 then
    Player:SetActiveCharge(2)
  end
end
DebugTools:AddCallback(ModCallbacks.MC_POST_UPDATE, DebugTools.PostUpdate)

function DebugTools:PostRender()
  if HoldingItem then
    local Player = Isaac.GetPlayer(0)
    local Room = Game():GetRoom()
    -- Resets the charge so it can be used to place the item immediately after
    Player:SetActiveCharge(2)
    if Player:GetHeadDirection() == Direction.LEFT then
      DirectionModifier = Vector(-40, 0)
    elseif Player:GetHeadDirection() == Direction.UP then
      DirectionModifier = Vector(0, -40)
    elseif Player:GetHeadDirection() == Direction.RIGHT then
      DirectionModifier = Vector(40, 0)
    elseif Player:GetHeadDirection() == Direction.DOWN then
      DirectionModifier = Vector(0, 40)
    end
    GridIndex = Room:GetClampedGridIndex(Player.Position + DirectionModifier)
    local RenderPosition = Isaac.WorldToRenderPosition(Room:GetGridPosition(GridIndex)) + Room:GetRenderScrollOffset()
    RenderedSprite:Render(RenderPosition, Vector(0,0), Vector(0,0))
  end
end
DebugTools:AddCallback(ModCallbacks.MC_POST_RENDER, DebugTools.PostRender)
