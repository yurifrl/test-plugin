--!strict

tern.log.info("bar: loaded from", tern.plugin.dir)

tern.command({
	id = "greet",
	title = "Bar: Greet",
	icon = "sparkle",
	run = function(cx)
		cx:toast("info", "Bar is installed", "Bundled with Test Plugin, installed on its own.")
	end,
})
