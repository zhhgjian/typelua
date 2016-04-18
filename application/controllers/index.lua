local IndexController = {}
local user_service = require 'models.service.user'
local statement = require('library.db.statement'):new('user')

statement:where('userid=1'):where({usertype=1, type = "dfdsf'sd"}):duplicate('user', {{usertype=1, type = "dfdsf'sd"},{usertype=1, type = "dfdsf'sd"}})
print_r(tostring(statement))

function IndexController:index()
    local view = self:getView()
    local p = {}

    -- statement.where('userid = 1')


    p['vanilla'] = 'Welcome To Vanilla...' .. user_service:get()
    p['zhoujing'] = 'Power by Openresty'
    view:assign(p)
    return view:display()
end

-- curl http://localhost:9110/get?ok=yes
function IndexController:get()
    local get = self:getRequest():getParams()
    print_r(get)
    do return 'get' end
end

-- curl -X POST http://localhost:9110/post -d '{"ok"="yes"}'
function IndexController:post()
    local _, post = self:getRequest():getParams()
    print_r(post)
    do return 'post' end
end

-- curl -H 'accept: application/vnd.YOUR_APP_NAME.v1.json' http://localhost:9110/api?ok=yes
function IndexController:api_get()
    local api_get = self:getRequest():getParams()
    print_r(api_get)
    do return 'api_get' end
end

return IndexController
