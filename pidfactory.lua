local function clamp(num,low,high)
    num = math.min(num,high)
    num = math.max(num,low)
    return num
end

local function create_pid(kp, ki, kd, bias)
    local pid = {
        kp = kp,
        ki = ki,
        kd = kd,
        bias = bias,
        error_prior = 0,
        integral_prior = 0,
        tick = function(self, setpoint, getpoint, strength_mult, delta_time)
            local kp = self.kp * strength_mult
            local ki = self.ki * strength_mult
            local kd = self.kd * strength_mult 

            local setRps = setpoint
            local getRps = getpoint
        
            local error = setRps - getRps
            local integral = clamp(self.integral_prior+error*delta_time,-100/ki,100/ki)
            local derivative = (error-self.error_prior)/delta_time
        
            local value_out = kp*error+ki*integral+kd*derivative+bias
        
            self.error_prior = error
            self.integral_prior = integral
        
            return value_out
        end
    }

    return pid
end

return { create_pid = create_pid }