# Route66 #

Simple URL routing for [LuaNode][1].

**Route66** allows to write simple URL based routing for LuaNode HTTP servers, similar to what [Orbit][2] provides 
(but lacking [Sinatra][3] -like routes).

```lua
local router = require "route66".new()

router:get("/prompt", function(req, res)
	res:writeHead(200, { ["Content-Type"] = "text/plain"})
	res:finish(">:")
end)

router:get("/hello/(.+)", function(req, res, user)
	res:writeHead(200, { ["Content-Type"] = "text/plain"})
	res:finish("hello " .. user)
end)

router:post("/send_code", function(req, res)
	res:writeHead(200, { ["Content-Type"] = "text/plain"})
	if req.body == "4 8 15 16 23 42" then
		res:finish(">:")
	else
		res:finish("boom!")
	end
end)
```

By means of Lua's pattern matching abilities, you can define urls and capture parts of it, so they will be passed to 
your handler function. Each handler gets the request and the response, plus any additional arguments that may have been 
captured.

## Installation #
**Route66** is installable with [LuaRocks][4].

```bash
luarocks install http://github.com/ignacio/route66/raw/master/rockspecs/route66-scm-1.rockspec
```

## Documentation #
The available methods are:

 - get
 - post
 - put
 - delete
 - head

Once you have defined your routes, you need to bind the router with a HTTP server:

    bindServer(server)

### Full example #

A full example is available [here](https://gist.github.com/751528).
<script src="https://gist.github.com/751528.js"> </script>

## Acknowledgments #
I'd like to acknowledge the work of the following people:

 - Fabio Mascarenhas, for his work on [Orbit][2], who served as a base for this.

 
## License #
**Route66** is available under the MIT license.


[1]: https://github.com/ignacio/luanode/
[2]: http://keplerproject.github.com/orbit/
[3]: http://www.sinatrarb.com/
[4]: http://www.luarocks.org/
