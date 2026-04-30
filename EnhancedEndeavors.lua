--/run DevTool:AddData(
local addonName, shared = ...
local ehed = shared.ehed or CreateFrame("Frame", name)
ehed.areFramesCreated = false
--todo: add options
local name = addonName
--local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "0"
local defaults = {}
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
    self:UpdateFrames()
end
function ehed:INITIATIVE_TASK_COMPLETED(event, ...)
    self:UpdateFrames()
end
function ehed:NEIGHBORHOOD_INITIATIVE_UPDATED(event,...)
    self:UpdateFrames()
end
function ehed:INITIATIVE_ACTIVITY_LOG_UPDATED(event,...)
    self:UpdateFrames()
end
function ehed:ADDON_LOADED(event, addon)
    if addon == "Blizzard_HousingDashboard" and HousingDashboardFrame then
        self:InitializeDashboard()
        self:isBothAddOnLoaded()
    elseif addon == "Blizzard_HousingHouseFinder" and HouseFinderFrame then
        self:InitializeFinder()
        self:isBothAddOnLoaded()
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
function ehed:isBothAddOnLoaded()
    if C_AddOns.IsAddOnLoaded("Blizzard_HousingDashboard") and C_AddOns.IsAddOnLoaded("Blizzard_HousingHouseFinder") then
        self:UnregisterEvent("ADDON_LOADED")
    end
end

function ehed:UpdateFrames()
    if InCombatLockdown() then return end
    if self.areFramesCreated then
        if HousingDashboardFrame and HousingDashboardFrame:IsVisible() then
            self:UpdateCurrentProgressText()
            self:ParseActivityLog()
        end
    end
    if HouseFinderFrame and HouseFinderFrame:IsVisible() then
            self:UpdateHouseFinderInitiatives()
    end
end

-----------------------------Dashboard-----------------------------

function ehed:InitializeDashboard()
		self:CreateFrames()
        HousingDashboardFrame.HouseInfoContent.ContentFrame:HookScript("OnUpdate", function() ehed:UpdateFrames() end)
        HousingDashboardFrame.HouseInfoContent.ContentFrame.InitiativesFrame.InitiativeSetFrame.InitiativeActiveNeighborhoodSwitcher.SwitchActiveNeighborhoodBtn:HookScript("OnClick",function () ehed:UpdateFrames() end)
end
function ehed:CreateFrames ()
    if not self.areFramesCreated and HousingDashboardFrame then
        local artFrame = HousingDashboardFrame.HouseInfoContent.ContentFrame.InitiativesFrame.InitiativesArt
        local isFrame = HousingDashboardFrame.HouseInfoContent.ContentFrame.InitiativesFrame.InitiativeSetFrame
        local pFrame = isFrame.ProgressBar
        if pFrame then
            --Progress Font
            self.progressFontString = pFrame.TextContainer:CreateFontString("ProgressTextString", "ARTWORK")
            self.progressFontString:SetPoint("RIGHT", pFrame.TextContainer , "RIGHT",-15,0)
            self.progressFontString:SetFontObject(GameFontHighlight)
            self.progressFontString:SetJustifyH("RIGHT")
            self.progressFontString:SetJustifyV("BOTTOM")
            self.progressFontString:SetShadowColor(0,0,0)
            --Your Contribution
            self.playerContributionFontString = pFrame:CreateFontString("ContributionTextString","ARTWORK")
            self.playerContributionFontString:SetPoint("BOTTOM",pFrame,"TOP",0,3)
            self.playerContributionFontString:SetFontObject(GameFontHighlight)
            --Completion Time
            self.completionTimeFontString = pFrame:CreateFontString("CompletionTimeTextString","ARTWORK")
            self.completionTimeFontString:SetPoint("BOTTOMRIGHT",pFrame,"TOPRIGHT",0,3)
            self.completionTimeFontString:SetFontObject(GameFontHighlight)
            self.completionTimeFontString:Hide()
            --Rankings
            self.mouseoverRanking = CreateFrame("Frame","AllEndeavorRanks", isFrame)
            self.mouseoverRanking:SetPoint("TOPRIGHT", isFrame, "TOPRIGHT", 0, -5)
            self.mouseoverRanking:SetSize(170,73)
            self.mouseoverRanking:SetScript("OnEnter", function(self, motion)  
                if not ehed.taskRankings then return end
                if #ehed.taskRankings <= 0 then return end
                GameTooltip:SetOwner(self,"ANCHOR_NONE")
                GameTooltip:ClearAllPoints()
                GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT")
                GameTooltip:AddLine(shared.L["Top Contributors"])
                for i,data in ipairs(ehed.taskRankings) do
                    local r,g,b = 0,0,0
                    if i == 1 then
                        r,g,b =GetItemQualityColor(5)
                    elseif i/#ehed.taskRankings < 0.1 then
                        r,g,b = GetItemQualityColor(4)
                    elseif i/#ehed.taskRankings < 0.25 then
                        r,g,b = GetItemQualityColor(3)
                    elseif i/#ehed.taskRankings < 0.5 then
                        r,g,b = GetItemQualityColor(2)
                    elseif i/#ehed.taskRankings < 0.9 then
                        r,g,b = GetItemQualityColor(1)
                    else
                        r,g,b = GetItemQualityColor(0)
                    end
                    GameTooltip:AddDoubleLine(data.name , BreakUpLargeNumbers(data.contribution*100),r,g,b)
                end
                GameTooltip:Show()
            end)
            self.mouseoverRanking:SetScript("OnLeave", function(self, motion) 
                GameTooltip:Hide()
            end)

            local r,g,b = 0,0,0
            self.titleRankFontString = self.mouseoverRanking:CreateFontString("TitleRankTextString","ARTWORK")
            self.titleRankFontString:SetPoint("TOPRIGHT", self.mouseoverRanking,"TOPRIGHT", -15,-3)
            self.titleRankFontString:SetFontObject(GameFontNormalLarge2)
            self.titleRankFontString:SetJustifyV("BOTTOM")
            self.titleRankFontString:SetText(shared.L["Top Contributors"])

            self.firstRankFontString = self.mouseoverRanking:CreateFontString("FirstRankTextString","ARTWORK")
            self.firstRankFontString:SetPoint("TOPRIGHT", self.titleRankFontString,"BOTTOMRIGHT",-47,-5)
            self.firstRankFontString:SetFontObject(GameFontHighlightLarge)
            self.firstRankFontString:SetText("? :")
            self.firstRankScore = self.mouseoverRanking:CreateFontString("FirstRankScore","ARTWORK")
            self.firstRankScore:SetPoint("LEFT", self.firstRankFontString, "RIGHT",2,0)
            self.firstRankScore:SetFontObject(GameFontHighlightLarge)
            self.firstRankScore:SetText("?")
            r,g,b = GetItemQualityColor(5)
            self.firstRankScore:SetTextColor(r,g,b) --Legendary

            self.secondRankFontString = self.mouseoverRanking:CreateFontString("SecondRankTextString","ARTWORK")
            self.secondRankFontString:SetPoint("TOPRIGHT",self.firstRankFontString, "BOTTOMRIGHT",0,-2)
            self.secondRankFontString:SetFontObject(GameFontHighlight)
            self.secondRankFontString:SetText("? :")
            self.secondRankScore = self.mouseoverRanking:CreateFontString("SecondRankScore","ARTWORK")
            self.secondRankScore:SetPoint("LEFT", self.secondRankFontString, "RIGHT",3,0)
            self.secondRankScore:SetFontObject(GameFontHighlight)
            self.secondRankScore:SetText("?")
            r,g,b = GetItemQualityColor(4)
            self.secondRankScore:SetTextColor(r,g,b) --Epic

            self.thirdRankFontString = self.mouseoverRanking:CreateFontString("ThirdRankTextString","ARTWORK")
            self.thirdRankFontString:SetPoint("TOPRIGHT", self.secondRankFontString,"BOTTOMRIGHT",0,-2)
            self.thirdRankFontString:SetFontObject(GameFontHighlight)
            self.thirdRankFontString:SetText("? :")
            self.thirdRankScore = self.mouseoverRanking:CreateFontString("ThirdRankScore","ARTWORK")
            self.thirdRankScore:SetPoint("LEFT", self.thirdRankFontString, "RIGHT",3,0)
            self.thirdRankScore:SetFontObject(GameFontHighlight)
            self.thirdRankScore:SetText("?")
            r,g,b = GetItemQualityColor(3)
            self.thirdRankScore:SetTextColor(r,g,b) --Rare

            
            --HouseXP Label
            self.houseXPLabel = isFrame:CreateFontString("HouseXPLabel", "ARTWORK")
            self.houseXPLabel:SetPoint("LEFT", isFrame.InitiativesXPIcon, "RIGHT", 5,0)
            self.houseXPLabel:SetFontObject(GameFontHighlight)
            --Activities
            local listView = isFrame.InitiativeTasks.TaskList:GetView()
            listView:SetElementFactory(function(factory, node)
                local data = node:GetData();

                local function TaskInitializer(button)
                    if data.taskType == Enum.NeighborhoodInitiativeTaskType.RepeatableInfinite then
                        button.CollapseIcon:Hide();
                        button.CollapseIconAlphaAdd:Hide();
                    elseif data.taskType == Enum.NeighborhoodInitiativeTaskType.RepeatableFinite then
                        if data.topLevel then
                            button.CollapseIcon:Show();
                            button.CollapseIconAlphaAdd:Show();
                            button:SetCollapseState(node:IsCollapsed());
                        else
                            button.CollapseIcon:Hide();
                            button.CollapseIconAlphaAdd:Hide();
                        end
                    else
                        button.CollapseIcon:Hide();
                        button.CollapseIconAlphaAdd:Hide();
                    end

                    if data.timesCompleted and data.taskType == Enum.NeighborhoodInitiativeTaskType.RepeatableInfinite then
                        button.Title:SetText(shared.L["Repeatable Task Title"]:format(data.taskName, data.timesCompleted,ehed.playerTaskCount[data.ID],ehed.taskCount[data.ID]));
                    else
                        button.Title:SetText(data.taskName);
                    end

                    -- TODO: fix supercede (repeatableFinite) 
                    if data.completed and data.taskType ~= Enum.NeighborhoodInitiativeTaskType.RepeatableInfinite then
                        button.ActivityXP:Hide();
                        button.Checkmark:Show();
                        button.BGAlphaAdd:Show();
                    else
                        button.ActivityXP:SetText(data.progressContributionAmount);
                        button.ActivityXP:Show();
                        button.Checkmark:Hide();
                        button.BGAlphaAdd:Hide();
                    end

                    button:UpdateTracked();
                end

                local function SubtaskInitializer(button)
                    button.Title:SetText(data.taskName);
                    button.ActivityXP:SetText(data.progressContributionAmount);
                end

                if not data.isSubtask then
                    factory("HousingDashboard_InitiativeTaskTemplate", TaskInitializer);
                else
                    factory("HousingDashboard_InitiativeSubtaskTemplate", SubtaskInitializer);
                end
            end)
            --Make adjustments to default layout
            --Fix top corner strata
            artFrame.BorderArt.InitiativesCornerTL:SetParent(isFrame)
            artFrame.BorderArt.InitiativesCornerTL:SetPoint("TOPLEFT",isFrame,"TOPLEFT",-4,2)
            artFrame.BorderArt.InitiativesCornerTR:SetParent(isFrame)
            artFrame.BorderArt.InitiativesCornerTR:SetPoint("TOPRIGHT",isFrame,"TOPRIGHT",4,2)
            --small adjustments
            isFrame.InitiativeTimer:SetPoint("TOPRIGHT", isFrame,"TOPRIGHT", 25,-135)
            isFrame.InitiativeName:SetPoint("TOPLEFT", isFrame, "TOPLEFT", 25, -2)
            isFrame.ProgressBar:SetPoint("TOP", isFrame.InitiativeDescription, "BOTTOM", 0, -20)
            isFrame.NeighborhoodGroupText:SetPoint("TOP", isFrame.InitiativeDescription, "BOTTOM", 5, -58)
            pFrame.TextContainer.ProgressText:Hide()
            pFrame:SetPoint("CENTER", isFrame, "CENTER",0,0)

            self.areFramesCreated = true
            self:UpdateCurrentProgressText()
        end
    end
end

function ehed:UpdateCurrentProgressText()
    if self.areFramesCreated then
        self.completionTimeFontString:Hide()
        local data = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
        self.lastGoodView = data.neighborhoodGUID
        self.hasLastGoodView = true
        local currprogress = HousingDashboardFrame.HouseInfoContent.ContentFrame.InitiativesFrame.InitiativeSetFrame.ProgressBar:GetValue() * 100
        local maxprogress = data.progressRequired * 100
        
        local contribution = data.playerTotalContribution *100
        local percent
        local contributionpercent
        if currprogress >= maxprogress and self.completionTime then 
            currprogress = maxprogress
            local completionDate = date(shared.L["Date Format"], self.completionTime)
            self.completionTimeFontString:Show()
            self.completionTimeFontString:SetText(shared.L["Completed"] .. completionDate or "")
        end
        if maxprogress ~= 0 then percent = (currprogress/maxprogress)*100 else percent = 0 end
        if currprogress ~= 0 then contributionpercent = (contribution/currprogress)*100 else contributionpercent = 0 end
        if type(currprogress) == "number" and type(percent) == "number" and percent ~= inf and type(maxprogress) == "number" and type(contribution) == "number" then
            self.progressFontString:SetText("(" .. BreakUpLargeNumbers(percent) .."%) " .. BreakUpLargeNumbers(currprogress) .. "/" .. BreakUpLargeNumbers(maxprogress))
            self.playerContributionFontString:SetText(shared.L["Your contribution"] .. ": " .. BreakUpLargeNumbers(contribution) .. " (" .. BreakUpLargeNumbers(contributionpercent) .. shared.L["% of current"] .. ")")
        else
            self.progressFontString:SetText("...")
            self.playerContributionFontString:SetText(shared.L["Your contribution"] .. ": " .. "")
        end
        self.houseXPLabel:SetText(ENDEAVOR_XP_TOOLTIP_AVAILABLE:format(BreakUpLargeNumbers(C_NeighborhoodInitiative.GetAvailableHouseXP())))
    elseif not self.areFramesCreated and HousingDashboardFrame then
        self:CreateFrames()
    end
end
function ehed:ParseActivityLog()
    local now = GetTime()
    if not self.last then self.last = 0 end
    if now < self.last + 0.5 then return end
    self.last = now
    local ranking = {}
    self.taskRankings = {}
    self.taskCount = {}
    self.playerTaskCount = {}
    self.completionTime = 0
    if self.areFramesCreated then
        local actitivyLog = C_NeighborhoodInitiative.GetInitiativeActivityLogInfo()
        if actitivyLog  then
            --Gather Task info
            for k,info in pairs(actitivyLog.taskActivity) do
                --Add up character contributions
                if not ranking[info.playerName] then
                    ranking[info.playerName] = 0
                end
                ranking[info.playerName] = ranking[info.playerName] + info.amount
                --Count all tasks
                if not self.taskCount[info.taskID] then
                    self.taskCount[info.taskID] = 0
                end
                if not self.playerTaskCount[info.taskID] then
                    self.playerTaskCount[info.taskID] = 0
                end
                self.taskCount[info.taskID] = self.taskCount[info.taskID] + 1
                if info.playerName == UnitName("player") then
                    self.playerTaskCount[info.taskID] = self.playerTaskCount[info.taskID] + 1
                end
                --Get completion time
                if info.amount and info.amount > 0 and info.completionTime and info.completionTime > self.completionTime then
                    self.completionTime = info.completionTime
                end
            end
            --Sort Task Info
            for player,playerContribution in pairs(ranking) do
                self.taskRankings[#self.taskRankings+1] = { name = player, contribution = playerContribution }
            end
            table.sort(self.taskRankings, self.SortRanks)
        else
            --Activity Log not available
            self.completionTime = nil
        end
    end
    if #self.taskRankings > 0 then
        self.firstRankFontString:SetText(self.taskRankings[1].name .. ":" )
        self.secondRankFontString:SetText(self.taskRankings[2].name .. ":")
        self.thirdRankFontString:SetText(self.taskRankings[3].name .. ":")
        self.firstRankScore:SetText(BreakUpLargeNumbers(self.taskRankings[1].contribution*100))
        self.secondRankScore:SetText(BreakUpLargeNumbers(self.taskRankings[2].contribution*100))
        self.thirdRankScore:SetText(BreakUpLargeNumbers(self.taskRankings[3].contribution*100))
    else
        self.firstRankFontString:SetText("? :" )
        self.secondRankFontString:SetText("? :")
        self.thirdRankFontString:SetText("? :")
        self.firstRankScore:SetText("?")
        self.secondRankScore:SetText("?")
        self.thirdRankScore:SetText("?")
    end
end
function ehed.SortRanks(A,B)
    if not B then return true end
    if not A then return false end
    return A.contribution > B.contribution
end
--Copy of Blizzard's RefreshTaskList()
-- function ehed:UpdateTaskList()
-- 	local taskList = {};
-- 	local dataProvider = CreateTreeDataProvider();
--     local data = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
--     local isFrame = HousingDashboardFrame.HouseInfoContent.ContentFrame.InitiativesFrame.InitiativeSetFrame
--     -- Task list from data is flat, traverse and build the task tree for the UI
-- 	for idx, task in ipairs(data.tasks) do
-- 		if not task.supersedes or task.supersedes == 0 then
-- 			-- toplevel task
-- 			task.children = {};
-- 			taskList[task.ID] = task;
-- 		else
-- 			-- child task
-- 			if taskList[task.supersedes] then
-- 				-- First child, insert into parent's children list if parent incomplete, otherwise make it the new parent
-- 				if taskList[task.supersedes].completed then
-- 					task.children = {};
-- 					taskList[task.ID] = task;
-- 				else
-- 					tinsert(taskList[task.supersedes].children, task);
-- 				end
-- 			else
-- 				-- Nth child, gotta find the parent then insert into children list
-- 				for _, parent in pairs(taskList) do
-- 					if #parent.children > 0 then
-- 						for _, child in pairs(parent.children) do
-- 							if task.supersedes == child.ID then
-- 								tinsert(parent.children, task);
-- 							end
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end

-- 	-- Now insert data into provider with our tree
-- 	for _, task in pairs(taskList) do
-- 		if #task.children > 0 then
-- 			local topLevelTaskData = { ID = task.ID, taskType = Enum.NeighborhoodInitiativeTaskType.RepeatableFinite, taskName = task.taskName, description = task.description, progressContributionAmount = task.progressContributionAmount, topLevel = true, sortOrder = task.sortOrder, completed = task.completed, requirementsList = task.requirementsList, tracked = task.tracked, rewardQuestID = task.rewardQuestID, hasChild = true};
-- 			local topLevelTask = dataProvider:Insert(topLevelTaskData);
-- 			for _, child in pairs(task.children) do
-- 				child.isSubtask = true;
-- 				topLevelTask:Insert(child);
-- 			end
-- 		else
-- 			dataProvider:Insert(task);
-- 		end
-- 	end

-- 	dataProvider:SetSortComparator(function(a, b)
-- 		local aData = a.data;
-- 		local bData = b.data;

-- 		-- if one of them is complete, return the incomplete first, else use sort order
-- 		if aData.completed ~= bData.completed then
-- 			return not aData.completed;
-- 		end
-- 		if aData.sortOrder and bData.sortOrder then
-- 			if aData.sortOrder < bData.sortOrder then
-- 				return true;
-- 			elseif aData.sortOrder > bData.sortOrder then
-- 				return false;
-- 			end
-- 		end
-- 	end);
-- 	dataProvider:Sort();

-- 	isFrame.InitiativeTasks.TaskList:SetEdgeFadeLength(30);
-- 	isFrame.InitiativeTasks.TaskList:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition);
-- end

-----------------------------House Finder-----------------------------
ehed.houseFinderQueue = {}
ehed.lastGoodView = ""
ehed.hasLastGoodView = false
function ehed:InitializeFinder()
    hooksecurefunc(HouseFinderFrame, "PopulateNeighborhoodList", function(HFFrame,info)ehed:FixNeighborhoodList(HFFrame.NeighborhoodListFrame.ScrollFrame.NeighborhoodList) end)
    hooksecurefunc(HouseFinderFrame, "PopulateBNetNeighborhoodList", function(HFFrame,info)ehed:FixNeighborhoodList(HFFrame.NeighborhoodListFrame.BNetScrollFrame.NeighborhoodList) end)
    HouseFinderFrame:HookScript("OnHide", function() ehed:RequestNeighborhoodInitiativeInfo(ehed.lastGoodView) end)
    HouseFinderFrame:HookScript("OnShow", function() ehed:UpdateHouseFinderInitiatives() end)
end
function ehed:FixNeighborhoodList(neighborhoodList)
        local f = neighborhoodList
        if not f then return end
        local children = {f:GetChildren()}
        for i,child in ipairs(children) do
            self.houseFinderQueue[i] = child --QUEUE all frames in finder.
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
        self:RequestNeighborhoodInitiativeInfo(self.houseFinderQueue[1].neighborhoodInfo.neighborhoodGUID)      
end

function ehed:RequestNeighborhoodInitiativeInfo(neighborhoodGUID)
    if not ehed.hasLastGoodView then 
        ehed.lastGoodView = neighborhoodGUID
        ehed.hasLastGoodView = true
    end
    C_NeighborhoodInitiative.SetViewingNeighborhood(neighborhoodGUID)
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
        self:RequestNeighborhoodInitiativeInfo(self.houseFinderQueue[1].neighborhoodInfo.neighborhoodGUID)
    elseif #self.houseFinderQueue <= 0 and self.hasLastGoodView then
        C_NeighborhoodInitiative.SetViewingNeighborhood(self.lastGoodView)
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

