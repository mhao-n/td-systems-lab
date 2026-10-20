local function newRng(seed)
  local state = seed % 2147483647
  local rng = {}
  function rng:number(low, high)
    state = (state * 48271) % 2147483647
    return low + (high - low) * (state / 2147483647)
  end
  function rng:integer(low, high) return math.floor(self:number(low, high + 1)) end
  return rng
end

local rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }
local function rarityPower(rarity)
  for index, value in ipairs(rarities) do
    if value == rarity then return 0.5 * 5 ^ (index - 1) end
  end
  error("unknown rarity: " .. tostring(rarity))
end

local function lootChances(items, rarity, categoryWeights)
  local eligible, categoryTotals, categoryWeightTotal = {}, {}, 0
  for _, item in ipairs(items) do
    if item.rarity == rarity then
      local gameplayCost = (item.weight or 1) * (item.utility or 1) * math.max((item.health or 1) ^ 0.25, 1)
      local raw = 1 / gameplayCost
      eligible[item.name] = { raw = raw, category = item.category }
      categoryTotals[item.category] = (categoryTotals[item.category] or 0) + raw
    end
  end
  for category in pairs(categoryTotals) do categoryWeightTotal = categoryWeightTotal + (categoryWeights[category] or 1) end
  local chances = {}
  for name, data in pairs(eligible) do
    local categoryShare = (categoryWeights[data.category] or 1) / categoryWeightTotal
    chances[name] = categoryShare * data.raw / categoryTotals[data.category]
  end
  return chances
end

local function sortedNames(values)
  local names = {}
  for name in pairs(values) do names[#names + 1] = name end
  table.sort(names)
  return names
end

local function sample(chances, rng)
  local roll, cumulative, fallback = rng:number(0, 1), 0, nil
  for _, name in ipairs(sortedNames(chances)) do
    fallback = name
    cumulative = cumulative + chances[name]
    if roll <= cumulative then return name end
  end
  return fallback
end

local questPools = {
  { "Highest Wave", "Frontline Clears" },
  { "Enemies", "Damage", "Currency" },
  { "Unit Damage", "Trap Damage", "Class Damage" },
  { "Clean Clears", "Unit Specialist", "Trap Specialist" },
}
local classes = { "Rapid Fire", "Splash", "Close Range", "Sniper", "Artillery" }

local function roundTarget(value, kind)
  if kind:find("Damage") then
    local step = value >= 1e6 and 10000 or value >= 1e5 and 1000 or value >= 1e4 and 100 or 10
    return math.max(math.floor(value / step + 0.5) * step, step)
  elseif kind == "Enemies" then
    return math.max(math.floor(value / 10 + 0.5) * 10, 10)
  elseif kind == "Currency" then
    return math.max(math.floor(value * 100 + 0.5) / 100, 0.01)
  end
  return math.max(math.floor(value + 0.5), 1)
end

local function generateQuests(period, wave, weekly)
  local quests, minRuns, maxRuns = {}, weekly and 80 or 12, weekly and 120 or 18
  for index, pool in ipairs(questPools) do
    local rng = newRng(period * 20 + (weekly and 10 or 0) + index)
    local kind = pool[rng:integer(1, #pool)]
    local runs = rng:integer(minRuns, maxRuns)
    local difficulty = (runs - minRuns) / (maxRuns - minRuns)
    local variation, target, subject = rng:number(0.9, 1.1), runs, nil
    if kind == "Enemies" then target = wave.enemies * runs * 2 * variation
    elseif kind == "Damage" then target = wave.health * runs * variation
    elseif kind == "Unit Damage" then target = wave.health * runs * 0.85 * variation
    elseif kind == "Trap Damage" then target = wave.health * runs * 0.25 * variation
    elseif kind == "Class Damage" then
      subject = classes[rng:integer(1, #classes)]
      target = wave.health * runs * 0.6 * variation
    elseif kind == "Currency" then target = wave.currency * runs * 1.4 * variation
    elseif kind == "Frontline Clears" then target = runs * 1.2 * variation
    elseif kind == "Clean Clears" or kind == "Unit Specialist" or kind == "Trap Specialist" then target = runs * 0.4 * variation
    elseif kind == "Highest Wave" then target = math.max(10, math.floor(wave.score ^ 0.25 + 0.5)) end
    quests[#quests + 1] = { kind = kind, subject = subject, target = roundTarget(target, kind),
      reward = math.floor((weekly and 10 or 3) + difficulty * (weekly and 4 or 2)) }
  end
  return quests
end

print("Rarity power curve")
for _, rarity in ipairs(rarities) do print(string.format("  %-10s %9.1f base DPS", rarity, rarityPower(rarity))) end

local items = {
  { name = "Scout", rarity = "Rare", category = "Units", weight = 1 },
  { name = "Bulwark", rarity = "Rare", category = "Units", weight = 3 },
  { name = "Pulse Trap", rarity = "Rare", category = "Traps", weight = 1.5 },
  { name = "Barrier", rarity = "Rare", category = "Blocks", health = 2400 },
}
local chances = lootChances(items, "Rare", { Units = 4, Traps = 2, Blocks = 1 })
local total = 0
print("\nNormalized Rare loot table")
for _, name in ipairs(sortedNames(chances)) do
  total = total + chances[name]
  print(string.format("  %-12s %6.2f%%", name, chances[name] * 100))
end
assert(math.abs(total - 1) < 1e-9, "loot probabilities did not normalize")

local trials, observed, rng = 100000, {}, newRng(90210)
for _ = 1, trials do local name = sample(chances, rng); observed[name] = (observed[name] or 0) + 1 end
print("\nMonte Carlo check (100,000 rolls)")
for _, name in ipairs(sortedNames(chances)) do
  print(string.format("  %-12s expected %6.2f%%  observed %6.2f%%", name, chances[name] * 100, observed[name] / trials * 100))
end

local wave = { enemies = 96, health = 48000, currency = 3.8, score = 12000 }
print("\nDeterministic daily quests")
for index, quest in ipairs(generateQuests(20261019, wave, false)) do
  print(string.format("  %d. %-18s target %-9s reward %d%s", index, quest.kind, tostring(quest.target), quest.reward,
    quest.subject and (" [" .. quest.subject .. "]") or ""))
end