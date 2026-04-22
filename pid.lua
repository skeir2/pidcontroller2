local ticker = 0.0
local movement_threshold = 3
local movement_angle = 20
local THRUST_MULTIPLIER = 1/1.5
 
local error_prior_pitch = 0
local integral_prior_pitch = 0
local kp_pitch = 0.5 * THRUST_MULTIPLIER
local ki_pitch = 0.05 * THRUST_MULTIPLIER
local kd_pitch = 0.2 * THRUST_MULTIPLIER
local bias_pitch = 0
 
local error_prior_roll = 0
local integral_prior_roll = 0
local kp_roll = 0.5 * THRUST_MULTIPLIER
local ki_roll = 0.05 * THRUST_MULTIPLIER
local kd_roll = 0.2 * THRUST_MULTIPLIER
local bias_roll = 0
 
function pitchPID(setpoint,getpoint)
    local setRps = setpoint
    local getRps = getpoint
 
    local error = setRps - getRps
    local integral = clamp(integral_prior_pitch+error*0.1,-100/ki_pitch,100/ki_pitch)
    local derivative = (error-error_prior_pitch)/0.1
 
    local value_out = kp_pitch*error+ki_pitch*integral+kd_pitch*derivative+bias_pitch
 
    error_prior_pitch = error
    integral_prior_pitch = integral
 
    return value_out
end
 
function rollPID(setpoint,getpoint)
    local setRps = setpoint
    local getRps = getpoint
 
    local error = setRps - getRps
    local integral = clamp(integral_prior_roll+error*0.1,-100/ki_roll,100/ki_roll)
    local derivative = (error-error_prior_roll)/0.1
 
    local value_out = kp_roll*error+ki_roll*integral+kd_roll*derivative+bias_roll
 
    error_prior_roll = error
    integral_prior_roll = integral
 
    return value_out
end
 
function onTick(frontRelay, backRelay, leftRelay, rightRelay, coarseFrontRelay, coarseBackRelay, coarseLeftRelay, coarseRightRelay)
	ticker = ticker + 0.1
    frontSignal = peripheral.call(frontRelay, "getAnalogInput", "back")
    backSignal = peripheral.call(backRelay, "getAnalogInput", "back")
    leftSignal = peripheral.call(leftRelay, "getAnalogInput", "back")
    rightSignal = peripheral.call(rightRelay, "getAnalogInput", "back")
 
    coarseFrontSignal = peripheral.call(coarseFrontRelay, "getAnalogInput", "front")
    coarseBackSignal = peripheral.call(coarseBackRelay, "getAnalogInput", "front")
    coarseLeftSignal = peripheral.call(coarseLeftRelay, "getAnalogInput", "front")
    coarseRightSignal = peripheral.call(coarseRightRelay, "getAnalogInput", "front")
 
    if frontSignal == 15 then
        frontSignal = coarseFrontSignal * 9
	end
    if backSignal == 15 then
        backSignal = coarseBackSignal * 9
	end
    if rightSignal == 15 then
        rightSignal = coarseRightSignal * 9
	end
    if leftSignal == 15 then
        leftSignal = coarseLeftSignal * 9
	end
 
 
    top = peripheral.wrap("top")
    goFront = top.getInput("front")
    goBack = top.getInput("back")
    goLeft = top.getInput("left")
    goRight = top.getInput("right")
 
    local roll_set_point = 0
	local roll_modifier = 0
	local pitch_set_point = 0
	local pitch_modifier = 0
	
    if goFront then
        pitch_modifier = movement_threshold
		pitch_set_point = movement_angle
		
    elseif goBack then
        pitch_modifier = -movement_threshold
		pitch_set_point = -movement_angle
    end
 

    if goRight then
        roll_modifier = movement_threshold
		roll_set_point = movement_angle
    elseif goLeft then
        roll_modifier = -movement_threshold
		roll_set_point = -movement_angle
    end
 
    roll_point = rightSignal - leftSignal
    pitch_point = frontSignal - backSignal
    roll_torque = clamp(rollPID(roll_set_point,roll_point),-100,100)
    pitch_torque = clamp(pitchPID(pitch_set_point,pitch_point),-100,100)
	
	roll_correction = percent_torque_to_signal_strength(roll_torque)
	pitch_correction = percent_torque_to_signal_strength(pitch_torque)
 
    local roll_strength = modulate_power(ticker,math.abs(roll_correction))
    roll_strength = clamp(roll_strength, 0, 15)
    if roll_correction > 0 then
        print("right") 
        peripheral.call(rightRelay, "setAnalogOutput", "left", roll_strength)
        peripheral.call(leftRelay, "setAnalogOutput", "left", 0)
    else
        print("left")
        peripheral.call(rightRelay, "setAnalogOutput", "left", 0)
        peripheral.call(leftRelay, "setAnalogOutput", "left", roll_strength)
    end
 
    local pitch_strength = modulate_power(ticker,math.abs(pitch_correction))
    pitch_strength = clamp(pitch_strength, 0, 15)
    if pitch_correction > 0 then
        print("front")
        peripheral.call(frontRelay, "setAnalogOutput", "left", pitch_strength)
        peripheral.call(backRelay, "setAnalogOutput", "left", 0)
    else
        print("back")
        peripheral.call(frontRelay, "setAnalogOutput", "left", 0)
        peripheral.call(backRelay, "setAnalogOutput", "left", pitch_strength)
    end
 
	if ticker >= 1 then
		ticker = 0
	end
 
    print(string.format("F:%d, B:%d, L:%d, R:%d", frontSignal, backSignal, leftSignal, rightSignal))
    print(string.format("roll_set_point: %f, pitch_set_point: %f", roll_set_point, pitch_set_point))
    print(string.format("roll_point: %f, pitch_point: %f", roll_point, pitch_point))
    print(string.format("roll_torque: %f%% (%d), pitch_torque: %f%% (%d)", roll_torque, roll_strength, pitch_torque, pitch_strength))
end
 
function modulate_power(ticker, value)
	if ticker>(value - math.floor(value)) then
		return math.floor(value)
	else
		return math.ceil(value)
	end
end

function percent_torque_to_signal_strength(torque)--number from -100 to 100
	torque = clamp(torque,-100,100)
	sign = (torque < 0) and -1 or 1
	return sign * linear_to_analog_speed((100 - math.abs(torque))/100)
end

function linear_to_analog_speed(speed)-- accept # from 0 to 1, should scale speed linearly, return signal strength 0-15
	speed = clamp(speed,0,1)
	if speed>(14/16) then --for some reason analog transmissions have a discontinuity here, they jump to 14/16 from 0-1 instead of 15/16
		return 8-8*speed
	else
		return 15-16*speed
	end
end
 
function clamp(num,low,high)
    num = math.min(num,high)
    num = math.max(num,low)
    return num
end
 
 
function init(frontRelay, backRelay, leftRelay, rightRelay, coarseFrontRelay, coarseBackRelay, coarseLeftRelay, coarseRightRelay)
    while true do
        onTick(frontRelay, backRelay, leftRelay, rightRelay, coarseFrontRelay, coarseBackRelay, coarseLeftRelay, coarseRightRelay)
        sleep(0.1)
    end
end
 
-- initialize here
local frontRelay = "redstone_relay_8"
local backRelay = "redstone_relay_7"
local leftRelay = "redstone_relay_6"
local rightRelay = "redstone_relay_5"
local coarseFrontRelay = "redstone_relay_12"
local coarseBackRelay = "redstone_relay_10"
local coarseLeftRelay = "redstone_relay_9"
local coarseRightRelay = "redstone_relay_11"
init(frontRelay, backRelay, leftRelay, rightRelay, coarseFrontRelay, coarseBackRelay, coarseLeftRelay, coarseRightRelay)