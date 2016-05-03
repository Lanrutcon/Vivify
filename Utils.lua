--Blizz functions
--Slightly changed to work with Vivify

-- Frame fading and flashing --

local frameFadeManager = CreateFrame("FRAME");

-- Generic fade function
function UIFrameFade(frame, fadeInfo)
	if (not frame) then
		return;
	end
	if ( not fadeInfo.mode ) then
		fadeInfo.mode = "IN";
	end
	local alpha;
	if ( fadeInfo.mode == "IN" ) then
		if ( not fadeInfo.startAlpha ) then
			fadeInfo.startAlpha = 0;
		end
		if ( not fadeInfo.endAlpha ) then
			fadeInfo.endAlpha = 1.0;
		end
		alpha = 0;
	elseif ( fadeInfo.mode == "OUT" ) then
		if ( not fadeInfo.startAlpha ) then
			fadeInfo.startAlpha = 1.0;
		end
		if ( not fadeInfo.endAlpha ) then
			fadeInfo.endAlpha = 0;
		end
		alpha = 1.0;
	end
	frame:SetAlpha(fadeInfo.startAlpha);

	frame.fadeInfo = fadeInfo;
	--frame:Show();

	local index = 1;
	while FADEFRAMES[index] do
		-- If frame is already set to fade then return
		if ( FADEFRAMES[index] == frame ) then
			return;
		end
		index = index + 1;
	end
	tinsert(FADEFRAMES, frame);
	frameFadeManager:SetScript("OnUpdate", UIFrameFade_OnUpdate);
end



-- Frame Timer --

--calls function after X time
local timer;
local frameTable = {};	--frames that asked for a timer
local size = 0;

local GetTime = GetTime;

function createTimer(time, func, ...)

	if(not timer) then
		timer = CreateFrame("FRAME");
	end
	if(size == 0) then
		local total = 0;
		timer:SetScript("OnUpdate", function(self, elapsed)
			total = total + elapsed;
			if(total > 0.1) then
				total = 0;
				for frame, funcTable in pairs(frameTable) do
					if(GetTime() > funcTable.timeFrame) then
						funcTable.fx(unpack(funcTable.args));
						frameTable[frame] = nil;
						size = size - 1;
						if(size == 0) then
							timer:SetScript("OnUpdate", nil);
						end
					end
				end
			end
		end);
	end

	if(not frameTable[select(1, ...)]) then
		size = size + 1;
	end
	frameTable[select(1, ...)] = {timeFrame=GetTime()+time, fx=func, args={...}};

end

--deletes a timer of a frame
function deleteTimer(frame)
	for frameIndex, funcTable in pairs(frameTable) do
		if(frameIndex == frame) then
			frameTable[frame] = nil;
			size = size - 1;
			if(size == 0) then
				timer:SetScript("OnUpdate", nil);
			end
		end
	end
end
