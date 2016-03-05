--[[
	INSTRUCTIONS
	
	New users: To insert the cat framework into your game, copy and paste this entire script into the commandbar.
	More in-depth instructions are given in the README file, which will be in the inserted model or on this repo.
	
	To update the framework (which I recommend doing periodically), copy and paste! If you wish to keep the older version
	(for whatever reason), change the first argument for the line that calls the build() function to false. Your old version
	will be left in ReplicatedStorage, and a new one will pop up as well.

	To repair the framework (and it's on the current version), for reasons such as screwing around with stuff you should not be screwing around with, change
	BOTH of the arguments to false. There is a simple caching system to prevent sending lots of requests in a short amount of time. The broken
	version will also be destroyed.





]]

local b4 = game.HttpService.HttpEnabled
game.HttpService.HttpEnabled = true

local dec do --found this function somewhere
	local b="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	
	function dec(data)
	    data = string.gsub(data,"[^"..b.."=]", "")
	    return (data:gsub(".", function(x)
	        if (x == "=") then return "" end
	        local r,f="",(b:find(x)-1)
	        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and "1" or "0") end
	        return r;
	    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
	        if (#x ~= 8) then return "" end
	        local c=0
	        for i=1,8 do c=c+(x:sub(i,i)=="1" and 2^(8-i) or 0) end
	        return string.char(c)
	    end))
	end
end



local truncated

local build do
	local link = "https://api.github.com/repos/ray-revenge/cat_framework/git/trees/master"
	local http = game:GetService("HttpService")
	
	local function getTree(link)
		return http:JSONDecode(http:GetAsync(link)).tree
	end
	
	local data = http:JSONDecode(http:GetAsync(link))
	local tree = data.tree
	truncated = data.truncated
	
	local rs = game:GetService("ReplicatedStorage")
	
	local function ct(an,sub)
		if not an or not sub then return end
		local f = Instance.new("Folder",an)
		f.Name = sub.path
		local newt = getTree(sub.url)
		ct(f,newt)
	end
	
	function build(overwrite,versioncache)
		local old = rs:FindFirstChild("CatFramework")
		if old and versioncache then
			local osha = old.Info.Source:match("SHA1:(%w+)")
			if osha == data.sha then
				warn("Version is up to date, did not overwrite current")
				return
			end
		end
		if old and overwrite then
			old:Destroy()
		end
		local frame = Instance.new("Folder",rs)
		frame.Name = "CatFramework"

		local infofile = Instance.new("Script",frame)
		infofile.Name = "Info"
		infofile.Disabled = true
		infofile.Source = [[

			information file, do not delete this

		]] .. "SHA1:"..data.sha
		
		for i = 1,#tree do
			local f = tree[i]
			if f.path == "README.md" then
				local readme = Instance.new("Script",frame)
				readme.Disabled = true
				readme.Name = "README"
				readme.Source = "--[[\n"..dec(http:JSONDecode(http:GetAsync(f.url)).content).."\n]]"
			elseif f.path == "source" then
				local t = getTree(f.url)
				for it = 1,#t do
					local cur = t[it]
					if cur.type == "tree" then
						ct(frame,cur)
					elseif cur.type == "blob" then
						for i,v in next, cur do
							print(i,v)
						end
						local src = dec(http:JSONDecode(http:GetAsync(cur.url)).content)
						local type = src:match("^%-%-(%a+)\n")
						assert(type=="ModuleScript"or type=="Script"or type=="LocalScript","Invalid source type")
						local file = Instance.new(type)
						file.Name = cur.path:gsub(".lua","")
						file.Source = src

						if cur.path == "main.lua" then
							file.Parent = frame
						else
							coroutine.wrap(function() file.Parent = frame:WaitForChild("main") end)()
						end
					end
				end
			end
		end

		http.HttpEnabled = b4
	end
end

build(true,true) -- first arg is overwrite old version, second arg is cache the version
