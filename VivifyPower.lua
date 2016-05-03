local Addon = CreateFrame("FRAME");

local powerFrame;


----------------------------------------
-- UTILS Functions
----------------------------------------

local function createTexture(frame, texture, height, width, point, xOfs, yOfs)

	local textureFrame = CreateFrame("FRAME", nil, frame);
	textureFrame:SetSize(height, width);
	textureFrame:SetPoint(point, frame, xOfs, yOfs);

	textureFrame.background = textureFrame:CreateTexture(nil, "BACKGROUND");
	textureFrame.background:SetTexture("Interface\\AddOns\\Vivify\\Textures\\"..texture.."0.blp");
	textureFrame.background:SetAllPoints();

	textureFrame.border = textureFrame:CreateTexture(nil, "BORDER");
	textureFrame.border:SetTexture("Interface\\AddOns\\Vivify\\Textures\\"..texture.."1.blp");
	textureFrame.border:SetAllPoints();

	textureFrame.artwork = textureFrame:CreateTexture(nil, "ARTWORK");
	textureFrame.artwork:SetTexture("Interface\\AddOns\\Vivify\\Textures\\"..texture.."2.blp");
	textureFrame.artwork:SetBlendMode("BLEND");
	textureFrame.artwork:SetAllPoints();

	textureFrame.overlay = textureFrame:CreateTexture(nil, "OVERLAY");
	textureFrame.overlay:SetTexture("Interface\\AddOns\\Vivify\\Textures\\"..texture.."1.blp");
	textureFrame.overlay:SetBlendMode("ADD");
	textureFrame.overlay:SetAllPoints();


	--animation glow
	textureFrame.animationGroup = textureFrame.overlay:CreateAnimationGroup();
	local animation = textureFrame.animationGroup:CreateAnimation("Alpha");
	animation:SetChange(-0.5);
	animation:SetDuration(1);
	animation:SetSmoothing("OUT");
	textureFrame.animationGroup:SetLooping("BOUNCE");
	textureFrame.animationGroup:Play();


	return textureFrame;

end


local function createGradientPanel()
	powerFrame.background = powerFrame:CreateTexture(nil, "BACKGROUND");
	powerFrame.background:SetTexture(0,0,0,1);
	powerFrame.background:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 1);
	powerFrame.background:SetAllPoints(powerFrame);
end


local function setUpPowerFrame()
	powerFrame = CreateFrame("FRAME", "VivifyPowerFrame", _G["VivifyHealthBar"]);
	powerFrame:SetSize(512*0.5, 64*0.5);
	powerFrame:SetPoint("BOTTOM", _G["VivifyHealthBar"], 0, -20);
end

----------------------------------------




----------------------------------------
-- DEATH KNIGHT
----------------------------------------

local runeColor = {
	[1] = {1,0,0},
	[2] = {0,1,0},
	[3] = {0,0,1},
	[4] = {1,0,1}
};


local function updateRune(runeIndex)
	local start, duration, runeReady = GetRuneCooldown(runeIndex);
	
	if(runeReady) then
		powerFrame[runeIndex]:SetScript("OnUpdate", nil);

		powerFrame[runeIndex].background:SetVertexColor(1,1,1);
		powerFrame[runeIndex].border:SetVertexColor(1,1,1);
		powerFrame[runeIndex].artwork:SetVertexColor(unpack(runeColor[GetRuneType(runeIndex)]));
		powerFrame[runeIndex].overlay:SetVertexColor(1,1,1);
	elseif(not powerFrame[runeIndex]:GetScript("OnUpdate")) then
		local endTime = start+duration-GetTime();
		
		local total, cooldown = 0, 0;
		powerFrame[runeIndex]:SetScript("OnUpdate", function(self, elapsed)
			total = total + elapsed;
			cooldown = cooldown + elapsed;
			if(total > 0.02) then
				total = 0;
				if(cooldown < endTime) then
    				local timeLeft = endTime - cooldown;
    				local light = (1-timeLeft/endTime)^2;
    
    				powerFrame[runeIndex].background:SetVertexColor(light,light,light);
    				powerFrame[runeIndex].border:SetVertexColor(light,light,light);
    				powerFrame[runeIndex].artwork:SetVertexColor(light,light,light);
    				powerFrame[runeIndex].overlay:SetVertexColor(light,light,light);
				end
			end
		end);
	end
end


local runeTexture = {
	[1] = "br",
	[2] = "ur",
	[3] = "fr",
	[4] = "dr"
};


local function updateRuneTexture(runeIndex)
	local runeType = GetRuneType(runeIndex);
	powerFrame[runeIndex].background:SetTexture("Interface\\AddOns\\Vivify\\Textures\\"..runeTexture[runeType].."0.blp");
	powerFrame[runeIndex].border:SetTexture("Interface\\AddOns\\Vivify\\Textures\\"..runeTexture[runeType].."1.blp");
	powerFrame[runeIndex].artwork:SetTexture("Interface\\AddOns\\Vivify\\Textures\\"..runeTexture[runeType].."2.blp");
	powerFrame[runeIndex].overlay:SetTexture("Interface\\AddOns\\Vivify\\Textures\\"..runeTexture[runeType].."1.blp");
end



local function setUpDeathKnightPower(talentChange)
	
	if(not talentChange) then

		--clear events from Blizzard RuneFrame
		_G["RuneFrame"]:UnregisterAllEvents();
		_G["RuneFrame"]:Hide();


		setUpPowerFrame();
		createGradientPanel();


		powerFrame[1] = createTexture(powerFrame, "br", 28, 28, "CENTER", -100, 0);
		powerFrame[2] = createTexture(powerFrame, "br", 28, 28, "CENTER", -60, 0);
		powerFrame[5] = createTexture(powerFrame, "fr", 28, 28, "CENTER", -20, 0);
		powerFrame[6] = createTexture(powerFrame, "fr", 28, 28, "CENTER", 20, 0);
		powerFrame[3] = createTexture(powerFrame, "ur", 28, 28, "CENTER", 60, 0);
		powerFrame[4] = createTexture(powerFrame, "ur", 28, 28, "CENTER", 100, 0);

		powerFrame:SetScript("OnEvent", function(self, event, runeIndex)
			if(event == "RUNE_POWER_UPDATE") then
				updateRune(runeIndex);
			else --RUNE_TYPE_UPDATE
				updateRuneTexture(runeIndex);
			end
		end);


		powerFrame:RegisterEvent("RUNE_TYPE_UPDATE");
		powerFrame:RegisterEvent("RUNE_POWER_UPDATE");
	end

	--on load
	for i = 1, 6 do
		updateRune(i);
		updateRuneTexture(i);
	end

end


----------------------------------------
-- DRUID
----------------------------------------

local function toggleVertexColor(textureFrame, light)
	if(light) then
		textureFrame.background:SetVertexColor(1,1,1);
		textureFrame.border:SetVertexColor(1,1,1);
		textureFrame.artwork:SetVertexColor(unpack(light));
		textureFrame.overlay:SetVertexColor(1,1,1);
	else
		textureFrame.background:SetVertexColor(1,1,1);
		textureFrame.border:SetVertexColor(0,0,0);
		textureFrame.artwork:SetVertexColor(0,0,0);
		textureFrame.overlay:SetVertexColor(0,0,0);
	end
end


local function updateSpark(self)
	local eclipsePower = UnitPower("player",8);

	self.eclipseBar.spark:SetPoint("CENTER", eclipsePower*1.17, -eclipsePower/100);
	self.eclipseBar.spark:SetRotation(-math.pi/3*(eclipsePower/100));
end

local function updateAura(self)
	if(UnitAura("player", "Eclipse (Lunar)")) then
		toggleVertexColor(self.eclipseBar.moon, {0.6,0.6,1});
	elseif(UnitAura("player", "Eclipse (Solar)")) then
		toggleVertexColor(self.eclipseBar.sun, {1,0.8,0});
	else
		toggleVertexColor(self.eclipseBar.sun);
		toggleVertexColor(self.eclipseBar.moon);
	end
end


local function setUpDruidPower(talentChange)
	--Checks if it's a Balance Druid
	if(GetPrimaryTalentTree(nil,nil,GetActiveTalentGroup()) == 1) then
		if(not powerFrame or not talentChange) then

			setUpPowerFrame();


			powerFrame.eclipseBar = CreateFrame("FRAME", "VivifyEclipseBar", powerFrame);
			powerFrame.eclipseBar:SetSize(512*0.5, 32*0.5);
			powerFrame.eclipseBar:SetPoint("TOP", powerFrame);

			powerFrame.eclipseBar.texture = powerFrame.eclipseBar:CreateTexture();
			powerFrame.eclipseBar.texture:SetTexture("Interface\\AddOns\\Vivify\\Textures\\eclipseBar.blp");
			powerFrame.eclipseBar.texture:SetSize(512*0.71, 32*0.71);
			powerFrame.eclipseBar.texture:SetPoint("BOTTOM", powerFrame.eclipseBar, -1, -2);

			powerFrame.eclipseBar.spark = powerFrame.eclipseBar:CreateTexture(nil, "OVERLAY");
			powerFrame.eclipseBar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");
			powerFrame.eclipseBar.spark:SetBlendMode("ADD");
			powerFrame.eclipseBar.spark:SetSize(32,32);
			powerFrame.eclipseBar.spark:SetPoint("CENTER", 0,0);


			powerFrame.eclipseBar.sun = createTexture(powerFrame.eclipseBar, "sun", 64*0.6, 64*0.6, "RIGHT", 25, -7);
			toggleVertexColor(powerFrame.eclipseBar.sun);

			powerFrame.eclipseBar.moon = createTexture(powerFrame.eclipseBar, "moon", 64*0.6, 64*0.6, "LEFT", -27, -7);
			toggleVertexColor(powerFrame.eclipseBar.moon);


			powerFrame:SetScript("OnEvent", function(self, event, ...)
				local unit, powerType = ...;
				if(event == "UNIT_POWER" and unit == "player" and powerType == "ECLIPSE") then
					updateSpark(self);
				elseif(event == "UNIT_AURA" and unit == "player") then
					updateAura(self);
				end
			end);

			powerFrame:RegisterEvent("UNIT_POWER");
			powerFrame:RegisterEvent("UNIT_AURA");

		end

		--onLoad
		updateSpark(powerFrame);
		updateAura(powerFrame);

		powerFrame:Show();
		
	elseif(powerFrame) then
		powerFrame:Hide();
	end
end


----------------------------------------
-- PALADIN
----------------------------------------

local function updateHolyPower()
	local numShards = UnitPower("player", 9);
	for i = 1, 3 do
		if(i > numShards) then
			powerFrame[i].background:SetVertexColor(0,0,0);
			powerFrame[i].border:SetVertexColor(0,0,0);
			powerFrame[i].artwork:SetVertexColor(0,0,0);
			powerFrame[i].overlay:SetVertexColor(0,0,0);
		else
			powerFrame[i].background:SetVertexColor(1,1,1);
			powerFrame[i].border:SetVertexColor(1,1,1);
			powerFrame[i].artwork:SetVertexColor(1, 1, 0);
			powerFrame[i].overlay:SetVertexColor(1,1,1);
			UIFrameFlash(powerFrame[i], 0.3, 0.2, 0.8, true, 0, 0);
		end
	end
end



local function setUpPaladinPower(talentChange)

	if(not talentChange) then

		setUpPowerFrame();
		createGradientPanel();


		powerFrame[1] = createTexture(powerFrame, "hp", 28, 28, "CENTER", -40, 0);
		powerFrame[2] = createTexture(powerFrame, "hp", 28, 28, "CENTER", 0, 0);
		powerFrame[3] = createTexture(powerFrame, "hp", 28, 28, "CENTER", 40, 0);


		powerFrame:SetScript("OnEvent", function(self, event, ...)
			local unit, powerType = ...;
			if(unit == "player" and powerType == "HOLY_POWER") then
				updateHolyPower();
			end
		end);

		powerFrame:RegisterEvent("UNIT_POWER");

	end

	--on load
	updateHolyPower();

end




----------------------------------------
-- WARLOCK
----------------------------------------

local function updateSoulShards()
	local numShards = UnitPower("player", 7);
	for i = 1, 3 do
		if(i > numShards) then
			powerFrame[i].background:SetVertexColor(0,0,0);
			powerFrame[i].border:SetVertexColor(0,0,0);
			powerFrame[i].artwork:SetVertexColor(0,0,0);
			powerFrame[i].overlay:SetVertexColor(0,0,0);
		else
			powerFrame[i].background:SetVertexColor(1,1,1);
			powerFrame[i].border:SetVertexColor(1,1,1);
			powerFrame[i].artwork:SetVertexColor(0.8, 0.3, 1);
			powerFrame[i].overlay:SetVertexColor(1,1,1);
			UIFrameFlash(powerFrame[i], 0.3, 0.2, 0.8, true, 0, 0);
		end
	end
end



local function setUpWarlockPower(talentChange)

	if(not talentChange) then

		setUpPowerFrame();
		createGradientPanel();


		powerFrame[1] = createTexture(powerFrame, "ss", 28, 28, "CENTER", -40, 0);
		powerFrame[2] = createTexture(powerFrame, "ss", 28, 28, "CENTER", 0, 0);
		powerFrame[3] = createTexture(powerFrame, "ss", 28, 28, "CENTER", 40, 0);


		powerFrame:SetScript("OnEvent", function(self, event, ...)
			local unit, powerType = ...;
			if(unit == "player" and powerType == "SOUL_SHARDS") then
				updateSoulShards();
			end
		end);

		powerFrame:RegisterEvent("UNIT_POWER");

	end

	--on load
	updateSoulShards();

end


----------------------------------------


--Classes+Specs with powers
--DeathKnight	+ Blood-Frost-Unholy
--Druid 		+ Moonkin
--Paladin		+ Holy-Protection-Retribution
--Warlock		+ Affliction-Demonology-Destruction

local setUpPowerTable = {
	["Death Knight"] = setUpDeathKnightPower,
	["Druid"] = setUpDruidPower,
	["Paladin"] = setUpPaladinPower,
	["Warlock"] = setUpWarlockPower
};

Addon:SetScript("OnEvent", function(self, event, ...)
	if(event == "ACTIVE_TALENT_GROUP_CHANGED") then
		setUpPowerTable[UnitClass("player")](true);
	else		
		if(not setUpPowerTable[UnitClass("player")]) then
			Addon:UnregisterAllEvents();
			return;
		end
		setUpPowerTable[UnitClass("player")]();
		
		--RegisterEvent here because it's being triggered before PlayerEnteringWorld & we can't call info functions (i.e. return nil)
		Addon:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
		Addon:UnregisterEvent("PLAYER_ENTERING_WORLD");
	end
end);


Addon:RegisterEvent("PLAYER_ENTERING_WORLD");

