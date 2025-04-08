local filename = "coords.txt"

-- Check if the file exists
if fs.exists(filename) then
    -- Open the file for reading
    local file = fs.open(filename, "r")
    local x = file.readLine()
    local y = file.readLine()
    local z = file.readLine()
    file.close()

    -- Display the stored coordinates
    print("Coordinates found:")
    print("X: " .. x)
    print("Y: " .. y)
    print("Z: " .. z)

    print("Starting GPS node at those coordinates...")

    shell.run("gps", "host", x, y, z)
else
    -- Prompt user for coordinates
    print("No coordinates found. Please enter new ones.")
    
    write("Enter X coordinate: ")
    local x = read()

    write("Enter Y coordinate: ")
    local y = read()

    write("Enter Z coordinate: ")
    local z = read()

    -- Save to file
    local file = fs.open(filename, "w")
    file.writeLine(x)
    file.writeLine(y)
    file.writeLine(z)
    file.close()

    print("Coordinates saved!")
end
