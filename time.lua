Time = {}
Time.globalTime = 0
Time.playTime = 0
Time.isPlaying = true
Time.globalDilation = 1
Time.timelines = {}
Time.timelineUID = 1
Time.updateCallbacks = {}

function Time:update(dt)
    self.globalTime = self.globalTime + dt

    if self.isPlaying then
        self.playTime = self.playTime + dt

        if self.globalDilation > 0 then
            for k, timeline in pairs(self.timelines) do
                if timeline.active then
                    if timeline.ignoreGlobalDilation then
                        timeline:update(dt)
                    else
                        timeline:update(dt * self.globalDilation)
                    end
                end
            end

            for k, updatable in pairs(self.updateCallbacks) do 
                if updatable.update then
                    updatable:update(dt * self.globalDilation)
                else
                    print("Updatable does not have update function")
                end
            end
        end
    end
end

function Time:addUpdateCallback(object)
    table.insert(self.updateCallbacks, object)
end

function Time:addTimeline(timeline)
    timeline.UID = self.timelineUID
    self.timelineUID = self.timelineUID + 1

    self.timelines[timeline.UID] = timeline
end

function Time:getTimeline(UID)
    return self.timelines[UID]
end

function Time:setDilation(newDilation)
    self.dilation = floatMin(newDilation, 0)
end

function Time:addDilation(dDilation)
    self.dilation = floatMin(self.dilation + dDilation, 0)
end

function Time:draw()
    love.graphics.print("Global Time", 10, 10)
    love.graphics.print(self.globalTime, 150, 10)

    love.graphics.print("Play Time", 10, 25)
    love.graphics.print(self.playTime, 150, 25)

    love.graphics.print("Timeline Q", 10, 40)
    love.graphics.print(#self.timelines, 150, 40)

    love.graphics.print("Update Callback Q", 10, 55)
    love.graphics.print(#self.updateCallbacks, 150, 55)
end

Timeline = {}
Timeline.type = "Timeline"
Timeline_mt = {__index = Timeline}

function Timeline:new(duration, loop, autoActivate, ignoreGlobalDilation)
    local newTimeline = {}
    setmetatable(newTimeline, Timeline_mt)

    newTimeline.duration = duration or 1
    newTimeline.loop = loop or false
    newTimeline.active = autoActivate or false
    newTimeline.ignoreGlobalDilation = ignoreGlobalDilation or false
    newTimeline.currentTime = 0
    newTimeline.dilation = 1


    Time:addTimeline(newTimeline)

    return newTimeline
end

function Timeline:update(dt)
    self.currentTime = self.currentTime + dt * self.dilation

    if self.currentTime > self.duration then
        self:completed()

        if self.loop then

            if type(self.loop) == "number" then
                if self.loop < 1 then
                    self:deactivate()
                else
                    self.loop = self.loop - 1
                end
            end

            self.currentTime = self.currentTime - self.duration
        end
    end
end

function Timeline:getPercentageDone()
    return self.currentTime / self.duration
end

function Timeline:activate()
    self.active = true
end

function Timeline:deactivate()
    self.active = false
end

function Timeline:completed()
    self.active = false
    self.currentTime = 0
end

EventTimeline = {}
EventTimeline.type = "EventTimeline"
setmetatable(EventTimeline, Timeline_mt)
EventTimeline_mt = {__index = EventTimeline}

function EventTimeline:new(duration, loop, autoActivate, ignoreGlobalDilation)
    local newEventTimeline = Timeline:new(duration, loop, autoActivate, ignoreGlobalDilation)
    newEventTimeline.events = {}
    setmetatable(newEventTimeline, EventTimeline_mt)

    return newEventTimeline
end

function EventTimeline:addEvent(timelineEvent)
    table.insert(self.events, timelineEvent)
end

function EventTimeline:update(dt)
    local oldTime = self.currentTime

    Timeline.update(self, dt)

    for k, v in ipairs(self.events) do
        for l, time in ipairs(v.time) do
            if time > oldTime and time < self.currentTime then
                v.callbackFunction(callbackTable, self, l)
            end
        end
    end
end

TimelineEvent = {}
TimelineEvent_mt = {__index = TimelineEvent}

function TimelineEvent:new(time, callbackTable, callbackFunction)
    local newTimelineEvent = {}
    setmetatable(newTimelineEvent, TimelineEvent_mt)

    if type(time) == "number" then
        time = {time}
    end

    newTimelineEvent.time = time
    newTimelineEvent.callbackTable = callbackTable
    newTimelineEvent.callbackFunction = callbackFunction

    return newTimelineEvent
end


function floatMap(x, rangeAUpper, rangeALower, rangeBUpper, rangeBLower)
    return (x-rangeAUpper)/(rangeALower-rangeAUpper) * (rangeBLower-rangeBUpper) + rangeBUpper
end

function floatClamp(x, min, max)
    if min and max then
        if min > max then
            local temp = min
            min = max
            max = temp
        end
    end

    if min then
        if x < min then
            return min
        end
    end

    if max then
        if x > max then
            return max
        end
    end

    return x
end

function floatMin(x, min)
    if min then
        if x < min then
            return min
        end
    end

    return x
end

function floatMax(x, max)
    if max then
        if x > max then
            return max
        end
    end

    return x
end