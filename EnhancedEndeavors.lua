--/run DevTool:AddData(
local addonName, shared = ...
local ehed = shared.ehed
local name = addonName
local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "0"
local defaults = {

}
ehed = CreateFrame("Frame", name)

ehed:RegisterEvent("ADDON_LOADED")
ehed:RegisterEvent("HOUSE_LEVEL_FAVOR_UPDATED")
ehed:RegisterEvent("INITIATIVE_TASK_COMPLETED")
ehed:RegisterEvent("NEIGHBORHOOD_INITIATIVE_UPDATED")

function ehed:OnEvent(event, ...)
    self[event](self,event,...)
end

function ehed:HOUSE_LEVEL_FAVOR_UPDATED(event,...)
    ehed:UpdateFrames()
end
function ehed:INITIATIVE_TASK_COMPLETED(event, ...)
    ehed:UpdateFrames()
end
function ehed:NEIGHBORHOOD_INITIATIVE_UPDATED(event,...)
    ehed:UpdateFrames()
end

function ehed:ADDON_LOADED(event, addon)
    if addon == "Blizzard_HousingDashboard" then
        self:Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    elseif addon == name then
        EnhancedEndeavors_SavedData = EnhancedEndeavors_SavedData or {}
        self.db = EnhancedEndeavors_SavedData
        for k,v in pairs(defaults) do
            if self.db[k] == nil then
                self.db[k] = v
            end
        end
    end
end

function ehed:Initialize()
	if HousingDashboardFrame then
        if type(HousingDashboardFrame.OnShow) == "function" then
			hooksecurefunc(HousingDashboardFrame, "OnShow", function() self:CreateFrames() end)
		end
		self:CreateFrames()
	end
end

function ehed:CreateFrames ()
    if not self.pTextFrame then
        local isFrame = HousingDashboardFrame.HouseInfoContent.ContentFrame.InitiativesFrame.InitiativeSetFrame
        local pFrame = isFrame.ProgressBar
        if pFrame then
            --Holding frame
            self.pTextFrame = CreateFrame("Frame", "ProgressTextFrame", pFrame)
            --Progress Font
            self.progressFontString = self.pTextFrame:CreateFontString("ProgressTextString", "ARTWORK")
            self.progressFontString:SetPoint("RIGHT", pFrame , "RIGHT",-15,0)
            self.progressFontString:SetFontObject(GameFontHighlight)
            self.progressFontString:SetJustifyH("RIGHT")
            self.progressFontString:SetJustifyV("BOTTOM")
            --Your Contribution
            self.playerContributionFontString = self.pTextFrame:CreateFontString("ContributionTextString","ARTWORK")
            self.playerContributionFontString:SetPoint("CENTER",pFrame,"CENTER",0,25)
            self.playerContributionFontString:SetFontObject(GameFontHighlight)
            --Rankings
            self.titleRankFontString = self.pTextFrame:CreateFontString("TitleRankTextString","ARTWORK")
            self.titleRankFontString:SetPoint("TOPRIGHT", isFrame,"TOPRIGHT", -15,-5)
            self.titleRankFontString:SetFontObject(GameFontNormalLarge2)
            self.titleRankFontString:SetText(shared.L["Top Contributors"])

            self.firstRankFontString = self.pTextFrame:CreateFontString("FirstRankTextString","ARTWORK")
            self.firstRankFontString:SetPoint("TOPRIGHT", self.titleRankFontString,"BOTTOMRIGHT",-45,-5)
            self.firstRankFontString:SetFontObject(GameFontHighlightLarge)
            self.firstRankScore = self.pTextFrame:CreateFontString("FirstRankScore","ARTWORK")
            self.firstRankScore:SetPoint("LEFT", self.firstRankFontString, "RIGHT",2,0)
            self.firstRankScore:SetFontObject(GameFontHighlightLarge)
            self.firstRankScore:SetTextColor(1.0,0.5,0) --Legendary

            self.secondRankFontString = self.pTextFrame:CreateFontString("SecondRankTextString","ARTWORK")
            self.secondRankFontString:SetPoint("TOPRIGHT",self.firstRankFontString, "BOTTOMRIGHT",0,-2)
            self.secondRankFontString:SetFontObject(GameFontHighlight)
            self.secondRankScore = self.pTextFrame:CreateFontString("FirstRankScore","ARTWORK")
            self.secondRankScore:SetPoint("LEFT", self.secondRankFontString, "RIGHT",2,0)
            self.secondRankScore:SetFontObject(GameFontHighlight)
            self.secondRankScore:SetTextColor(0.64,0.21,0.93) --Epic

            self.thirdRankFontString = self.pTextFrame:CreateFontString("ThirdRankTextString","ARTWORK")
            self.thirdRankFontString:SetPoint("TOPRIGHT", self.secondRankFontString,"BOTTOMRIGHT",0,-2)
            self.thirdRankFontString:SetFontObject(GameFontHighlight)
            self.thirdRankScore = self.pTextFrame:CreateFontString("FirstRankScore","ARTWORK")
            self.thirdRankScore:SetPoint("LEFT", self.thirdRankFontString, "RIGHT",2,0)
            self.thirdRankScore:SetFontObject(GameFontHighlight)
            self.thirdRankScore:SetTextColor(0,0.44,0.87) --Rare
            ehed:UpdateCurrentProgressText()
            --Make adjustments to default layout
            isFrame.InitiativeTimer:SetPoint("TOPRIGHT", isFrame,"TOPRIGHT", 25,-135)
            isFrame.InitiativeDescription:SetWidth(isFrame:GetWidth()*0.25)
            pFrame:SetPoint("CENTER", isFrame, "CENTER",0,0)
        end
    end
end
function ehed:UpdateFrames()
    ehed:UpdateCurrentProgressText()
    ehed:ParseActivityLog()
end
function ehed:UpdateCurrentProgressText()
    if type(self.pTextFrame) == "table"  then
        local data = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
        local currprogress = data.currentProgress * 100
        local maxprogress = data.progressRequired * 100
        local contribution = data.playerTotalContribution *100
        local percent
        local contributionpercent
        if maxprogress ~= 0 then percent = (currprogress/maxprogress)*100 else percent = 0 end
        if currprogress ~= 0 then contributionpercent = (contribution/currprogress)*100 else contributionpercent = 0 end
        if type(currprogress) == "number" and type(percent) == "number" and percent ~= inf and type(maxprogress) == "number" and type(contribution) == "number" then
            self.progressFontString:SetText("(" .. BreakUpLargeNumbers(percent) .."%) " .. BreakUpLargeNumbers(currprogress) .. "/" .. BreakUpLargeNumbers(maxprogress))
            self.playerContributionFontString:SetText(shared.L["Your contribution"] .. ": " .. BreakUpLargeNumbers(contribution) .. " (" .. BreakUpLargeNumbers(contributionpercent) .. shared.L["% of current"] .. ")")
        else
            self.progressFontString:SetText("...")
            self.playerContributionFontString:SetText(shared.L["Your contribution"] .. ": " .. "")
        end
    elseif self.pTextFrame == nil and HousingDashboardFrame then
        ehed:CreateFrames()
    end
end
function ehed:ParseActivityLog()
    if type(self.pTextFrame) == "table" then
        local actitivyLog = C_NeighborhoodInitiative.GetInitiativeActivityLogInfo()
        if actitivyLog then
            local ranking = {}
            local first,second,third = 0
            local firstplayer,secondplayer,thirdplayer
            if actitivyLog then
                for k,info in pairs(actitivyLog.taskActivity) do
                    if not ranking[info.playerName] then
                        ranking[info.playerName] = 0
                    end
                    ranking[info.playerName] = ranking[info.playerName] + info.amount
                end
            end
            for player,contribution in pairs(ranking) do
                if contribution  > first then 
                    thirdplayer = secondplayer
                    third = second
                    secondplayer = firstplayer
                    second = first
                    firstplayer = player
                    first = contribution
                elseif contribution > second then
                    thirdplayer = secondplayer
                    third = second
                    secondplayer = player
                    second = contribution
                elseif contribution > third then
                    thirdplayer = player
                    third = contribution
                end
            end
            if not firstplayer then return end
            if not secondplayer then return end
            if not thirdplayer then return end
            self.firstRankFontString:SetText(firstplayer .. ":" )
            self.secondRankFontString:SetText(secondplayer .. ":")
            self.thirdRankFontString:SetText(thirdplayer .. ":")
            self.firstRankScore:SetText(BreakUpLargeNumbers(first*100))
            self.secondRankScore:SetText(BreakUpLargeNumbers(second*100))
            self.thirdRankScore:SetText(BreakUpLargeNumbers(third*100))
        end
    end


end


ehed:HookScript("OnEvent", ehed.OnEvent)
ehed:SetSize(1,1)

--ehed:Initialize()

