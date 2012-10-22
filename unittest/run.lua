package.path = [[C:\LuaRocks\1.0\lua\?.lua;C:\LuaRocks\1.0\lua\?\init.lua;]] .. package.path

require "luarocks.require"

local Runner = require "siteswap.runner"
local Test = require "siteswap.test"

local event_emitter = require "luanode.event_emitter"

local route66 = require "route66"

local runner = Runner()

local router = route66.new()

--
-- The router to be used in the tests
--
router:get("/hello/(.+)", function(req, res, word)
	res:writeHead(200, { ["Content-Type"] = "text/plain"})
	res:finish("received " .. word)
end)

router:get("hola", "que", "tal", function(req, res)
end)

router:post("/postit", function(req, res)
	res:writeHead(200, { ["Content-Type"] = "text/plain"})
	res:finish(req.body)
end)


--
-- A fake webserver
--
local server = event_emitter()
server:on("request", function(self, req, res)
	router.not_found(req, res)
end)

router:bindServer(server)


--
-- Fake requests and responses
--
local request_mt = {}
request_mt.__index = request_mt

function request_mt:finish (data)
	if data then
		table.insert(self.body, data)
	end
	self.body = table.concat(self.body)
end

local function make_request ()
	return setmetatable({
		body = {}
	}, request_mt)
end

local response_mt = {}
response_mt.__index = response_mt

function response_mt:writeHead (status, headers)
	self.status = status
	self.headers = headers
end

function response_mt:finish (data)
	if data then
		table.insert(self.body, data)
	end
	self.body = table.concat(self.body)
end

local function make_response ()
	return setmetatable({
		body = {}
	}, response_mt)
end





---
-- Valid GET. Must reply 200.
--
runner:AddTest("GET", function(test)
	local req, res = make_request(), make_response()

	req.url = "/hello/world"
	req.method = "get"
	req.headers = {Accept = "*/*", Foo = "bar"}

	server:emit("request", req, res)

	test:assert_equal(200, res.status)
	test:assert_equal("received world", res.body)

	test:Done()
end)

---
-- GET not found. Must reply 404.
--
runner:AddTest("GET not found", function(test)

	local req, res = make_request(), make_response()

	req.url = "/not_found"
	req.method = "get"
	req.headers = {Accept = "*/*"}

	server:emit("request", req, res)

	test:assert_equal(404, res.status)
	test:assert_equal("Not Found\n", res.body)

	test:Done()

end)

---
-- Valid POST. Must reply 200.
--
runner:AddTest("POST", function(test)

	local req, res = make_request(), make_response()

	req.url = "/postit"
	req.method = "post"
	req.headers = {Accept = "*/*", Foo = "bar", ["Content-Length"] = 10}
	req:finish("0123456789")

	server:emit("request", req, res)

	test:assert_equal(200, res.status)
	test:assert_equal("0123456789", res.body)

	test:Done()
end)

---
-- A request is performed and there is no handler for it.
-- We use a HEAD request for the simple reason we didn't register any handlers for it.
--
runner:AddTest("Method with no handler", function(test)
	local req, res = make_request(), make_response()

	req.url = "/hello/world"
	req.method = "head"
	req.headers = {Accept = "*/*", Foo = "bar"}

	server:emit("request", req, res)

	test:assert_equal(405, res.status)
	test:Done()
end)

---
-- Checks that when the method is allowed (there are handlers for it) but no pattern
-- matches, a 404 is returned.
--
runner:AddTest("Allowed method but no match", function(test)
	local req, res = make_request(), make_response()

	req.url = "/foo"
	req.method = "get"
	req.headers = {Accept = "*/*", Foo = "bar"}

	server:emit("request", req, res)

	test:assert_equal(404, res.status)
	test:Done()
end)

---
-- Unknown method. Must reply 405.
--
runner:AddTest("Unknown method", function(test)

	local req, res = make_request(), make_response()

	req.url = "/who_cares"
	req.method = "unknown_method"
	req.headers = {Accept = "*/*"}

	server:emit("request", req, res)

	test:assert_equal(405, res.status)

	test:Done()

end)

runner:Run()

process:loop()
