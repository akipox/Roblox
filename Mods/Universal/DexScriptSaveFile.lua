local FileName = "NameFileHere"
local Cntainer = script:QueryDescendants("")



local RunService = game:GetService("RunService")
local Lines = Cntainer:GetChildren()

table.sort(Lines, function(a, b)
	if a:IsA("GuiObject") and b:IsA("GuiObject") then
		return a.Position.Y.Offset < b.Position.Y.Offset
	end
	return false
end)

local step, rngStep = 0, math.random(30,50)
local s = ""

for i, line in ipairs(Lines) do
	local label = nil
	for _, child in ipairs(line:GetChildren()) do if child:IsA("TextLabel") and child.Name=="Label" then label = child break end end
	if label then
		s = s .. label.Text .. "\n"
		step=(step+1)%rngStep
		if step==0 then rngStep=math.random(30,50) print("[" .. FileName .. "] Still copy text step:",step) end
	end
	RunService.RenderStepped:Wait()
end

writefile("Instal/".. FileName, s)
