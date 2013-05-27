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

By default, *post* and *put* handlers will be called when all data has been received. If you need full control, you can 
add a raw handler:

```lua

router:raw_post("/send_code", function(req, res)
	res:writeHead(200, { ["Content-Type"] = "text/plain"})

	req._incoming_data = {}
	req:on("data", function(_, data)
		table.insert(req._incoming_data, data)
	end)

	req:on("end", function()
		req.body = table.concat(req._incoming_data)
		if req.body == "4 8 15 16 23 42" then
			res:finish(">:")
		else
			res:finish("boom!")
		end
	end)
end)
```


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
 - options
 - propfind
 - proppatch
 - mkcol
 - copy
 - move
 - lock
 - unlock
 - patch
 - version-control
 - report
 - checkout
 - checkin
 - uncheckout
 - mkworkspace
 - update
 - label
 - merge
 - baseline-control
 - mkactivity

Once you have defined your routes, you need to bind the router with a HTTP server:

    bindServer(server)

If there is no handler for the method of a given request, the router replies with "405 Method not allowed".

It there is a handler for the given method, but no matching pattern is found, a "request" event is emitted, just like in
 a vanilla server.

### Full example #

A full example is available [here](https://gist.github.com/751528).
<script src="https://gist.github.com/751528.js"> </script>

### Tests #

If you want to run the test suite, you'll need to install [siteswap][5]. After doing that, just do:

```bash
luanode unittest/run.lua
````

## Acknowledgments #
I'd like to acknowledge the work of the following people:

 - Fabio Mascarenhas, for his work on [Orbit][2], who served as a base for this.

 
## License #
**Route66** is available under the MIT license.


[1]: https://github.com/ignacio/luanode/
[2]: http://keplerproject.github.com/orbit/
[3]: http://www.sinatrarb.com/
[4]: http://www.luarocks.org/
[5]: https://github.com/ignacio/siteswap/
