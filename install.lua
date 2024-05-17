local file = fs.open("look.lua", "w")

local content = [[
    local contentEdited = false
local count = 0
local allContents

function scanBarrel(barrelPeripheral)
    print("Scanning barrel " .. count + 1 .. "/" .. #peripheral.getNames() - 2)
    local contents = {}
    count = count + 1
    for slot = 1, 27 do
        local itemDetail = barrelPeripheral.getItemDetail(slot)
        if itemDetail then
            contentEdited = true
            local itemName = itemDetail["displayName"]
            if contents[itemName] then
                contents[itemName] = contents[itemName] + itemDetail["count"]
            else
                contents[itemName] = itemDetail["count"]
            end
        end
    end
    if not contentEdited then
        contents = nil
    end
    return contents
end

function displayContents(contents, monitor)
monitor.clear()
if contents then
    print("Displaying contents on monitor")
    monitor.setCursorPos(1, 1)
    monitor.write("Storage System Contents:")
    local y = 3
    for item, count in pairs(contents) do
        monitor.setCursorPos(1, y)
        monitor.write(item .. ": " .. count)
        y = y + 1
    end
else
    monitor.write("Loading...") 
    allContents = scanAllBarrels()
end
    term.redirect(monitor)
    paintutils.drawFilledBox(monitor.getSize() / 2 - 10, 18, monitor.getSize() / 2 - 5, 18, colors.gray)
    paintutils.drawFilledBox(monitor.getSize() / 2 + 10, 18, monitor.getSize() / 2 + 5, 18, colors.gray)
    x, y = monitor.getCursorPos()
    monitor.setCursorPos(monitor.getSize() / 2 - 10, 18)
    print("Reload")
    monitor.setCursorPos(monitor.getSize() / 2 + 10 - 4, 18)
    print("Back")
    monitor.setBackgroundColor(colors.black)
    term.redirect(term.native())
end

function scanAllBarrels()
    local allContents = {}
    local barrelPeripherals = {}
        for _, peripheralName in ipairs(peripheral.getNames()) do
        if peripheral.getType(peripheralName) == "minecraft:barrel" then
            table.insert(barrelPeripherals, peripheral.wrap(peripheralName))
        end
    end
    local scanTasks = {}
    for i, barrelPeripheral in ipairs(barrelPeripherals) do
        table.insert(scanTasks, function()
            local contents = scanBarrel(barrelPeripheral)
            if contents then
                for item, count in pairs(contents) do
                    if allContents[item] then
                        allContents[item] = allContents[item] + count
                    else
                        allContents[item] = count
                    end
                end
            end
        end)
    end
    parallel.waitForAll(table.unpack(scanTasks))
    return allContents
end

function main()
    local monitor = peripheral.find("monitor")
    displayContents(nil, monitor)
    if monitor then
        print("Monitor found")
        while true do
            contentEdited = false
            count = 0
            local event, button, mx, my = os.pullEvent("monitor_touch")
            if mx >= monitor.getSize() / 2 - 10 and mx <= monitor.getSize() / 2 - 5 and my >= 18 and my <= 18 then
                allContents = scanAllBarrels()
            end
            if mx >= monitor.getSize() / 2 + 5 and mx <= monitor.getSize() / 2 + 10 and my >= 18 and my <= 18 then
                dofile("startup.lua")
            end
            if allContents then
                print("All contents scanned successfully")
                displayContents(allContents, monitor)
            else
                print("No contents found")
            end
            sleep(0.1)
      end
    else
        print("No monitor found. Please attach a monitor.")
    end
end
main()
]]

file.write(content)

file.close()

local file = fs.open("startup.lua", "w")
    
local content = [[
    local progress = 0
local monitor = peripheral.find("monitor")
term.redirect(monitor)
monitor.setBackgroundColor(colors.black)
paintutils.drawFilledBox(2, 2, 10, 5)
monitor.setCursorPos(1, 1)
function monitor.writeline(text, sameline, offset)
    _, y = monitor.getCursorPos()
    if offset then
        monitor.setCursorPos(monitor.getSize() / 2 + (#text + offset) / 2, y)
    else
        monitor.setCursorPos(monitor.getSize() / 2 - #text / 2, y)
    end
    monitor.write(text)
    if not sameline then
        monitor.setCursorPos(_, y + 1)
    end
end
monitor.setTextColour(1)
function showMessage()
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.setTextColour(1)
    monitor.writeline("Welcome to S.O.R.T")
    if progress < 10 then
        for i = 0, 10, 1 do
        if i > progress then
            monitor.setTextColour(1) 
        else
            monitor.setTextColour(2048)
        end
            monitor.writeline("|", true, (i - 5) * 2)
        end
    else
        monitor.writeline("Done Loading")
    end
end
local inputText
while true do 
    if progress < 10 then
        progress = progress + 1
    else
        paintutils.drawFilledBox(monitor.getSize() / 2 - 10, 18, monitor.getSize() / 2 - 5, 18, colors.gray)
        paintutils.drawFilledBox(monitor.getSize() / 2 + 10, 18, monitor.getSize() / 2 + 5, 18, colors.gray)
        x, y = monitor.getCursorPos()
        monitor.setCursorPos(monitor.getSize() / 2 - 10 + 1, 18)
        print("Lift")
        monitor.setCursorPos(monitor.getSize() / 2 + 10 - 4, 18)
        print("Info")
        local event, button, mx, my = os.pullEvent("monitor_touch")
        monitor.setBackgroundColor(colors.black)
        if mx >= monitor.getSize() / 2 - 10 and mx <= monitor.getSize() / 2 - 5 and my >= 18 and my <= 18 then
            dofile("down.lua")
        end
        if mx >= monitor.getSize() / 2 + 5 and mx <= monitor.getSize() / 2 + 10 and my >= 18 and my <= 18 then
            dofile("look.lua")
        end     
    end
    showMessage()
    sleep(0.5)
end
]]

file.write(content)

file.close()