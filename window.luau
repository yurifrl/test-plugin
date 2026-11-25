--!strict
-- Test Plugin: the bundle root.
--
-- `tern plugin install DIR` copies exactly one package, and Tern's loader reads
-- only the plugins folder's direct children, so a package cannot declare the
-- plugins it ships as dependencies. This root installs them itself: on every
-- load it asks the CLI where the plugins folder is, installs at most one
-- missing bundled plugin, and the reload that install triggers starts the next
-- pass. Each pass re-reads the disk, so a reload that interrupts a pass simply
-- resumes it, and removing foo or bar reinstalls it on the next reload.
--
-- The bundled plugins are also installable one by one:
--   tern plugin install github.com/OWNER/test-plugin/foo   (or .../bar)

local BUNDLED: { string } = { "foo", "bar" }

local function tern_bin(): string
	local override = tern.getenv("TERN_EXE")
	if override and override ~= "" then
		return override
	end
	local path = (tern.getenv("HOME") or "") .. "/.local/bin/tern"
	return if tern.fs.exists(path) then path else "tern"
end

local function present(plugins_dir: string, name: string): boolean
	return tern.fs.exists(plugins_dir .. "/" .. name .. "/plugin.toml")
		or tern.fs.exists(plugins_dir .. "/" .. name .. ".path")
end

local function install(name: string)
	local source = tern.plugin.dir .. "/" .. name
	tern.log.info("test-plugin: installing bundled plugin", name, "from", source)
	tern.process.run({ tern_bin(), "plugin", "install", source }, { timeout_ms = 60000 }, function(result, cx)
		if result.status == 0 then
			tern.log.info("test-plugin: installed", name, result.stdout)
		else
			tern.log.error("test-plugin: installing", name, "failed", result.status, result.stderr)
			if cx then
				cx:toast("error", "Test Plugin could not install " .. name, result.stderr)
			end
		end
	end)
end

local function check()
	tern.process.run({ tern_bin(), "plugin", "dir" }, { timeout_ms = 10000 }, function(result, cx)
		if result.status ~= 0 then
			tern.log.error("test-plugin: tern plugin dir failed", result.status, result.stderr)
			return
		end
		local plugins_dir = (string.gsub(result.stdout, "%s+$", ""))
		for _, name in BUNDLED do
			if not present(plugins_dir, name) then
				install(name)
				return
			end
		end
		tern.log.debug("test-plugin: bundled plugins present")
	end)
end

-- On load, not window_start: window_start runs only once per window, so it
-- would not run again after the install's reload.
check()

tern.command({
	id = "status",
	title = "Test Plugin: Bundle status",
	icon = "puzzle",
	run = function(cx)
		tern.process.run({ tern_bin(), "plugin", "dir" }, { timeout_ms = 10000 }, function(result)
			if result.status ~= 0 then
				cx:toast("error", "Test Plugin: tern plugin dir failed", result.stderr)
				return
			end
			local plugins_dir = (string.gsub(result.stdout, "%s+$", ""))
			local missing: { string } = {}
			for _, name in BUNDLED do
				if not present(plugins_dir, name) then
					table.insert(missing, name)
				end
			end
			if #missing == 0 then
				cx:toast("info", "Test Plugin bundle intact", "foo and bar are installed.")
			else
				cx:toast("warn", "Test Plugin is installing " .. table.concat(missing, ", "))
			end
		end)
	end,
})
