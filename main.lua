local DevTools = RegisterMod("Dev Tools",1)

local ModdedCollectibleType = {
  COLLECTIBLE_BROKEN_DEBUG_TOOLS = Isaac.GetItemIdByName("Broken Debug Tools"),
  COLLECTIBLE_COMPILER = Isaac.GetItemIdByName("Compiler"),
  COLLECTIBLE_MINIMAL_DEBUG_TOOLS = Isaac.GetItemIdByName("Minimal Debug Tools")
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
local DebugRender = false
local UsedCompiler = false
local GridIndex = 0
local RenderedSprite = Sprite()

function DevTools:NewGame()
  -- Reset variables
  HeldItem.Sound = 0
  HeldItem.Type = 0
  HeldItem.Variant = 0
  DebugRender = false
  GridIndex = 0
end
DevTools:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, DevTools.NewGame)

function DevTools:UseBrokenDevTools(CollectibleType)
  local Player = Isaac.GetPlayer(0)
  local Room = Game():GetRoom()

  if not DebugRender then
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
    DebugRender = true
    -- Make the player animate 'using' the item
    Player:AnimateCollectible(CollectibleType, "LiftItem", "PlayerPickup")
  else
    Room:SpawnGridEntity(GridIndex, HeldItem.Type, HeldItem.Variant, Room:GetSpawnSeed(), 0)
    SFXManager():Play(HeldItem.Sound, 1.0, 0, false, 1.0)

    -- Inform PostRender that a a grid entity should no longer be rendered
    DebugRender = false
    -- Clear the player's animating the item
    Player:AnimateCollectible(CollectibleType, "HideItem", "PlayerPickup")
  end
end
DevTools:AddCallback(ModCallbacks.MC_USE_ITEM, DevTools.UseBrokenDevTools, ModdedCollectibleType.COLLECTIBLE_BROKEN_DEBUG_TOOLS)

-- On use, the Compiler fetches each pickup and merges each duplicate into its doubled form
function DevTools:UseCompiler()
  local Player = Isaac.GetPlayer(0)
  local CompilerList = {
    Bomb = {},
    Coin = {},
    HalfHeart = {},
    HalfSoulHeart = {},
    Heart = {},
    Key = {}
  }

  -- Adds every pickup to a table to be compiled later
  for i,entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_PICKUP then
      if entity.Variant == PickupVariant.PICKUP_BOMB and entity.SubType == BombSubType.BOMB_NORMAL then
        CompilerList.Bomb[#CompilerList.Bomb+1] = entity
      elseif entity.Variant == PickupVariant.PICKUP_COIN and entity.SubType == CoinSubType.COIN_PENNY then
        CompilerList.Coin[#CompilerList.Coin+1] = entity
      elseif entity.Variant == PickupVariant.PICKUP_HEART and entity.SubType == HeartSubType.HEART_HALF then
        CompilerList.HalfHeart[#CompilerList.HalfHeart+1] = entity
      elseif entity.Variant == PickupVariant.PICKUP_HEART and entity.SubType == HeartSubType.HEART_HALF_SOUL then
        CompilerList.HalfHeartSoul[#CompilerList.HalfHeartSoul+1] = entity
      elseif entity.Variant == PickupVariant.PICKUP_HEART and entity.SubType == HeartSubType.HEART_FULL then
        CompilerList.Heart[#CompilerList.Heart+1] = entity
      elseif entity.Variant == PickupVariant.PICKUP_KEY and entity.SubType == KeySubType.KEY_NORMAL then
        CompilerList.Key[#CompilerList.Key+1] = entity
      end
    end
  end

  -- Takes every item and 'compiles' two of each into their doublepack or full form(s).
  for i=1,#CompilerList.Bomb,2 do
    if CompilerList.Bomb[i+1] then
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, BombSubType.BOMB_DOUBLEPACK, Vector((CompilerList.Bomb[i].Position.X + CompilerList.Bomb[i+1].Position.X) / 2, (CompilerList.Bomb[i].Position.Y + CompilerList.Bomb[i+1].Position.Y)) / 2, Vector(0, 0), Player)
      CompilerList.Bomb[i]:Remove()
      CompilerList.Bomb[i+1]:Remove()
    end
  end
  for i=1,#CompilerList.Coin,2 do
    if CompilerList.Coin[i+1] then
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_DOUBLEPACK, Vector((CompilerList.Coin[i].Position.X + CompilerList.Coin[i+1].Position.X) / 2, (CompilerList.Coin[i].Position.Y + CompilerList.Coin[i+1].Position.Y) / 2), Vector(0, 0), Player)
      CompilerList.Coin[i]:Remove()
      CompilerList.Coin[i+1]:Remove()
    end
  end
  for i=1,#CompilerList.HalfHeart,2 do
    if CompilerList.HalfHeart[i+1] then
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_NORMAL, Vector((CompilerList.HalfHeart[i].Position.X + CompilerList.HalfHeart[i+1].Position.X) / 2, (CompilerList.HalfHeart[i].Position.Y + CompilerList.HalfHeart[i+1].Position.Y) / 2), Vector(0, 0), Player)
      CompilerList.HalfHeart[i]:Remove()
      CompilerList.HalfHeart[i+1]:Remove()
    end
  end
  for i=1,#CompilerList.HalfSoulHeart,2 do
    if CompilerList.HalfSoulHeart[i+1] then
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_SOUL, Vector((CompilerList.HalfSoulHeart[i].Position.X + CompilerList.HalfSoulHeart[i+1].Position.X) / 2, (CompilerList.HalfSoulHeart[i].Position.Y + CompilerList.HalfSoulHeart[i+1].Position.Y) / 2), Vector(0, 0), Player)
      CompilerList.HalfSoulHeart[i]:Remove()
      CompilerList.HalfSoulHeart[i+1]:Remove()
    end
  end
  for i=1,#CompilerList.Heart,2 do
    if CompilerList.Heart[i+1] then
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_DOUBLEPACK, Vector((CompilerList.Heart[i].Position.X + CompilerList.Heart[i+1].Position.X) / 2, (CompilerList.Heart[i].Position.Y + CompilerList.Heart[i+1].Position.Y) / 2), Vector(0, 0), Player)
      CompilerList.Heart[i]:Remove()
      CompilerList.Heart[i+1]:Remove()
    end
  end
  for i=1,#CompilerList.Key,2 do
    if CompilerList.Key[i+1] then
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_DOUBLEPACK, Vector((CompilerList.Key[i].Position.X + CompilerList.Key[i+1].Position.X) / 2, (CompilerList.Key[i].Position.Y + CompilerList.Key[i+1].Position.Y) / 2), Vector(0, 0), Player)
      CompilerList.Key[i]:Remove()
      CompilerList.Key[i+1]:Remove()
    end
  end

  -- Adds the Magneto item effect to draw items into Isaac
  Player:AddCollectible(CollectibleType.COLLECTIBLE_MAGNETO, 0, false)
  UsedCompiler = true

  return true
end
DevTools:AddCallback(ModCallbacks.MC_USE_ITEM, DevTools.UseCompiler, ModdedCollectibleType.COLLECTIBLE_COMPILER)

function DevTools:NewRoom()
  local Player = Isaac.GetPlayer(0)

  -- Stop the Broken Debug Tools' rendering when entering a new room
  if DebugRender then
    DebugRender = false
  end

  -- Removes the Magneto effect if the Compiler had been used previously
  if UsedCompiler then
    Player:RemoveCollectible(CollectibleType.COLLECTIBLE_MAGNETO)
    UsedCompiler = false
  end
end
DevTools:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DevTools.NewRoom)

function DevTools:PostUpdate()
  local Player = Isaac.GetPlayer(0)

  if DebugRender then
    -- Resets the Broken Debug Tools' charge while it's rendering
    if Player:GetActiveCharge() <= 0 then
      Player:SetActiveCharge(2)
    end

    -- Stops rendering Broken Debug Tools if the player no longer has it
    if not Player:HasCollectible(ModdedCollectibleType.COLLECTIBLE_BROKEN_DEBUG_TOOLS) then
      DebugRender = false
      Player:AnimateCollectible(ModdedCollectibleType.COLLECTIBLE_BROKEN_DEBUG_TOOLS, "HideItem", "PlayerPickup")
    end
  end
end
DevTools:AddCallback(ModCallbacks.MC_POST_UPDATE, DevTools.PostUpdate)

function DevTools:PostRender()
  if DebugRender then
    local Player = Isaac.GetPlayer(0)
    local Room = Game():GetRoom()
    -- Resets the charge so it can be used to place the item immediately after
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
DevTools:AddCallback(ModCallbacks.MC_POST_RENDER, DevTools.PostRender)
