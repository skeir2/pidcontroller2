function onTick(gimbal, FR_SpeedController, FL_SpeedController, BR_SpeedController, BL_SpeedController)
    local controllers = {
        FR = FR_SpeedController, 
        FL = FL_SpeedController, 
        BR = BR_SpeedController, 
        BL = BL_SpeedController
    }

    for positionName, controllerName in pairs(controllers) do
        local controller = peripheral.wrap(controllerName)
        print(string.format("%s, %s: %d", positionName, controllerName, controller.getTargetSpeed()))
    end
end

function init(gimbal, FR_SpeedController, FL_SpeedController, BR_SpeedController, BL_SpeedController)
    while true do
        onTick(gimbal, FR_SpeedController, FL_SpeedController, BR_SpeedController, BL_SpeedController)
        sleep(0.1)
    end
end
 
-- initialize here
local gimbal = "left"
local FR_SpeedController = "Create_RotationSpeedController_2"
local FL_SpeedController = "Create_RotationSpeedController_0"
local BR_SpeedController = "Create_RotationSpeedController_1"
local BL_SpeedController = "Create_RotationSpeedController_3"
init(gimbal, FR_SpeedController, FL_SpeedController, BR_SpeedController, BL_SpeedController)