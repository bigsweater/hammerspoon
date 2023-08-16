--- Watches a folder for changes, and if the changed files or directories fall
--- in a directory in `ignore` or they're in a parent in `ignoreParent`, sets
--- writes the extended attributes on the changed file to instruct Dropbox to
--- ignore the file.
---@class Dropbox
---@field target string The target directory to watch
---@field ignore { [string]: boolean|fun(path: string): boolean }? Files to ignore. These files will be ignored by Dropbox as soon as they're created if their value is true, or the value is a function that returns true. False does nothing.
---@field ignoreParent { [string]: boolean|fun(path: string): boolean }? Same as `ignore`, but instead sets the *parent* of a file to be ignored. Useful for cache indicators in e.g. Rust.
local Dropbox = {}
Dropbox.target = os.getenv('HOME') .. '/Library/CloudStorage/Dropbox/Code'
Dropbox.ignore = {
	['node_modules'] = true,
	['.git'] = true,
	['__pycache__'] = true,
	['.sass-cache'] = true,
	['vendor'] = function(path)
		return Dropbox.isGitIgnored(path)
	end,
}
Dropbox.ignoreParent = {
	['CACHEDIR.TAG'] = true
}

--- Construct a new dropbox directory watcher.
---@param target string? The directory to watch for changes.
---@param ignore { [string]: boolean|fun(path: string): boolean }? Files to ignore. These files will be ignored by Dropbox as soon as they're created if their value is true, or the value is a function that returns true. False does nothing.
---@param ignoreParent { [string]: boolean|fun(path: string): boolean }? Same as `ignore`, but instead sets the *parent* of a file to be ignored. Useful for cache indicators in e.g. Rust.
---@return self
function Dropbox:new(target, ignore, ignoreParent)
	local instance = {}
	setmetatable(instance, self)
	self.__index = self

	instance.target = target or self.target
	instance.ignore = ignore or self.ignore
	instance.ignoreParent = ignoreParent or self.ignoreParent

	return instance
end

function Dropbox:start()
	Dropbox.watcher = hs.pathwatcher.new(
		self.target,
		function(paths, flagTables)
			self:changeHandler(paths, flagTables)
		end
	):start()

	return self
end

function Dropbox:changeHandler(paths, flagTables)
	local function shouldHandleChange(changes, localPath)
		return Dropbox.fileExists(localPath)
			and (changes['itemCreated'] or changes['itemRenamed'])
			and not changes['itemXattrMod']
	end

	for i, path in ipairs(paths) do
		local changes = flagTables[i]

		if shouldHandleChange(changes, path) then
			local ignoreFile, ignoreParent = self:shouldBeIgnored(path)

			if ignoreFile then
				hs.fs.xattr.set(path, 'com.apple.fileprovider.ignore#P', '1')
			end

			if ignoreParent then
				hs.fs.xattr.set(Dropbox.getParent(path), 'com.apple.fileprovider.ignore#P', '1')
			end
		end
	end
end

---@param path string File to check against the `ignore` and `ignoreParent` instance tables.
---@return boolean ignoreFile, boolean ignoreParent True if file should be ignored by Dropbox; false if not.
function Dropbox:shouldBeIgnored(path)
	local ignore = {}
	local file = self.ignore[hs.fs.displayName(path)] or false
	local parent = self.ignoreParent[hs.fs.displayName(path)] or false

	if type(file) == 'function' then
		ignore.file = file(path)
	else
		ignore.file = file
	end

	if type(parent) == 'function' then
		ignore.parent = parent(path)
	else
		ignore.parent = parent
	end

	return ignore.file, ignore.parent
end

--- Checks if a file exists at a given path. Uses hs.fs.displayName, which
--- simply returns `nil` if a file does not exist, rather than erroring.
--- @param path string
--- @return boolean exists
function Dropbox.fileExists(path)
	return not not hs.fs.displayName(path)
end

--- Runs `git status` inside a file (or its parent) to determine if the path
--- is in a git repository. `git status` errors if no repo is found in the
--- directory tree.
---@param path string The path to check.
---@return boolean isInGitRepo
function Dropbox.isInGitRepo(path)
	local _, status = hs.execute(string.format(
		[[ /usr/bin/env git -C %q status --porcelain > /dev/null 2>&1 ]],
		Dropbox.getContext(path)
	))

	return status or false
end

--- Runs `git check-ginroe` inside a file (or its parent) to determine if the path
--- inside the directory or the parent of the file. Returns true if the file is
--- gitignored. Should return false if file is not in git repo.
--- @param path string The path to check.
--- @return boolean ignored True of the file is ignored; false if not.
function Dropbox.isGitIgnored(path)
	local _, status = hs.execute(string.format(
		[[ /usr/bin/env git -C %q check-ignore -q %q > /dev/null 2>&1 ]],
		Dropbox.getContext(path), path
	))

	return status or false
end

---@param path string Path to a file.
---@return string path The path if it is a directory, or its parent if not.
function Dropbox.getContext(path)
	if Dropbox.isDirectory(path) then
		return path
	end

	return Dropbox.getParent(path)
end

---@param path string Path for which to get parent.
---@return string parent The parent of the given path.
function Dropbox.getParent(path)
	-- Path string up to the last forward slash
	return string.match(path, '^(.+)/')
end

---@param path string The path to check.
---@return boolean isDirectory True if the file is a directory; false if not.
function Dropbox.isDirectory(path)
	return hs.fs.attributes(path, 'mode') == 'directory'
end

return Dropbox
