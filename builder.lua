local dec do
	local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	
	function dec(data)
	    data = string.gsub(data, '[^'..b..'=]', '')
	    return (data:gsub('.', function(x)
	        if (x == '=') then return '' end
	        local r,f='',(b:find(x)-1)
	        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
	        return r;
	    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
	        if (#x ~= 8) then return '' end
	        local c=0
	        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
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
	
	function build(overwrite)
		if rs:FindFirstChild("CatFramework") and overwrite then
			rs.CatFramework:Destroy()
		end
		local frame = Instance.new("Folder",rs)
		frame.Name = "CatFramework"
		
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
	end
end

build(true)
