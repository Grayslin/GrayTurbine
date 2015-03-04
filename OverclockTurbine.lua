component = require 'component'
local event = require("event")
local fs = require("filesystem")
local keyboard = require("keyboard")
local shell = require("shell")
local term = require("term")
local text = require("text")
local unicode = require("unicode")
local sides = require("sides")
local colors=require("colors")

local gpu=component.gpu
side = require 'sides'

RS_CONTROL = side.south
RF_BUFFER_MAX = 9000000
RF_BUFFER_MIN = 1000
TEMP_MAX = 300
TEMP_MIN = 100
local tickCnt = 0
local turbineCnt = 1
local hours = 0
local mins = 0
local rtrStat = 'OFF'

REACTORS = {}
TURBINES = {}
local running = true

gpu.setResolution(80,25)

for address, type in component.list() do
    if type == 'br_reactor' then
        table.insert(REACTORS, component.proxy(address))
        print('Found reactor at ' .. address)
    elseif type == 'br_turbine' then
        table.insert(TURBINES, component.proxy(address))
        print('Found turbine at ' .. address)
    end
end

local function onKeyDown(opt)
  if opt == keyboard.keys.q then
   -- gpu.setResolution(160, 50)
    running = false
  end
end

function roundtfd(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

while running do -- Main Loop
term.clear()
  tickCnt = tickCnt + 1
  if tickCnt == 20 then
    mins = mins + 1
    tickCnt = 0
  end
  
  if mins == 60 then
    hours = hours + 1
    mins = 0
  end
  
turbineCnt = 1
turbineActive = 'ACTIVE'
  for _, t in pairs(TURBINES) do
        if t.getActive == false then
            turbineActive = 'SHUT DOWN'
        end
        if t.getRotorSpeed() < 1000000 then
            t.setInductorEngaged(false)
        end
        if t.getRotorSpeed() > 1100000 then
            t.setInductorEngaged(true)
        end
        if t.getInductorEngaged() == true then
            rtrStat = 'ON'
        end
        if t.getInductorEngaged() == false then
            rtrStat = 'OFF'
        end
       print('Turbine ' .. turbineCnt ..' power: ' .. roundtfd(t.getEnergyProducedLastTick(),0) .. ' RF/t' ..' RF stored: ' ..  roundtfd(t.getEnergyStored(),0) ..' Rotor Speed ' .. roundtfd(t.getRotorSpeed(),0) .. ' Rotor:' .. rtrStat)
       turbineCnt = turbineCnt + 1
    end

print('\n---------------------------------------------------------\n')
print('Current uptime: ' .. hours .. ' hours ' .. mins .. ' mins')
print('Data updates every second. Tick Count: ' .. tickCnt)

  local event, address, arg1, arg2, arg3 = event.pull(1)
  if type(address) == "string" and component.isPrimary(address) then
    if event == "key_down" then
      onKeyDown(arg2)
    end
  end
    os.sleep(0.04) -- Don't lag out the server

end
