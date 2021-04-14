local function read_from_file(filename)
    local file = io.open(filename, "r")
    local config = file:read("*all")
    file:close()
    local yaml = require('yaml')
    local z = yaml.decode(config)
    return z
end

local conf = read_from_file('config.yaml')
local proxy = conf['proxy']

port = proxy['port']
new_host = proxy['bypass']['host']
new_port = proxy['bypass']['port']

local function redirect(req)
    local path = req:path()
    local new_path = string.format('%s:%s%s', new_host, new_port, path)
    local query = req:query()
    if query ~= "" then new_path = new_path .. string.format('?%s', query) end

    local http_client = require('http.client').new()
    return http_client:request(req:method(), new_path)
end

router = require('http.router').new()
router:route({method = 'ANY', path = '/'}, redirect)
router:route({method = 'ANY', path = '.*'}, redirect)

local server = require('http.server').new('localhost', port)
server:set_router(router)
server:start()

local function hello(req) return {status = 200, body = 'hello'} end
local function foo(req) return {status = 200, body = 'foo'} end
local function bar(req) return {status = 200, body = 'bar'} end
local function anyother(req) return {status = 200, body = 'anyother'} end

other_router = require('http.router').new()
other_router:route({method = 'ANY', path = '/'}, hello)
other_router:route({method = 'ANY', path = '/foo'}, foo)
other_router:route({method = 'ANY', path = '/bar'}, bar)
other_router:route({method = 'ANY', path = '.*'}, anyother)

local other_server = require('http.server').new('localhost', new_port)
other_server:set_router(other_router)
other_server:start()