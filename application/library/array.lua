--------------------------------------------------------------------------------
-- array.lua, v0.0.1: basic array creator
-- Copyright (c) 2016 zhhgjian <zhhgjian@126.com>
-- License: MIT
-- https://github.com/zhhgjian/array
--------------------------------------------------------------------------------
local _M = {}
_M._VERSION = '0.01'

function _M:new( T )
	T= T or {}
	setmetatable(T, 
		{
			__index = self,
			__add = function(a,b)
				local array = _M:new()
				for k,v in pairs(a) do array[k] = v end
				for k,v in pairs(b) do array[k] = v end

				return array
			end
		}
	)

	self.__newindex = function(table, key, value)
		table[key] = value
	end

	return T
end

function _M:insert( value, pos )
	local array = self
	if pos ~= nil and type(pos) == 'number'  then
		table.insert(array, pos, value)
	else
		table.insert(array, value)
	end
end

function _M:array_shift(  )
	return self:remove(0)
end

function _M:array_keys()
	local array = self
	local keys = {}
	for k,v in pairs(array) do
		if k ~= '__newindex' then
			keys[#keys+1] = k
		end
	end
	return keys
end

function _M:concat_keys(sep)
	local array = self
	local keys = {}
	for k,v in pairs(array) do
		if k ~= '__newindex' then
			keys[#keys+1] = k
		end
	end
    
	return table.concat(keys, sep)
end

function _M:array_values()
	local array = self
	local vals = {}
	for k,v in pairs(array) do
		if k ~= '__newindex' then
			vals[#vals+1] = v
		end
	end

	return vals
end

function _M:concat( sep )
	local array = self:is_array() and self or self:array_values()
	
	return table.concat(array, sep)
end

function _M:remove( pos )
	local array = self
	if pos ~= nil and type(pos) == 'number'  then
		table.remove(array, pos)
	else
		table.remove(array)
	end
end

function _M:is_array()
	local array = self
    if type(array) ~= "table" then return false end
    local i = 1
    for _ in pairs(array) do
        if array[i] == nil then return false end
        i = i + 1
    end
    return true
end

function _M:in_array(needle)
	local array = self
	for _,v in pairs(array) do
		if(needle == v) then return true end
	end

	return false
end

function _M:key_exists( key )
	local array = self
	local search = array[key]

	if search ~= nil then
		return true, search
	else
		return false, nil
	end
end

return _M