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
local pairs = pairs

module((...))

-- can set this to true to enable for all connections
debug_mode = false

local router_methods = {}
router_methods.__index = router_methods

local accepted_methods = {}
for _, method in ipairs{
	-- http://tools.ietf.org/html/rfc2616
	"options", "get", "head", "post", "put", "delete", "trace", "connect",
	-- http://tools.ietf.org/html/rfc2518
	"propfind", "proppatch", "mkcol", "copy", "move", "lock", "unlock",
	-- http://tools.ietf.org/html/rfc5789
	"patch",
	-- http://tools.ietf.org/html/rfc3253
	"version-control", "report", "checkout", "checkin", "uncheckout", "mkworkspace", "update",
	"label", "merge", "baseline-control", "mkactivity"
}
do
	accepted_methods[method] = true
end

---
-- Creates a new router. Its http method dispatch will be populated on demand.
--
function new()
	local r = { dispatch_table = {} }
	return setmetatable(r, router_methods)
end

--
--
local function add_handler(router, method, ...)
	local n = select("#", ...)
	assert(n >= 2, "you must supply a handler")
	
	local handler = select(n, ...)
	assert(type(handler) == "function", "you must supply a handler")
	
	assert(accepted_methods[method], "unknown http method " .. method)
	local t = router.dispatch_table[method]
	if not t then
		t = {}
		router.dispatch_table[method] = t
	end

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

---
-- Add a function for each http method allowed
--
for method in pairs(accepted_methods) do
	router_methods[method] = function(self, ...)
		add_handler(self, method, ...)
	end
end

--
--
local function dispatcher(router, method, path)
	local dispatch_entries = router.dispatch_table[method]
	if not dispatch_entries or #dispatch_entries == 0 then
		return nil, "method_not_allowed"
	end

	for _, entry in ipairs(dispatch_entries) do
		local captures
		if type(entry.pattern) == "string" then
			captures = { string.match(path, entry.pattern) }
		else
			captures = { entry.pattern:match(path) }
		end
		if #captures > 0 then
			for i = 1, #captures do
				if type(captures[i]) == "string" then
					captures[i] = QueryString.url_decode(captures[i])
				end
			end
			return entry.handler, captures
		end
	end

	return nil, "no_match_found"
end

---
-- Checks if there is a route for the given request.
-- If the request is handled, returns true.
--
function router_methods:dispatch(server, req, res)
	local uri = Url.parse(req.url)
	local pathname = uri.pathname
	
	if not pathname then
		if debug_mode then
			console.error("route66.dispatch: Malformed url '%s'", req.url)
		end
		res:writeHead(400, { ["Content-Type"] = "text/plain" })
		res:finish("Bad request")
		return true
	end
	
	local handler, captures = dispatcher(self, req.method:lower(), pathname)
	if debug_mode then
		console.debug("method: '%s', path: '%s', handler: '%s'", req.method, pathname, handler)
	end

	if not handler then
		if captures == "method_not_allowed" then
			res:writeHead(405, { ["Content-Type"] = "text/plain" })
			res:finish( ("Method '%s' is not allowed"):format(req.method) )
			return true
		end
		return false
	end
	
	captures = captures or {}
	
	if req.method == "POST" or req.method == "PUT" then
		req._incoming_data = {}
		req:on("data", function (self, data)
			req._incoming_data[#req._incoming_data + 1] = data
		end)
		req:on("end", function()
			req.body = table.concat(req._incoming_data)
			req._incoming_data = nil
			handler(req, res, unpack(captures))
		end)
	else
		handler(req, res, unpack(captures))
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
