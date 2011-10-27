local Url = require "luanode.url"
local QueryString = require "luanode.querystring"
local setmetatable = setmetatable
local assert = assert
local type = type
local select = select
local console = console
local table = table
local string = string
local unpack = unpack
local ipairs = ipairs

module((...))

local router_methods = {}
router_methods.__index = router_methods

function new()
	local r = {
		dispatch_table = {
			get = {},
			post = {},
			put = {},
			delete = {},
			head = {},
			options = {}
		}
	}
	return setmetatable(r, router_methods)
end

--
--
local function add_handler(router, method, ...)
	local n = select("#", ...)
	assert(n >= 2, "you must supply a handler")
	
	local handler = select(n, ...)
	assert(type(handler) == "function", "you must supply a handler")
	
	local t = router.dispatch_table[method]
	assert(t, "unknown http method " .. method)

	for i = 1, n - 1 do
		local url = select(i, ...)
		t[#t + 1] = {
			pattern = "^" .. url .. "$",
			handler = handler
		}
	end
end

--
--
function router_methods.not_found(req, res)
	local NOT_FOUND = "Not Found\n"
	res:writeHead(404, { ["Content-Type"] = "text/plain", ["Content-Length"] = #NOT_FOUND })
	res:finish(NOT_FOUND)
end

function router_methods:get(...)
	add_handler(self, "get", ...)
end

function router_methods:post(...)
	add_handler(self, "post", ...)
end

function router_methods:put(...)
	add_handler(self, "put", ...)
end

function router_methods:delete(...)
	add_handler(self, "delete", ...)
end

function router_methods:head(...)
	add_handler(self, "head", ...)
end

function router_methods:options(...)
	add_handler(self, "options", ...)
end

--
--
local function dispatcher(router, method, path, index)
	index = index or 0
	if #router.dispatch_table[method] == 0 then
		return nil
	else
		for index = index + 1, #router.dispatch_table[method] do
		local item = router.dispatch_table[method][index]
			local captures
			if type(item.pattern) == "string" then
				captures = { string.match(path, item.pattern) }
			else
				captures = { item.pattern:match(path) }
			end
			if #captures > 0 then
				for i = 1, #captures do
					if type(captures[i]) == "string" then
						captures[i] = QueryString.url_decode(captures[i])
					end
				end
				return item.handler, captures, index
			end
		end
	end
end

--
--
function router_methods:dispatch(server, req, res)
	local uri = Url.parse(req.url)
	local pathname = uri.pathname
	
	if not pathname then
		console.error("route66.dispatch: Malformed url %q", req.url)
		res:writeHead(400, { ["Content-Type"] = "text/plain" })
		res:finish("Bad request")
		return false
	end
	
	local handler, captures, index = dispatcher(self, req.method:lower(), pathname)
	captures = captures or {}
	
	console.debug("method: '%s', path: '%s', handler: '%s'", req.method, pathname, handler)
	if not handler then
		return false
	end
	
	local result
	
	if req.method == "POST" or req.method == "PUT" then
		req._incoming_data = {}
		req:on("data", function (self, data)
			req._incoming_data[#req._incoming_data + 1] = data
		end)
		req:on("end", function()
			req.body = table.concat(req._incoming_data)
			req._incoming_data = nil
			result = handler(req, res, unpack(captures))
		end)
	else
		result = handler(req, res, unpack(captures))
	end
	if type(result) == "boolean" then
		return result
	end
	return true
end


--
--
function router_methods:bindServer(server)
	local router = self
	router._server = server
	
	local listeners = server:listeners('request')
	server:removeAllListeners('request')
	
	server:on('request', function(self, req, res)
		if router:dispatch(self, req, res) then
			return
		end
		for k,v in ipairs(listeners) do
			v(self, req, res)
		end
	end)
end
