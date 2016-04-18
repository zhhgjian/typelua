--------------------------------------------------------------------------------
-- statement.lua, v0.0.1: basic db statement creator
-- Copyright (c) 2016 zhhgjian <zhhgjian@126.com>
-- License: MIT
-- https://github.com/zhhgjian/typelua
--------------------------------------------------------------------------------

local array = require('library.array')
local pairs = pairs
local escape_string = ngx.quote_sql_str

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 20)
_M._VERSION = '0.01'

local statements = {
	'where', 	'orWhere',	
	'in',	    'notIn',     
	'between',  'high',     'low',      
	'like',     'notLike',  
	'isNull',   'isNotNull'
}

local function escape(q)
	if type(q) == "string" then
		q = escape_string(q)
		return q
	elseif type(q) == "table" then
		for k,v in pairs(q) do
			q[k] = escape_string(v)
		end
		return
	end
	return q
end

local function prepareStatementForWhere( command, sqlPreBuild, ... )
	local function equilWhere( sqlPreBuild, values, op )
		local where = nil

		if type(values) == 'string' then
			where = values
		elseif type(values) == 'table' then
			local array = array:new()
			for k,v in pairs(values) do
				array:insert(k..' = '..escape(v)..' ')
			end
	
			where = array:concat(op)
		end

		if where ~= nil then
			sqlPreBuild:insert(where)
		end
	end
	local function inWhere ( column, values, op )
		local where = nil
		op = op or 'IN'
		
		escape(values)
		if type(values) == 'table' and #values > 0 then
			where = "`"..column.."` "..op.." ("..table.concat(values, ',')..")"
		end

		return where
	end
	local function likeWhere( column, value, enable_start, enable_end, op )
		enable_start = enable_start ~= false
		enable_end   = enable_end ~= false
		op = op or ' LIKE '

		if enable_start then
			value = "%"..value
		end
		if enable_end then
			value = value.."%"
		end

		value = escape(value)
		return '`'..column..'` '..op..' '..value
	end
	local commands = {
		--[[
		 AND条件查询语句
	     
	     @param mix condition 条件内容
	      例1：where("name='test'")  字符串条件
		  例2：{name='liyan', time=123} table多条件
		--]]
		['where'] = function( ... )
			local condition = ...

			equilWhere(sqlPreBuild, condition, ' AND ')
		end,
		['orWhere'] = function( ... )
			local condition = ...
			
			equilWhere(sqlPreBuild, condition, ' OR ')
		end,
		--[[
		in条件
		column : 列名
		values : 在哪些值范围里面(数组)
		例：whereIn('test_name', {'liyan', 'test'})
		--]]
		['in'] = function( ... )
			local column, values = ...
			
			local where = inWhere(column, values)

			if where ~= nil then
				sqlPreBuild:insert(where)
			end
		end,
		--[[
		notIn条件
		column : 列名
		values : 不在哪些值范围里面(数组)
		例：whereNotIn('test_name', {'liyan', 'test'})
		--]]
		['notIn'] = function( ... )
			local column, values = ...
			
			local where = inWhere(column, values, 'NOT IN')
			if where ~= nil then
				sqlPreBuild:insert(where)
			end
		end,
		--[[
		between条件
		column : 列名
		min : 最小值
		max : 最大值
		--]]
		['between'] = function( ... )
			local column, minVal, maxVal = ...

			local where = '`'..column..'` BETWEEN '..(minVal or 0)..' AND '..(maxVal or 0)
			sqlPreBuild:insert(where)
		end,
		--[[
		> 或者 >= 条件
		column : 列名
		value  : 大于哪个值
		equel  : 是否等于(默认true)
		例：whereHigh('test_id', 3, false)
		--]]
		['high'] = function( ... )
			local column, value, equel = ...

			equel = equel ~= false
			local operator = equel and '>=' or '>'
			local where = '`'..column..'`'..operator..escape(value);
			sqlPreBuild:insert(where)
		end,
		--[[
		< 或者 <= 条件
		column : 列名
		value  : 小于哪个值
		equel  : 是否等于(默认true)
		例：whereLow('test_id', 3, false)
		--]]
		['low'] = function( ... )
			local column, value, equel = ...

			equel = equel ~= false
			local operator = equel and '<=' or '<'
			local where = '`'..column..'`'..operator..escape(value);
			sqlPreBuild:insert(where)
		end,
		--[[
		like 条件
		column : 列名
		value  : 值
		enable_start : 是否在开始加上%（默认true）
		enable_end   : 是否在结尾加上%（默认true）
		例：whereLike('test_name', 'liyan')
		--]]
		['like'] = function( ... )
			local column, value, enable_start, enable_end = ...

			local where = likeWhere(column, value, enable_start, enable_end)
			sqlPreBuild:insert(where)
		end,
		['notLike'] = function( ... )
			local column, value, enable_start, enable_end = ...

			local where = likeWhere(column, value, enable_start, enable_end, ' NOT LIKE ')
			sqlPreBuild:insert(where)
		end,
		['isNull'] = function ( ... )
			local column = ...
			local where = '`'..column..'` IS NULL '

			sqlPreBuild:insert(where)
		end,
		['isNotNull'] = function ( ... )
			local column = ...
			local where = '`'..column..'` IS NOT NULL '

			sqlPreBuild:insert(where)
		end,
	}
	return commands[command](...)
end

local function do_command( self, command, ... )
	local sqlPreBuild = self.sqlPreBuild

	if sqlPreBuild['where'] == nil then
		sqlPreBuild['where'] = array:new()
	end

	pcall(prepareStatementForWhere, command, sqlPreBuild['where'], ...)

	return self
end

local function buildSqlString( table, sqlPreBuild )
	local function whereStr( )
		local whereStr = sqlPreBuild['where'] and ' WHERE '..sqlPreBuild['where']:concat(' AND ') or ""
		return whereStr
	end

	local function buildSqlForInsert( )
		local keys = sqlPreBuild['rows']['keys']
		local keyStr = "("..'`'..keys:concat_keys('`,`')..'`'..")"

        return 'INSERT INTO '..table..keyStr..' VALUES '..sqlPreBuild['rows']['vals']:concat(', ')
	end

	local actions = {
		['select'] = function ( )
			local join = sqlPreBuild['join']
			local tableStr = table
			if join ~= nil then
				for _,v in pairs(join) do
					local table, condition, op = v[1], v[2], v[3]
					tableStr = tableStr .. op .. " JOIN "..table.. " ON "..condition
				end
			end

			local limitStr = sqlPreBuild['limit'] and sqlPreBuild['limit'] or ""
			local orderStr = sqlPreBuild['order'] and sqlPreBuild['order']  or ""
			local groupStr = sqlPreBuild['group'] and sqlPreBuild['group'] or ""
			local havingStr = sqlPreBuild['having'] and sqlPreBuild['having'] or ""
			
			return 'SELECT '..sqlPreBuild['fields'].." FROM "..tableStr..whereStr()..groupStr..havingStr..orderStr..limitStr
		end,
		['insert'] = function(  )

            return buildSqlForInsert()
		end,
		['update'] = function (  )
            return 'UPDATE '..table..' SET '..sqlPreBuild['rows']:concat(', ')..whereStr()
		end,
		['duplicate'] = function (  )
			local keys = sqlPreBuild['rows']['keys']
            local sql = buildSqlForInsert()
			local updates = array:new()

			for k, _ in pairs(keys) do
				updates:insert('`'..k..'` = VALUES(`'..k..'`)')
			end

			return sql..' ON DUPLICATE KEY UPDATE '..updates:concat(', ')
		end,
		['delete'] = function (  )
            return 'DELETE FROM '..table..whereStr()
		end
	}

	return actions[sqlPreBuild['action']]()
end

function _M:new( )
	local instance = {
		table = nil,
		sqlPreBuild = array:new()
	}
	for i=1,#statements do
		local command = statements[i]
		_M[command] = function( self, ... )
			return do_command(self, command, ...)
		end
	end

	return setmetatable(instance, 
	{
		__index = self,
		__tostring = function( self ) 
			
			return buildSqlString(self.table, self.sqlPreBuild)
		end
	})
end

function _M:select( field )
	self.sqlPreBuild['action'] = 'select'
	self.sqlPreBuild['fields'] = field or '*'

	return self
end

function _M:update( table, rows )
	self.sqlPreBuild['action'] = 'update'
	self:rows(rows, 'update')
	self:from(table)

	return self
end

function _M:insert( table, rows )
	self.sqlPreBuild['action'] = 'insert'
	self:rows(rows, 'insert')
	self:from(table)

	return self
end

function _M:duplicate( table, rows )
	self.sqlPreBuild['action'] = 'duplicate'
	self:rows(rows, 'duplicate')
	self:from(table)

	return self
end

function _M:delete( table )
	self.sqlPreBuild['action'] = 'delete'
	self:from(table)

	return self
end

function _M:from( table )
	self.table = table

	return self
end

--[[
 连接表
 
 @param string table 需要连接的表
 @param string condition 连接条件
 @param string op 连接方法(LEFT, RIGHT, INNER)
--]]
function _M:join( table, condition, op )
	local sqlPreBuild = self.sqlPreBuild

	if sqlPreBuild['join'] == nil then
		sqlPreBuild['join'] = array:new()
	end

	sqlPreBuild['join']:insert({table, condition, op or ' INNER '})

	return self
end

--[[
 limit 条件
 
 @param int limit 条数
 @param int offset 偏移值
--]]
function _M:limit( limit, offset )
	local where = ' LIMIT '..(offset or 0)..', '..tonumber(limit)

	self.sqlPreBuild['limit'] = where
	return self
end

--[[
 指定需要写入的栏目及其值

 @param array rows
--]]
function _M:rows( rows, action )
	local values = array:new()
	if action == 'update' then
		escape(rows)
		print_r(rows)
		for k,v in pairs(rows) do
			values:insert('`'..k..'`'.."="..v)
		end
	elseif action == 'insert' or action == 'duplicate' then
		values['vals'] = array:new()
		local rs = array:new(rows)
		if rs:is_array() then
			for _,vals in pairs(rs) do
				escape(vals)
				local val = array:new()
				for k,v in pairs(vals) do
					val:insert(v)
				end
		
				values['vals']:insert("("..val:concat(",")..")")
			end

			local keys = rs[1]
			values['keys'] = array:new(rs[1])
		else
			escape(rs)

			local val = array:new()
			for k,v in pairs(rs) do
				for k,v in pairs(vals) do
					val:insert(v)
				end
			end
			values['keys'] = rs
			values['vals']:insert("("..val:concat(",")..")")
		end
	end
	self.sqlPreBuild['rows'] = values
	return self
end

--[[
 排序顺序(ORDER BY)

 @param string column 排序的索引
 @param string direction 排序的方式(ASC, DESC)
--]]
function _M:order( column, direction )
	direction = direction or 'ASC'

	local order = array:new()
	if type(column) == 'table' then
		for _,v in pairs(column) do
			order.insert('`'..v..'` '..direction)
		end
	else
		order.insert('`'..column..'` '..direction)
	end

	self.sqlPreBuild['order'] = ' ORDER BY '..order.concat(', ')
	return self
end

--[[
 集合聚集(GROUP BY)
 
 @param string $key 聚集的键值
--]]
function _M:group( ... )
	local param = {...}
	local group = array:new(param)

	self.sqlPreBuild['group'] = ' GROUP BY '..group:concat(',')

	return self
end

--[[
 HAVING (HAVING)

--]]
function _M:having( ... )
	local param = {...}
	local group = array:new(param)

	self.sqlPreBuild['having'] = ' HAVING '..group:concat(' AND ')
	return self
end

function _M:sql( )
	return buildSqlString(self.table, self.sqlPreBuild)
end

function _M:clean( )
	self.sqlPreBuild = array:new()
end

return _M