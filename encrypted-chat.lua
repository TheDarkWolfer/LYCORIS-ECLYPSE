--TODO Add name registration
--TODO Add color linked to usernames
-- Seed the random number generator
math.randomseed(os.time())

-- List of syllables to use for generating names
local syllables = {
  "an", "bar", "cen", "dor", "en", "fal", "gor", "hal",
  "in", "jar", "kel", "lor", "mir", "nor", "or", "pan",
  "qua", "rin", "sar", "tan", "ur", "vin", "wen", "xon",
  "yor", "zan"
}

local usernameColors = {
    colors.white,
    colors.orange,
    colors.magenta,
    colors.lightBlue,
    colors.yellow,
    colors.lime,
    colors.pink,
    colors.gray,
    colors.lightGray,
    colors.cyan,
    colors.purple,
    colors.blue,
    colors.brown,
    colors.green,
    colors.red,
    colors.black,
}

function MapIdToColorIndex(id)
    return usernameColors[(id % 16) + 1]
end

-- Function to generate a name with a given number of syllables
function GenerateName(numSyllables)
  local name = ""
  for i = 1, numSyllables do
    -- Select a random syllable and concatenate it
    name = name .. syllables[math.random(#syllables)]
  end
  -- Capitalize the first letter
  name = name:gsub("^%l", string.upper)
  return name
end

-- Custom bitwise XOR function without using the ~ operator.
local function bitXor(a, b)
    local res = 0
    local bit = 1
    while a > 0 or b > 0 do
      local a_bit = a % 2
      local b_bit = b % 2
      local xor_bit = (a_bit + b_bit) % 2
      res = res + xor_bit * bit
      a = math.floor(a / 2)
      b = math.floor(b / 2)
      bit = bit * 2
    end
    return res
end
  
-- XOR cipher function for encryption and decryption.
function Xor_cipher(input, key)
    if not input or input == "" then
        return ""
    end
    local output = {}
    local key_len = #key
    for i = 1, #input do
      local input_byte = input:byte(i)
      local key_byte = key:byte((i - 1) % key_len + 1)
      -- Use our custom bitXor instead of the ~ operator.
      output[i] = string.char(bitXor(input_byte, key_byte))
    end
    return table.concat(output)
end


local convKey = "public"
local protocol = "EncryChat"

io.write("Initiating RedNet...")
rednet.open("back")
io.write("RedNet open !\nUsing protocol >"..protocol.."<")

function ManageInput()
    for _ = 1, 32 do
        io.write("\n")
    end
    while true do
        io.write(">")
        local input = io.read()
        local command, data = input:match("^(%S+)%s*(.*)$")
        if command == "/setkey" then
            convKey = data
            io.write("Conversation key set to >"..convKey.."<\n")
        elseif command == "/exit" then
            io.write("Exiting...")
            os.shutdown()
        elseif command == "/setprotocol" then
            protocol = data
            io.write("Changed protocol to >"..protocol.."<\n")
        elseif command == "/clear" then
            for _ = 1, 32 do
                io.write("\n")
            end
        else
            local encryptedText = Xor_cipher(input, convKey)
            rednet.broadcast(encryptedText,protocol)
        end
    end
end

function ManageOutput()
    while true do
        local senderID, encryptedText = rednet.receive(protocol)
        local text = Xor_cipher(encryptedText,convKey)
        io.write("\n"..senderID.."<")
        term.setTextColor(MapIdToColorIndex(senderID))
        io.write(text)
        term.setTextColor(colors.white)
        io.write("\n>")
    end
end

parallel.waitForAny(ManageOutput, ManageInput)
