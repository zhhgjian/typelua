--------------------------------------------------------------------------------
-- mysql.lua, v0.0.1: basic db mysql creator
-- Copyright (c) 2016 zhhgjian <zhhgjian@126.com>
-- License: MIT
-- https://github.com/zhhgjian/typelua
--------------------------------------------------------------------------------
local mysql = require("resty.mysql")

local _M = {}
_M._VERSION = '0.01'

function _M:new( options )
	local instance = {
		options = options,
	}
	
	setmetatable(instance, { __index = self })

	return instance
end

function _M:connect()
    local options = self.options

    local timeout = (options and options.timeout) or 1000
    local charset = (options and options.charset) or 'utf8'
    local db, err = mysql.new()
    if not db then
        error('mysql new error')
    end

    db:set_timeout(timeout)

    local ok, err, errno, sqlstate = db:connect(options)

    if not ok then
        error(err)
    end

    db:query("SET NAMES "..charset)

    self.db = db
end

function _M:keepalive()
	local options = self.options
	local ok, err = self.db:set_keepalive(options.pool_timeout, options.pool_size)
    if not ok then
        ngx.log(ngx.ERR, "bad set_keepalive: ", err, ": ")
        self.db:close()
    end
    self.db = nil
end

function _M:execute(sql)
    local qres, qerr, qerrno, qsqlstate = self.db:query(sql)
    if not qres then
        ngx.log(ngx.ERR, "bad result: ", qerr, ": ", qerrno, ": ", qsqlstate, ".")
    end
    return qres, qerr
end

function _M:exec(sql)

    self:connect()
    
    local qres, qerr = self:execute(sql)

    self:keepalive()
    
    return qres, qerr
end

function _M:begin()
    self:connect()
    return self:execute('START TRANSACTION')
end

function _M:commit()
    local res = self:execute('COMMIT')
    self:keepalive()
    return res
end

function _M:rollback()
    local res = self:execute('ROLLBACK')
    self:keepalive()
    return res
end

function _M:close()
    if self.db then
        self.db.close()
    end
end

return _M

