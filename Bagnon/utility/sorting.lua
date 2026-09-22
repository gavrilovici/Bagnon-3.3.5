--[[
	sorting.lua
		Client side bag sorting algorithm
--]]

--local Search = LibStub('ItemSearch-1.3')
local Sort = Bagnon:NewModule('Sorting', 'AceTimer-3.0')
Bagnon.Sorting = Sort

Sort.Proprieties = {
  --'set',
  'class', 'subclass', --'equip',
  'quality',
  'icon',
  'level', 'name', 'id',
  'count'
}

Sort.init = false

--a runaway guard only: a sort settles in a handful of passes, so this sits far out
--of reach of any real one and exists purely so a stuck slot cannot spin forever
Sort.MAX_PASSES = 100

function Sort:Init()
  Sort.init = true
  Sort.Classes = {}
  for i, itemClass in ipairs({GetAuctionItemClasses()}) do
    local subClasses = {}
    for j, subClass in ipairs({GetAuctionItemSubClasses(i)}) do
      subClasses[subClass] = j
    end
    Sort.Classes[itemClass] = {index = i, subClasses = subClasses}
  end
end


--[[ Process ]]--

function Sort:Start(itemFrame)
  --a sort already in flight would otherwise keep running against the old frame
  self:CancelAllTimers()

  self.itemFrame = itemFrame
  self.passes = 0

  --the frame has to be set first, since CanRun asks it whether it is sortable
  if not self:CanRun() then
    self:Stop()
    return
  end

  if not self.init then
    self:Init()
  end

  --self:SendMessage('SORTING_STATUS', itemFrame)
  self:Run()
end

function Sort:Run()
  if self:CanRun() then
    ClearCursor()
    self:Iterate()
  else
    self:Stop()
  end
end

function Sort:Iterate()
  local spaces = self:GetSpaces()
  local families = self:GetFamilies(spaces)
  local updateRequired = false;
  local stackable = function(item)
    return (item.count or 1) < (item.stack or 1)
  end

  for k, target in pairs(spaces) do
    local item = target.item
    if item.id and stackable(item) then
      for j = k+1, #spaces do
        local from = spaces[j]
        local other = from.item

        if item.id == other.id and stackable(other) then
          updateRequired = self:Move(from, target) or updateRequired
        end
      end
    end
  end

  local moveDistance = function(item, goal)
    return math.abs(item.space.index - goal.index)
  end

  for _, family in ipairs(families) do
    local order, spaces = self:GetOrder(spaces, family)
    local n = min(#order, #spaces)

    for index = 1, n do
      local goal = spaces[index]
      local item = order[index]
      item.sorted = true

      if item.space ~= goal then
        local distance = moveDistance(item, goal)

        for j = index, n do
          local other = order[j]
          if other.id == item.id and other.count == item.count then
            local d = moveDistance(other, spaces[j])
            if d > distance then
              item = other
              distance = d
            end
          end
        end

        updateRequired = self:Move(item.space, goal) or updateRequired
      end
    end
  end

  self.passes = self.passes + 1

  if updateRequired and self.passes < self.MAX_PASSES then
    self:ScheduleTimer("Run", self.itemFrame:GetSortDelay())
  else
    self:Stop()
  end
end

function Sort:Stop()
  self.itemFrame:SendMessage('SORTING_STATUS')
end


--[[ Data Structures ]]--

function Sort:GetSpaces()
  local spaces = {}
  local itemFrame = self.itemFrame
  local reversed = itemFrame:IsSortOrderReversed()

  --spaces are filled in the order they are collected here, so walking bags and
  --slots backwards makes a sort start at the last available bag and work forward
  for _, bag in itemFrame:GetSortableBags() do
    local family = itemFrame:GetSortBagFamily(bag)
    local bagSize = itemFrame:GetSortBagSize(bag)
    local first, last, step = 1, bagSize, 1
    if reversed then
      first, last, step = bagSize, 1, -1
    end

    for slot = first, last, step do
      local texture, count, locked, quality, link = itemFrame:GetSortSlotInfo(bag, slot)
      local item = {}
      local space = {index = #spaces, bag = bag, slot = slot, family = family, item = item}
      tinsert(spaces, space)
      item.space = space
      if link then
        local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount = GetItemInfo(link)
        item.class = Sort.Classes[itemType] and Sort.Classes[itemType].index or 0
        item.subclass = Sort.Classes[itemType] and Sort.Classes[itemType].subClasses[itemSubType] or 0
        --GetItemInfo comes back empty for items the client has not cached yet, and
        --the sort rule compares these directly, so none of them may be left nil
        item.stack = itemStackCount or 1
        item.count = count or 1
        item.id =  tonumber(link:match("item:(%d+)")) or 0
        item.locked = locked
        --containers that do not report quality themselves fall back to the item's own rarity
        item.quality = quality or itemRarity or 0
        item.icon = texture or ''
        item.level = itemLevel or 0
        item.name = itemName or ''
      end
    end
  end
  --[[
  for _, bag in pairs(self.bags) do
    local link, count, texture = bag:GetBagInfo()
    for slot = 1, (container.count or 0) do
      local item = Bagnon.Bag:GetItemInfo(self.owner, bag, slot)
      tinsert(spaces, {index = #spaces, bag = bag, slot = slot, family = container.family, item = item})

      item.class = item.id and Search:IsQuestItem(item.id) and Enum.ItemClass.Questitem or item.class
      item.space = spaces[#spaces]

      --item.set = item.id and Search:BelongsToSet(item.id) and 0 or 1
    end
  end
  ]]

  return spaces
end

function Sort:GetFamilies(spaces)
  local set = {}
  for _, space in ipairs(spaces) do
    set[space.family] = true
  end

  local list = {}
  for family in pairs(set) do
    tinsert(list, family)
  end

  sort(list, function(a, b) return a > b end)
  return list
end

function Sort:GetOrder(spaces, family)
  local order, slots = {}, {}

  for _, space in ipairs(spaces) do
    local item = space.item
    if item.id and not item.sorted and self:FitsIn(item.id, family) then
      tinsert(order, space.item)
    end

    if space.family == family then
      tinsert(slots, space)
    end
  end

  sort(order, self.Rule)
  return order, slots
end

function Sort:CanRun()
  if InCombatLockdown() or UnitIsDead('player') then
    return false
  end

  local itemFrame = self.itemFrame
  return (itemFrame and itemFrame:CanSortItems()) and true or false
end

function Sort:FitsIn(id, family)
  if family == 9 then
    return GetItemFamily(id) == 256
  end

  return family == 0 or (bit.band(GetItemFamily(id), family) > 0 and select(9, GetItemInfo(id)) ~= 'INVTYPE_BAG')
end

function Sort.Rule(a, b)
  for _,prop in pairs(Sort.Proprieties) do
    if a[prop] ~= b[prop] then
      return a[prop] > b[prop]
    end
  end

  if a.space.family ~= b.space.family then
    return a.space.family > b.space.family
  end
  return a.space.index < b.space.index
end

function Sort:Move(from, to)
  if from.locked or to.locked or (to.item.id and not self:FitsIn(to.item.id, from.family)) then
    return
  end

  local itemFrame = self.itemFrame

  ClearCursor()
  itemFrame:PickupSortItem(from.bag, from.slot)
  itemFrame:PickupSortItem(to.bag, to.slot)
  ClearCursor()

  from.locked = true
  to.locked = true
  return true
end
