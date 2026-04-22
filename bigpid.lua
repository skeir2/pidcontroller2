local DELTA_TIME = 0.1
local MIN_RPM = 0
local MAX_RPM = 256

local pidfactory = require("pidfactory")

-- init
local gimbal = peripheral.wrap("left")
local FR_SpeedController = peripheral.wrap("Create_RotationSpeedController_2")
local FL_SpeedController = peripheral.wrap("Create_RotationSpeedController_0")
local BR_SpeedController = peripheral.wrap("Create_RotationSpeedController_1")
local BL_SpeedController = peripheral.wrap("Create_RotationSpeedController_3")

local total_strength = 0.6 -- from 0 to 1

local roll_pid = pidfactory.create_pid(0.5, 0, 0, 0)
local pitch_pid = pidfactory.create_pid(0.5, 0, 0, 0)

local function get_current_rpm()
    return MAX_RPM * total_strength
end

-- strength goes from -1 to 1
-- controls rpm
local function set_roll_strength(strength)
    local rpm = get_current_rpm()
    local target_rpm = math.abs(strength) * rpm

    if strength > 0 then
        FR_SpeedController.setTargetSpeed(target_rpm)
        FL_SpeedController.setTargetSpeed(target_rpm)
        BR_SpeedController.setTargetSpeed(0)
        BL_SpeedController.setTargetSpeed(0)     
    else
        FR_SpeedController.setTargetSpeed(0)
        FL_SpeedController.setTargetSpeed(0)
        BR_SpeedController.setTargetSpeed(target_rpm)
        BL_SpeedController.setTargetSpeed(target_rpm)    
    end

    return target_rpm
end

local function set_pitch_strength(strength)
    local rpm = get_current_rpm()
    local target_rpm = math.abs(strength) * rpm

    if strength > 0 then
        FL_SpeedController.setTargetSpeed(0)
        FL_SpeedController.setTargetSpeed(0)
        BR_SpeedController.setTargetSpeed(target_rpm)
        BR_SpeedController.setTargetSpeed(target_rpm)    
    else
        FL_SpeedController.setTargetSpeed(target_rpm)
        FL_SpeedController.setTargetSpeed(target_rpm)
        BR_SpeedController.setTargetSpeed(0)
        BR_SpeedController.setTargetSpeed(0)    
    end

    return target_rpm
end

function onTick()
    roll_set_point = 45
    pitch_set_point = 0

    local angles = gimbal.getAngles()
    local x_angle = angles[1]
    local y_angle = angles[2]

    roll_point = x_angle
    pitch_point = y_angle

    local roll_strength = roll_pid:tick(roll_point, roll_set_point, 1, DELTA_TIME) / 180
    local pitch_strength = pitch_pid:tick(pitch_point, pitch_set_point, 1, DELTA_TIME) / 180

    local roll_target_rpm = set_roll_strength(roll_strength)
    local pitch_target_rpm = set_pitch_strength(pitch_strength)

    print(string.format("roll_set_point: %f, pitch_set_point: %f", roll_set_point, pitch_set_point))
    print(string.format("roll_point: %f, pitch_point: %f", roll_point, pitch_point))
    print(string.format("roll_target_rpm: %f, pitch_target_rpm: %f", roll_target_rpm, pitch_target_rpm))
end

function init()
    while true do
        onTick()
        sleep(DELTA_TIME)
    end
end

init()