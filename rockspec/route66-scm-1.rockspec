package = "route66"
version = "scm-1"
source = {
	url = "git://github.com/ignacio/route66.git",
	branch = "master"
}
description = {
	summary = "Route66, simple URL routing for LuaNode.",
	detailed = [[
Route66 allows to write simple URL based routing for LuaNode HTTP servers, similar to what Orbit provides (but lacking Sinatra -like routes).
]],
	license = "MIT/X11",
	homepage = "https://github.com/ignacio/route66"
}
dependencies = {
	"lua >= 5.1"
}

build = {
	type = "builtin",
	modules = {
		route66 = "lua/route66.lua"
	}
}
