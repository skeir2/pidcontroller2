local DELTA_TIME = 0.1
local pidfactory = require("pidfactory")

-- init
local gimbal = "left"
local FR_SpeedController = "Create_RotationSpeedController_2"
local FL_SpeedController = "Create_RotationSpeedController_0"
local BR_SpeedController = "Create_RotationSpeedController_1"
local BL_SpeedController = "Create_RotationSpeedController_3"

local roll_pid = pidfactory.create_pid(0.5, 0, 0, 0)
local pitch_pid = pidfactory.create_pid(0.5, 0, 0, 0)

function onTick()
    local controllers = {
        FR = FR_SpeedController, 
        FL = FL_SpeedController, 
        BR = BR_SpeedController, 
        BL = BL_SpeedController
    }

    for positionName, controllerName in pairs(controllers) do
        local controller = peripheral.wrap(controllerName)
        print(string.format("%s: %d", positionName, controller.getTargetSpeed()))
    end

    print(roll_pid:tick(1, 0, DELTA_TIME))
end

function init()
    while true do
        onTick()
        sleep(DELTA_TIME)
    end
end

init()