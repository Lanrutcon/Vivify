local Addon = CreateFrame("FRAME");

---TODO
--add support to Runes, ComboPoints (maybe), Soul Shards, HolyPower


--not a frame, but a table where is stored the hp and power bar (mana, energy, rage or runic power)
local playerFrame, playerDropMenu = {};

--HP Bar won't flow from both sides anymore
--[[
local function getCenteredPosition(currentHP, maxHP)
	local x = currentHP*260/maxHP;

	return (260-x)/2;
end
--]]

local powerColor = {
	[0] = {r = 0.3, g = 0.3, b = 1},
	[1] = {r = 1, g = 0, b = 0},
	[2] = {r = 1, g = 0.5, b = 0.25},
	[3] = {r = 1, g = 1, b = 0},
	[6] = {r = 0, g = 0.82, b = 1}
}


local function createFontFrame(name, parent, posX, posY, onClick)
	local fontFrame = CreateFrame("FRAME", "VivifyPlayerDropMenu" .. name, parent);
	fontFrame:SetSize(100,20);
	fontFrame:SetPoint("BOTTOM", posX, posY);

	fontFrame.font = fontFrame:CreateFontString("Vivify" .. name .. "Font", "OVERLAY", "GameFontNormal");
	fontFrame.font:SetFont("Interface\\AddOns\\Rising\\Futura-Condensed-Normal.TTF", 18, "OUTLINE");
	fontFrame.font:SetTextColor(0.5, 0.5, 0.5, 1);
	fontFrame.font:SetText(name);
	fontFrame.font:SetPoint("CENTER", 0, 0);

	fontFrame:SetScript("OnEnter", function(self)
		self.font:SetTextColor(1, 1, 1, 1);
	end);
	fontFrame:SetScript("OnLeave", function(self)
		self.font:SetTextColor(0.5, 0.5, 0.5, 1);
	end);
	fontFrame:SetScript("OnMouseDown", function()
		onClick();
		playerDropMenu:Hide();
	end);

	return fontFrame;
end

local function togglePlayerDropDownMenu()
	if(playerDropMenu:IsShown()) then
		playerDropMenu:Hide();
	else
		playerDropMenu:Show();
	end
end


local function setUpOptions(optionsTable)
	
	for key, option in ipairs(playerDropMenu) do
		if(optionsTable and optionsTable[key]) then
			option.font:SetText(optionsTable[key][1]);
			option:SetScript("OnMouseDown", function()
				optionsTable[key][2]();
				playerDropMenu:Hide();
			end);
			option:SetPoint("BOTTOM", playerDropMenu, 0, (key-1)*20);
			option:Show();
		else
			option:Hide();
		end
	end
	
end


local function playerDropMenu_OnEvent()
	
	local options = {};
	--IsInRaid
	if(GetRaidRosterInfo(1)) then
		if(IsRaidLeader()) then	
			table.insert(options, { "Convert To Party", function() ConvertToParty() end } );
			table.insert(options, { "Reset All Instances", function() ResetInstances() end } );
		end
		table.insert(options, { "Leave Raid", function() LeaveParty() end } );
	elseif(GetNumPartyMembers() > 0) then
		if(IsRaidLeader()) then
			table.insert(options, { "Convert To Raid", function() ConvertToRaid() end } );
			table.insert(options, { "Reset All Instances", function() ResetInstances() end } );
		end
		table.insert(options, { "Leave Party", function() LeaveParty() end } );
	else
		table.insert(options, { "Reset All Instances", function() ResetInstances() end } );
	end
		
	setUpOptions(options);
end



local function setUpPlayerDropMenu()
	
	playerDropMenu = CreateFrame("FRAME", "VivifyPlayerDropMenu", playerDropMenu);
	playerDropMenu:SetSize(150, 150);
	playerDropMenu:SetPoint("TOP", playerFrame.hpBar, "TOP", 0, 150);


	playerDropMenu[1] = createFontFrame("Reset All Instances", playerDropMenu, 0, 0);
	playerDropMenu[2] = createFontFrame("Convert To Raid", playerDropMenu, 0, -20);
	playerDropMenu[3] = createFontFrame("Leave Party", playerDropMenu, 0, -40);
	
	
	playerDropMenu:Hide();


	playerDropMenu:SetScript("OnEvent", playerDropMenu_OnEvent);
	playerDropMenu_OnEvent(); --triggers on first load
	
	--PARTY_LEADER_CHANGED seems to trigger when converting the raid/party, doesn't trigger on leave Party
	playerDropMenu:RegisterEvent("PARTY_LEADER_CHANGED");
	playerDropMenu:RegisterEvent("PARTY_MEMBERS_CHANGED");

end





local function savePosition(self)
	local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint();
	VivifySV[self:GetName()] = {
		point = point,
		relativeTo = relativeTo,
		relativePoint = relativePoint,
		x = xOfs,
		y = yOfs
	}; 
end


local function setPowerBarColor(self)
	local color = powerColor[UnitPowerType("player")];
	self.statusBar:SetStatusBarColor(color.r, color.g, color.b, 1);
	self.spark:SetVertexColor(color.r, color.g, color.b, 1);
end





local function createBar(name, point, xOffs, yOffs)

	local frame = CreateFrame("BUTTON", name, point, "SecureUnitButtonTemplate");
	frame:SetAttribute("type","target");
	frame:SetAttribute("unit", "player");
	
	RegisterUnitWatch(frame);
	
	frame:SetSize(512*0.7, 64*0.7);
	
	--border
	frame.border = frame:CreateTexture();
	frame.border:SetTexture("Interface\\AddOns\\Vivify\\frame.blp");
	frame.border:SetAllPoints();
	frame.border:SetDrawLayer("BORDER");
	
	
	--bar
	frame.statusBar = CreateFrame("StatusBar", nil, frame);
	frame.statusBar:SetSize(260,13);
	frame.statusBar:SetStatusBarTexture("Interface\\AddOns\\ABreathBeneath\\texture.blp");
	frame.statusBar:SetPoint("CENTER");
	
	
	--spark/indicator
	frame.spark = frame.statusBar:CreateTexture(nil, "OVERLAY");
	frame.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");
	frame.spark:SetBlendMode("ADD");
	frame.spark:SetSize(32, 32);
	--frame.spark:SetPoint("CENTER", frame);
	
	
	frame.fontNumber = frame.statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	frame.fontNumber:SetFont("Interface\\AddOns\\Rising\\Futura-Condensed-Normal.TTF", 18, "OUTLINE");
	frame.fontNumber:SetTextColor(0.5, 0.5, 0.5, 1);
	frame.fontNumber:SetPoint("CENTER", 0, 0);
	
	
	frame:SetPoint("CENTER", xOffs, yOffs);
	frame:Show();
	frame:SetAlpha(0);
	
	
	--move script
	frame:EnableMouse(true);
	frame:SetScript("OnMouseDown", function(self, button)
		if(IsShiftKeyDown() and IsAltKeyDown() and button=="LeftButton") then
			frame:SetMovable(true);
			frame:StartMoving();
		end
	end);
	frame:SetScript("OnMouseUp", function(self, button)
		frame:StopMovingOrSizing();
		frame:SetMovable(false);
		savePosition(frame);
	end);
	
	--fade in/out on mouseOver
	frame:SetScript("OnEnter", function(self)
		if(not UnitAffectingCombat("player")) then
			UIFrameFadeIn(frame, 1-frame:GetAlpha(), frame:GetAlpha(), 1);
		end
	end);
	frame:SetScript("OnLeave", function(self)
		if(not UnitAffectingCombat("player")) then
			UIFrameFadeOut(frame, frame:GetAlpha(), frame:GetAlpha(), 0);
		end
	end);
	
	--handles fade in/out when entering/exiting combat
	frame.combatHandler = CreateFrame("FRAME");
	frame.combatHandler:SetScript("OnEvent", function(self, event)
		if(event == "PLAYER_REGEN_DISABLED") then
			UIFrameFadeIn(frame, 1-frame:GetAlpha(), frame:GetAlpha(), 1);
		elseif(not MouseIsOver(frame)) then
			UIFrameFadeOut(frame, frame:GetAlpha(), frame:GetAlpha(), 0);
		end
	end);
	
	frame.combatHandler:RegisterEvent("PLAYER_REGEN_DISABLED");
	frame.combatHandler:RegisterEvent("PLAYER_REGEN_ENABLED");
	
	return frame;
end




local function setUpPlayerFrame()

	--setting the hpBar
	playerFrame.hpBar = createBar("VivifyHealthBar", UIParent, 0, 0);
	playerFrame.hpBar.statusBar:SetMinMaxValues(0, UnitHealthMax("player"));
	playerFrame.hpBar.statusBar:SetValue(UnitHealth("player"));
	playerFrame.hpBar.statusBar:SetStatusBarColor(1,0.2,0.2,1);
	playerFrame.hpBar.spark:SetVertexColor(1,0.2,0.2,1);
	playerFrame.hpBar.fontNumber:SetText(UnitHealth("player"));
	playerFrame.hpBar:HookScript("OnMouseUp", function(self, button)
		if(button == "RightButton") then
			togglePlayerDropDownMenu();
		end
	end);
	
	playerFrame.hpBar:SetScript("OnEvent", function(self, event, unit)
		if(unit == "player") then
			local currentHp, maxHp = UnitHealth("player"), UnitHealthMax("player");
			if(event == "UNIT_MAXHEALTH") then
				playerFrame.hpBar.statusBar:SetMinMaxValues(0, maxHp);
			end
			playerFrame.hpBar.statusBar:SetValue(currentHp);
			
			local x = (260/2)*(currentHp-maxHp/2)/(maxHp/2);
			playerFrame.hpBar.spark:SetPoint("CENTER", x, 0);
			
			playerFrame.hpBar.fontNumber:SetText(currentHp);
		end
	end);
	
	playerFrame.hpBar:RegisterEvent("UNIT_HEALTH");
	playerFrame.hpBar:RegisterEvent("UNIT_MAXHEALTH");
	

	
	--setting the powerBar
	playerFrame.powerBar = createBar("VivifyPowerBar", UIParent, 0, 32);
	playerFrame.powerBar.statusBar:SetMinMaxValues(0, UnitPowerMax("player"));
	playerFrame.powerBar.statusBar:SetValue(UnitPower("player"));
	playerFrame.powerBar.fontNumber:SetText(UnitPower("player"));
	playerFrame.powerBar.statusBar:SetReverseFill(true);
	setPowerBarColor(playerFrame.powerBar);
	
--	playerFrame.powerBar.statusBar:SetMinMaxValues(0, UnitPowerMax("player"));
--	playerFrame.powerBar.statusBar:SetValue(UnitPower("player"));
	
	playerFrame.powerBar:SetScript("OnEvent", function(self, event, unit)
		if(unit == "player") then
			local currentPower, maxPower = UnitPower("player"), UnitPowerMax("player");
			if(event == "UNIT_MAXPOWER") then
				playerFrame.powerBar.statusBar:SetMinMaxValues(0, maxPower);
			end
			playerFrame.powerBar.statusBar:SetValue(currentPower);
			
			local x = (260/2)*(currentPower-maxPower/2)/(maxPower/2);
			playerFrame.powerBar.spark:SetPoint("CENTER", -x, 0);
			
			playerFrame.powerBar.fontNumber:SetText(currentPower);
		elseif(event == "UPDATE_SHAPESHIFT_FORM") then
			setPowerBarColor(playerFrame.powerBar);
		end
	end);
	
	playerFrame.powerBar:RegisterEvent("UNIT_POWER_FREQUENT");
	playerFrame.powerBar:RegisterEvent("UNIT_MAXPOWER");
	playerFrame.powerBar:RegisterEvent("UPDATE_SHAPESHIFT_FORM");	
	
end






local function loadSavedVariables()
	if(not VivifySV) then
		VivifySV = {};
	end
	for key, table in pairs(VivifySV) do
		_G[key]:ClearAllPoints();
		_G[key]:SetPoint(table.point, table.relativeTo, table.relativePoint, table.x, table.y);
	end
end




Addon:SetScript("OnEvent", function(self, event, ...)
	setUpPlayerFrame();
	setUpPlayerDropMenu();
	loadSavedVariables();
	

	PlayerFrame:UnregisterAllEvents();
	PlayerFrame:Hide();

	Addon:UnregisterAllEvents();
end);


Addon:RegisterEvent("PLAYER_ENTERING_WORLD");

