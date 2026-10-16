local FileName = "NameFileHere"
local Container = game:GetService("StarterGui")

local RunService=cloneref and cloneref(game:GetService("RunService")) or game:GetService("RunService")

local Children = Container:GetChildren()
local Lines = {}

print("[" .. FileName .. "] Starting")
for i, line in ipairs(Children) do
	if line:IsA("GuiObject") then
		local label = nil
		for _, layer in ipairs(line:GetChildren()) do 
			if layer:IsA("TextLabel") and layer.Name=="Label" then 
				label = layer 
				break 
			end 
		end
		RunService.Stepped:Wait()
		if label then
			table.insert(Lines, {
				Tier = line.Position.Y.Offset,
				Text = label.Text
			})
		end
	end
end

print("[" .. FileName .. "] Sorting")
table.clear(Children)
table.sort(Lines, function(a, b)
	return a.Tier < b.Tier
end)

print("[" .. FileName .. "] Creating")
local step = 0
local s = ""
for i, line in ipairs(Lines) do
	s = s .. line.Text .. "\n"
	step=step+1
	if i%30==0 then print("[" .. FileName .. "] Still copy text step:", step) end
	RunService.Stepped:Wait()
end

if writefile then
	writefile("Instal/".. FileName, s)
	print("[" .. FileName .. "] Successfully copied to file!")
else
	print("[" .. FileName .. "] Failed copy to file because writefile function is missing")
end
table.clear(Lines)

