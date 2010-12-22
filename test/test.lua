local Http = require "luanode.http"
local Url = require "luanode.url"
local Fs = require "luanode.fs"

local router = require "route66".new()

router:get("/hello/(.+)", function(req, res, word)
	res:writeHead(200, { ["Content-Type"] = "text/plain"})
	res:finish("received " .. word)
end)

router:get("hola", "que", "tal", function(req, res)
end)

router:post("/postit", function(req, res)
	assert(req.body == "0123456789")
	res:writeHead(200, { ["Content-Type"] = "text/plain"})
	res:finish(req.body)
end)


local server = Http.createServer(function (self, req, res)
	print("hi")
end)

router:bindServer(server)


server:on("listening", function()
	
	local client = Http.createClient(8000)
	local req = client:request("/hello/world", {Accept = "*/*", Foo = "bar"})
	req:finish()
	req:addListener('response', function (self, res)
		assert(200 == res.statusCode)
		
		console.log("Got /hello response")
		
		local req2 = client:request("POST", "/postit", {Accept = "*/*", Foo = "bar", ["Content-Length"] = 10})
		req2:finish("0123456789")
		req2:addListener('response', function (self, res)
			assert(200 == res.statusCode)
			server:close()
		end)
	end)
end)

server:listen(8000)

process:loop()