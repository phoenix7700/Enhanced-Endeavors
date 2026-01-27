--/run DevTool:AddData(
local addonName, shared = ...
local ehed = shared.ehed
local name = addonName
local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "0"
local defaults = {

}
ehed = CreateFrame("Frame", name)
ehed.isDashboardInitialized = false
ehed.isFinderInitialized = false
--Event Registration
local regEvent  = {
    "ADDON_LOADED",
    "HOUSE_LEVEL_FAVOR_UPDATED",
    "INITIATIVE_TASK_COMPLETED",
    "NEIGHBORHOOD_INITIATIVE_UPDATED",
    "INITIATIVE_ACTIVITY_LOG_UPDATED",

}
for _,e in ipairs(regEvent) do ehed:RegisterEvent(e) end

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
function ehed:INITIATIVE_ACTIVITY_LOG_UPDATED(event,...)
    ehed:UpdateFrames()
end

function ehed:ADDON_LOADED(event, addon)
    if addon == "Blizzard_HousingDashboard" and HousingDashboardFrame then
        self:InitializeDashboard()
    elseif addon == "Blizzard_HousingHouseFinder" and HouseFinderFrame then
        self:InitializeFinder()
    elseif addon == name then
        EnhancedEndeavors_SavedData = EnhancedEndeavors_SavedData or {}
        self.db = EnhancedEndeavors_SavedData
        for k,v in pairs(defaults) do
            if self.db[k] == nil then
                self.db[k] = v
            end
        end
    end
    if C_AddOns.IsAddOnLoaded("Blizzard_HousingDashboard") and C_AddOns.IsAddOnLoaded("Blizzard_HousingHouseFinder") then    
        self:UnregisterEvent("ADDON_LOADED")
    end
end

--Dashboard
ehed.areFramesCreated = false
function ehed:InitializeDashboard()
		self:CreateFrames()
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
            --isFrame.InitiativeDescription:SetWidth(isFrame:GetWidth()*0.25)
            pFrame:SetPoint("CENTER", isFrame, "CENTER",0,0)
            ehed.areFramesCreated = true
        end
    end
end
function ehed:UpdateFrames()
    if InCombatLockdown() then return end
    if ehed.areFramesCreated then
        if HousingDashboardFrame and HousingDashboardFrame:IsVisible() then
            --HousingDashboardFrame.HouseInfoContent
            ehed:UpdateCurrentProgressText()
            ehed:ParseActivityLog()
        elseif HouseFinderFrame and HouseFinderFrame:IsVisible() then
            ehed:UpdateHouseFinderInitiatives()
        end
    end
end
function ehed:UpdateCurrentProgressText()
    if type(self.pTextFrame) == "table"  then
        local data = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
        self.lastGoodView = data.neighborhoodGUID
        self.hasLastGoodView = true
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
    local first,second,third = 0,0,0
    local firstplayer,secondplayer,thirdplayer = "?","?","?"
    local ranking = {}
    if type(self.pTextFrame) == "table" then
        local actitivyLog = C_NeighborhoodInitiative.GetInitiativeActivityLogInfo()
        if actitivyLog  then
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
            
        end
    end
    self.firstRankFontString:SetText(firstplayer .. ":" )
    self.secondRankFontString:SetText(secondplayer .. ":")
    self.thirdRankFontString:SetText(thirdplayer .. ":")
    self.firstRankScore:SetText(BreakUpLargeNumbers(first*100))
    self.secondRankScore:SetText(BreakUpLargeNumbers(second*100))
    self.thirdRankScore:SetText(BreakUpLargeNumbers(third*100))
end
--House Finder
ehed.houseFinderQueue = {}
ehed.lastGoodView = ""
ehed.hasLastGoodView = false
function ehed:InitializeFinder()
    hooksecurefunc(HouseFinderFrame, "PopulateNeighborhoodList", function(HFFrame,info)ehed:FixNeighborhoodList(HFFrame.NeighborhoodListFrame.ScrollFrame.NeighborhoodList) end)
    hooksecurefunc(HouseFinderFrame, "PopulateBNetNeighborhoodList", function(HFFrame,info)ehed:FixNeighborhoodList(HFFrame.NeighborhoodListFrame.BNetScrollFrame.NeighborhoodList) end)
    HouseFinderFrame:HookScript("OnHide", function() C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo() end )
end
function ehed:FixNeighborhoodList(neighborhoodList)
        local f = neighborhoodList
        if not f then return end
        local children = {f:GetChildren()}
        for i,child in ipairs(children) do
            ehed.houseFinderQueue[i] = child
            child:SetHeight(80)
            child.NeighborhoodType:SetJustifyH("LEFT")
            child.NeighborhoodName:SetSize(200,child.NeighborhoodName:GetLineHeight())
            if child.neighborhoodInfo.suggestionReason == Enum.HouseFinderSuggestionReason.Guild then
                child.NeighborhoodName:SetPoint("TOPLEFT", child, "TOPLEFT", 30, -12)
            else
                child.NeighborhoodName:SetPoint("TOPLEFT", child, "TOPLEFT", 15, -12)
            end
            if not child.NeighborhoodInitiative then
                child.NeighborhoodInitiative = child:CreateFontString("neighborhood-initiative","ARTWORK")
                child.NeighborhoodInitiative:SetFontObject(GameFontHighlightSmall)
                child.NeighborhoodInitiative:SetPoint("TOPLEFT",child.NeighborhoodType, "BOTTOMLEFT",0,-4)
                child.NeighborhoodInitiative:SetJustifyH("LEFT")
                child.NeighborhoodInitiative:SetTextColor(1,0.82,0)
            end
            if not child.NeighborhoodMilestone then
                child.NeighborhoodMilestone = child:CreateFontString("neighborhood-milestone","ARTWORK")
                child.NeighborhoodMilestone:SetFontObject(GameFontHighlightSmall)
                child.NeighborhoodMilestone:SetPoint("TOPLEFT",child.NeighborhoodInitiative, "BOTTOMLEFT",0,-2)
                child.NeighborhoodMilestone:SetJustifyH("LEFT")
                child.NeighborhoodMilestone:SetTextColor(1,0.82,0)
            end
            child.NeighborhoodInitiative:SetText(shared.L["Loading..."])
            child.NeighborhoodMilestone:SetText("")
            
        end
        f.spacing = 0
        f.topPadding = -1
        f:SetFixedHeight(95)
        f:MarkDirty()
        f:Layout()
        ehed:RequestNeighborhoodInitiativeInfo()
end
function ehed:FixBNetNeighborhoodList()

end
function ehed:RequestNeighborhoodInitiativeInfo()
    if not ehed.hasLastGoodView then 
        ehed.lastGoodView = ehed.houseFinderQueue[1].neighborhoodInfo.neighborhoodGUID
        ehed.hasLastGoodView = true
    end
    C_NeighborhoodInitiative.SetViewingNeighborhood(ehed.houseFinderQueue[1].neighborhoodInfo.neighborhoodGUID)
    C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
end
function ehed:UpdateHouseFinderInitiatives()
    local info = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
    if not info then return end
    if #self.houseFinderQueue > 0 then
        self.houseFinderQueue[1].NeighborhoodInitiative:SetText(info.title)
        self.houseFinderQueue[1].NeighborhoodMilestone:SetText(self:GetMilestoneText(self:GetMilestoneForNeighborhood(info)))
        table.remove(self.houseFinderQueue,1)
    end
    if #self.houseFinderQueue > 0 then 
        self:RequestNeighborhoodInitiativeInfo()
    elseif #self.houseFinderQueue <= 0 and self.hasLastGoodView == true then
        C_NeighborhoodInitiative.SetViewingNeighborhood(self.lastGoodView)
        self.hasLastGoodView = false
    end
end

function ehed:GetMilestoneForNeighborhood(neighborhoodInfo)
    if neighborhoodInfo and neighborhoodInfo.milestones then
        local milestones = neighborhoodInfo.milestones
        for i= #milestones, 1, -1 do
            if milestones and neighborhoodInfo.currentProgress >= milestones[i].requiredContributionAmount then
                return milestones[i].milestoneOrderIndex + 1
            end
        end
    end
    return 0
end

function ehed:GetMilestoneText(milestone)
    return shared.L["Milestone"] .. tostring(milestone)
end

ehed:HookScript("OnEvent", ehed.OnEvent)
ehed:SetSize(1,1)

--ehed:InitializeDashboa()

