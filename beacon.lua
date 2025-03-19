os.pullEvent = os.pullEventRaw

--[[
So, for anyone trying to work with this code, here's a little 
warning : most of it is asynchronous, and a major pain to make
work. I had to re-check the regex SEVERAL TIMES, and had some
odd race conditions to deal with. 

Most of the data has nil-checks and default states, in order to 
basically handle those nasty products from functions running 
asynchronously.
By the way, the first line is to prevent the user from breaking 
the beacon and accessing the OS, which depending on what you want 
to do, you may need to remove. I placed it here as to keep the 
computer for that program, for it to have a single purpose.

By the way, if you decide to run this program on a computer instead 
of a tablet, you have the option of powering it with redstone to 
print out a help page with an adjacent printer, if necessary.
Made with love, 
-Camille <3
]]--

-- Delay (in milliseconds) before a beacon is 
-- considered "dead" and thus removed.
TIMEOUT = 1000

-- Delay (in seconds) inbetween broadcasts
-- and fetches of information.
REFRESH_RATE = 0.01

function PrintMANPage()
    while true do
        while os.pullEvent("redstone") ~= nil do
            local printer = peripheral.find("printer")
            io.write("Printing a new MANUAL page")
            if not printer.newPage() then
                io.write("\nCan't print MAN page\n")
            else
                if printer.getInkLevel() > 0 and printer.getPaperLevel() > 0 then
                    printer.setPageTitle("Beacon MANUAL")
                            
                    local lines = {
                        "Beacon MANUAL",
                        "- By Camille -",
                        "",
                        "Instructions to use ",
                        "the beacons :",
                        "1. Turn on the computer",
                        "2. Input the GPS channel",
                        "   you want to use",
                        "3. Input a name for",
                        "   the beacon to use",
                        "4. As long as the beacon",
                        "   is active, it will",
                        "   broadcast your ",
                        "   location to others,",
                        "   as well as displaying",
                        "   your location and that",
                        "   of the closest beacons",
                        "",
                        "Made with love (and pain),",
                        "  -Camille <3"
                    }
    
                    for key, line in ipairs(lines) do
                        printer.setCursorPos(1, key+1)  -- Corrected function name
                        printer.write(line)
                    end
    
                    printer.endPage()
                else
                    io.write("\nPrinter is out of ink or paper!\n")
                end
            end
            sleep(3)
        end
    end
end

local function SavePDAData(pdaID, data)
    local filename = "beacon.cfg"
    local file = fs.open(filename, "w")

    for key, value in pairs(data) do
        if type(value) == "table" then
            value = table.concat(value, ",") -- Convert table (e.g., location) to a string
        end
        file.write(key .. ":" .. tostring(value) .. "\n")
    end

    file.close()
  end

  local function LoadPDAData()
    local filename = "beacon.cfg"
    if not fs.exists(filename) then return {} end

    local file = fs.open(filename, "r")
    local data = {}

    while true do
        local line = file.readLine()
        if not line then break end

        local key, value = line:match("([^:]+):(.+)")
        if key and value then
            -- Convert booleans back
            if value == "true" then value = true end
            if value == "false" then value = false end

            -- Convert numbers back
            if tonumber(value) then value = tonumber(value) end

            -- Convert location (comma-separated values)
            if key == "location" then
                local x, y, z = value:match("([^,]+),([^,]+),([^,]+)")
                data[key] = {tonumber(x), tonumber(y), tonumber(z)}
            else
                data[key] = value
            end
        end
    end

    file.close()
    return data
  end

-- Used to link to all other beacons
rednet.open("back")

-- So, fun fact, computercraft doesn't support these characters,
-- so my pretty logo was unnecessary :(
--local logo = {
--    "╭╮", --1
--    "││╿", --2
--    "│└┴╮", --3
--    "│>/│", --4
--    "╰──╯", --5
--}

local logo = {
    "/\\",
    "||",
    "|'-.",
    "|>?|",
    "\\__/"
}

local pdaInfo = {
    pdaID = os.getComputerID(),
    user = "VOID",
    channel = 65534
  }

if not fs.exists("beacon.cfg") then
    -- Ask the user what channel they'd want to use, so that we can separate GPS meshes
    -- by channel, which is also used for rednet connections
    io.write("\n\n\n--- Basic GPS Beacon ---")
    io.write("\nPlease enter what GPS channel to use (Leave blank for default)\n> ")
    local channel = io.read()
    for i = 1, 42 do
        io.write("\n")
    end

    -- Validate that the provided channel is a right number
    CHANNEL_GPS = tonumber(channel) or 65534

    io.write("\n\n\nUsing channel "..CHANNEL_GPS.."\n\n\n")

    io.write("What name do you want this peripheral to use ?\n> ")
    BeaconName = io.read()

    pdaInfo.channel = tonumber(channel) or 65534
    pdaInfo.user = tostring(BeaconName)

    SavePDAData(os.getComputerID(),pdaInfo)

    for i = 1, 42 do
        io.write("\n")
    end
else
    local pdaInfo = LoadPDAData()
    

    CHANNEL_GPS = tonumber(pdaInfo.channel) or 65534
    BeaconName = tostring(pdaInfo.user)
end

sleep(1)

for i = 1, 42 do
    io.write("\n")
end

for i = 1, 3 do
    for i, line in ipairs(logo) do
        io.write(line.."\n")
    end
    io.write("\n\n\nChannel : "..tostring(pdaInfo.channel).."\nName : "..BeaconName.."\n\n")
    io.write("Starting in "..4-i.." . . .")
    sleep(1)
    for i = 1, 42 do
        io.write("\n")
    end
end

-- Implementation of the Euclidian distance formula ;
-- sqrt((x2-x1)^2+(y2-y1)^2+(z2-z1)^2)
-- Just provide the XYZ coordinates of the first and second point,
-- and it'll return the distance
local function CalculateDistance(x1,y1,z1,x2,y2,z2)
    if x1 == nil or x2 == nil or y1 == nil or y2 == nil or z1 == nil or z2 == nil then
        return -1
    end
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    dx = dx * dx
    dy = dy * dy
    dz = dz * dz
    local sum = dx + dy + dz
    return math.sqrt(sum)
end

local function parseData(dataString)
    if not dataString then 
        --io.write("Warning: Received empty data string!\n")
        return nil, nil, nil, nil 
    end

    -- Trim whitespace or hidden characters
    dataString = dataString:gsub("^%s*(.-)%s*$", "%1")

    -- Debugging: Print the raw data
    --io.write("Debug: Raw received data -> [" .. dataString .. "]\n")

    -- Extract values (supporting floating-point numbers)
    local x, y, z, name = dataString:match("|(-?%d+%.?%d*):(-?%d+%.?%d*):(-?%d+%.?%d*):(.+)|")

    -- Debugging: Print extracted values
    --io.write("Debug: Extracted -> X: " .. tostring(x) .. " Y: " .. tostring(y) .. " Z: " .. tostring(z) .. " Name: " .. tostring(name) .. "\n")

    -- Convert x, y, z to numbers
    x, y, z = tonumber(x), tonumber(y), tonumber(z)

    -- Ensure all values are valid before returning
    if not x or not y or not z or not name then
        --io.write("Warning: Malformed data received -> [" .. dataString .. "]\n")
        return nil, nil, nil, nil
    end

    return x, y, z, name
end

local running = true -- Flag to kill all processes in case of termination

Locations = {}
local function ReceiveLocation(channel)
    while running do
        local myX, myY, myZ = gps.locate(2)
        local senderID, data = rednet.receive(tostring(channel))

        if data and (senderID ~= os.getComputerID()) then
            --io.write("DATA RECEIVED: " .. tostring(data) .. "\n")
            local dx, dy, dz, name = parseData(data)

            -- Ensure valid data before storing
            if dx and dy and dz and name then
                Locations[name] = {
                    x = dx, y = dy, z = dz,
                    distance = CalculateDistance(myX, myY, myZ, dx, dy, dz),
                    lastUpdate = os.epoch("utc")
                }
                --io.write("Debug: Stored in Locations -> " .. name .. " at (" .. dx .. ", " .. dy .. ", " .. dz .. ") dΔ " .. Locations[name].distance .. "\n")
            --else --? Stupidly enough, removing this line avoids spam from disrupting beacons
            --    io.write("Warning: Received invalid data from sender " .. senderID .. "\n")
            end
        --else
        --    io.write("DATA MISSING!\n")
        end
    end
end

local function displayData()
    while running do
        for i = 1, 42 do io.write("\n") end

        local myX, myY, myZ = gps.locate(2)
        if (myX == nil) or (myY == nil) or (myZ == nil) then
            myX = 0
            myY = 0
            myZ = 0
        end
        local currentTime = os.epoch("utc")
        io.write("C:"..CHANNEL_GPS.." N:"..BeaconName.."\nLoc:\nX:"..myX.."\nY:"..myY.."\nZ:"..myZ.."\n\n")

        if next(Locations) == nil then
            io.write("No other beacons detected.\n")
        else
            --io.write("Debug: Detected beacons:\n")
            for name, entry in pairs(Locations) do
                if currentTime - entry.lastUpdate > TIMEOUT then
                    Locations[name] = nil
                end
                local countLocations = 0
                for _ in pairs(Locations) do countLocations = countLocations + 1 end
                if entry then
                    if countLocations < 3 then
                        io.write(",- "..name.." - Dist:"..string.format("%.2f",tostring(entry.distance)).."\n| X:"..entry.x.."\n| Y:"..entry.y.."\n^-Z:"..entry.z.."\n")
                    else
                        io.write("-"..name.." - Dist:"..string.format("%.2f",tostring(entry.distance)).."\n")
                    end
                end
            end
        end
        sleep(REFRESH_RATE)
    end
end

local function TransmitLocation(channel,BeaconName)
    while running do
        local x, y, z = gps.locate(2)
        local data = "|"..x..":"..y..":"..z..":"..BeaconName.."|"
        rednet.broadcast(data,tostring(channel))
        sleep(0.1)
    end
end

function Reset()
    os.pullEventRaw("terminate")
    fs.delete("beacon.cfg")
    io.write("\n*--------------*")
    io.write("\n|Config reset !|")
    io.write("\n*--------------*\n")
    for i = 1, 4 do
        io.write("Rebooting in "..4-i)
        sleep(1)
    end
    os.reboot()
end

if turtle or pocket then
    parallel.waitForAny(
        Reset,
        function() TransmitLocation(CHANNEL_GPS, BeaconName) end,
        function() ReceiveLocation(CHANNEL_GPS) end,
        function() displayData() end
    )
else
    parallel.waitForAny(
        PrintMANPage,
        Reset,
        function() TransmitLocation(CHANNEL_GPS, BeaconName) end,
        function() ReceiveLocation(CHANNEL_GPS) end,
        function() displayData() end
    )
end