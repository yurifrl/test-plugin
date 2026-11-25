--!strict

tern.log.info("foo: loaded from", tern.plugin.dir)

tern.command({
	id = "greet",
	title = "Foo: Greet",
	icon = "sparkle",
	run = function(cx)
		cx:toast("info", "Foo is installed", "Bundled with Test Plugin, installed on its own.")
	end,
})
