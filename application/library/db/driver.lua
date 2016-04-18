local ngx                  = ngx
local helpers = require 'vanilla.v.libs.utils'

local _M = {}

function _M.is_array(t)
	if type(t) ~= "table" then return false end
	local i = 1
	for _ in pairs(t) do
		if t[i] == nil then return false end
		i++
	end
	return true
end

function _M.table_is_array(t)
    if type(t) ~= "table" then return false end
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end

function _M.sprint_r( ... )
    return helpers.sprint_r(...)
end

function _M.lprint_r( ... )
    local rs = _M.sprint_r(...)
    ngx.print(rs)
end

function _M.print_r( ... )
    local rs = _M.sprint_r(...)
    ngx.say(rs)
end

function _M:err_log(msg)
    ngx.log(ngx.ERR, "===zjdebug" .. msg .. "===")
end

return _M
