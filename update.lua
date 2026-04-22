local pidURL = "https://raw.githubusercontent.com/skeir2/pidcontroller2/refs/heads/main/pid.lua"
local pid
local pidFile

pid = http.get(pidURL)
pidFile = pid.readAll()

local file1 = fs.open("pid.lua", "w")
file1.write(pidFile)
file1.close()

print("updated")