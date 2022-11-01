module scheduler
using PlotlyJS, DataFrames, ColorSchemes, Colors
export create_schedule
export cleanEvents, checkFirst, checkLast, checkEventTimes
export createDataframe, fillEmptyGaps, separateMultidayEvents, plotSchedule
export Scheduler

weekToNumber = Dict([
    ("sunday", 0), ("monday", 1), ("tuesday", 2),
    ("wednesday", 3), ("thursday", 4), ("friday", 5),
    ("saturday", 6)
])
numberToWeek = String[
    "sunday", "monday", "tuesday", "wednesday",
    "thursday", "friday", "saturday"
]

mutable struct Scheduler
    """
    eventCount = Name, duration and repetition of events e.g.("math", 2, 3, "per week")
    eventTimes = Allowed times for a given event e.g.("math", 2, 34, 15, 7, "every day")
    logic = Sequential logic: which events go before or after others e.g.("math", "before", "chem")
    blockedTimes = Times where events cannot exist e.g.(12, 4, 21, 45, "per day")
    fitInterval = Interval between each event fit attempt
    firstEvents = Allowed first events for each weekday
    lastEvents = Allowed last events for each weekday
    hasTimes = If there are event times rules (for optimization)
    hasFirst = If there are first event rules (for optimization)
    hasLast = If there are last event rules   (for optimization)
    allTimes = All event times events         (for optimization)
    allFirst = All allowed first events       (for optimization)
    allLast = All allowed last events         (for optimization)
    maxEventsLeft = Total number of events    (for optimization)
    """
    schedule::Vector{Tuple{String,Int64,Int64}}
    eventCount::Set{Tuple{String,Int64,Int64,String}}
    eventTimes::Set{Tuple{String,Int64,Int64,Int64,Int64,String}}
    logic::Set{Tuple{String,String,String}}
    blockedTimes::Set{Tuple{Int64,Int64,Int64,Int64,String}}
    hasTimes::Bool
    hasFirst::Bool
    hasLast::Bool
    fitInterval::Int64
    allTimes::Set{String}
    allFirst::Set{String}
    allLast::Set{String}
    maxEventsLeft::Int64
    firstEvents::Dict{String, Vector{String}}
    lastEvents::Dict{String, Vector{String}}
    Scheduler() = new(
        [], Set(), Set(), Set(), Set(), false, false, false, 1, Set(), Set(), Set(), 0,
        Dict("monday"=>[],"tuesday"=>[],"wednesday"=>[],"thursday"=>[],"friday"=>[],"saturday"=>[],"sunday"=>[]),
        Dict("monday"=>[],"tuesday"=>[],"wednesday"=>[],"thursday"=>[],"friday"=>[],"saturday"=>[],"sunday"=>[]),
    )
end

function printConfig(data::Scheduler)
    println("\u001b[96mEvent count: ", data.eventCount, "\u001b[0m")
    println("\u001b[96mAll times: ", data.allTimes, "\u001b[0m")
    println("\u001b[96mFirst events: ", data.allFirst, "\u001b[0m")
    println("\u001b[96mLast events: ", data.allLast, "\u001b[0m")
end

function create_schedule(data::Scheduler)::Vector{Tuple{String,Int64,Int64}}
    itemsLeft = addEventsLeft(data)
    optimize(itemsLeft, data)
    data.schedule = addBlockedEvents(data)
    schedule = append!([("START", -1, 0)], data.schedule)
    push!(schedule, ("END", 40320, 40321))
    printConfig(data)
    backtrack(schedule, itemsLeft, 1, data)
    return data.schedule
end

function addEventsLeft(data::Scheduler)::Vector{Tuple{String, Int32}}
    itemsLeft = Tuple{String, Int32}[]
    for item in data.eventCount
        if item[4] == "per day"
            for _ in 1:item[2] * 28
                push!(itemsLeft, (item[1], item[3]))
            end
        elseif item[4] == "per week"
            for _ in 1:item[2] * 4
                push!(itemsLeft, (item[1], item[3]))
            end
        elseif item[4] == "per month"
            for _ in 1:item[2]
                push!(itemsLeft, (item[1], item[3]))
            end
        else
            for _ in 1:item[2] * 4
                push!(itemsLeft, (item[1], item[3]))
            end
        end
    end
    return itemsLeft
end

function cleanEvents(blocks::Vector{Tuple{String,Int64,Int64}})::Vector{Tuple{String,Int64,Int64}}
    """Assumes blocks are sorted by starting time."""
    if isempty(blocks)
        return blocks
    end

    cleaned = [blocks[1]]
    for i in range(2, length(blocks))
        current = blocks[i]
        if cleaned[end][3] ≥ current[2] && cleaned[end][1] == current[1]
            cleaned[end] = (cleaned[end][1], cleaned[end][2], current[3])
        else
            push!(cleaned, current)
        end
    end
    return cleaned
end

function optimize(left::Vector{Tuple{String, Int32}}, data::Scheduler)
    firstEventList = values(data.firstEvents)
    if any(x -> !isempty(x), firstEventList)
        data.hasFirst = true
        firstEvents = Vector{String}()
        for items in firstEventList
            if !isempty(items)
                append!(firstEvents, items)
            end
        end
        data.allFirst = Set(firstEvents)
    end

    lastEventList = values(data.lastEvents)
    if any(x -> !isempty(x), lastEventList)
        data.hasLast = true
        lastEvents = Vector{String}()
        for items in lastEventList
            if !isempty(items)
                append!(lastEvents, items)
            end
        end
        data.allLast = Set(lastEvents)
    end

    data.hasTimes = !isempty(data.eventTimes)
    if data.hasTimes
        eventTimes = Vector{String}()
        for event in data.eventTimes
            push!(eventTimes, event[1])
        end
        data.allTimes = Set(eventTimes)
    end

    data.maxEventsLeft = length(left)
end

function addBlockedEvents(data::Scheduler)::Vector{Tuple{String,Int64,Int64}}
    blocks = Vector{Tuple{String,Int64,Int64}}()
    for block in data.blockedTimes
        frequency = split(block[5], " ")
        if frequency[2] == "day"
            for day in range(0, 27)
                add = (
                    "BLOCKED",
                    (1440 * day) + (block[1] * 60) + block[2],
                    (1440 * day) + (block[3] * 60) + block[4])
                push!(blocks, add)
            end
        elseif length(frequency) == 3
            continue
        else
            for week in range(0, 3)
                add = (
                    "BLOCKED",
                    (week * 10080) + (weekToNumber[frequency[2]] * 1440) +
                    (block[1] * 60) + block[2],
                    (week * 10080) + (weekToNumber[frequency[2]] * 1440) +
                    (block[3] * 60) + block[4]
                )
                push!(blocks, add)
            end
        end
    end
    return cleanEvents(sort(blocks))
end

function invalid(schedule::Vector{Tuple{String,Int64,Int64}}, index::Int64, isFull::Bool, data::Scheduler)::Bool
    # No schedule that is incorrect but could be correct later shall be rejected here
    if data.hasTimes
        if schedule[index][1] ∈ data.allTimes
            if checkEventTimes(schedule, index, data)
                return true
            end
        end
    end
    if length(schedule) < 3
        return false
    end
    if length(schedule) > 3
        if checkEventLogic(schedule, index, data)
            return true
        end
    end
    if checkEventCount(schedule, index, data)
        return true
    end
    if data.hasFirst
        if isFull
            if checkFirst(schedule, data)
                return true
            end
        end
    end
    if data.hasLast
        if isFull
            if checkLast(schedule, data)
                return true
            end
        end
    end
    return false
end

function checkEventLogic(schedule::Vector{Tuple{String,Int64,Int64}}, index::Int64, data::Scheduler)::Bool
    for logic_rule in data.logic
        if index == 1
            before = schedule[end]
        else
            before = schedule[index - 1]
        end
        event = schedule[index]
        after = schedule[index + 1]
        if logic_rule[1] == event[1]
            if logic_rule[2] == "before"
                if (before[3] ÷ 1440) != (event[2] ÷ 1440)
                    continue
                end
                if logic_rule[3] != after[1]
                    return true
                end
            else  # "after"
                if (before[3] ÷ 1440) != (event[2] ÷ 1440)
                    continue
                end
                if logic_rule[3] != before[1]
                    return true
                end
            end     
        elseif logic_rule[3] == event[1]
            if logic_rule[2] == "before"
                if (after[3] ÷ 1440) != (event[2] ÷ 1440)
                    continue
                end
                if logic_rule[1] != before[1]
                    return true
                end
            else  # "after"
                if (before[3] ÷ 1440) != (event[2] ÷ 1440)
                    continue
                end
                if logic_rule[1] != after[1]
                    return true
                end
            end
        end
    end
    return false
end

function checkEventCount(schedule::Vector{Tuple{String,Int64,Int64}}, index::Int64, data::Scheduler)::Bool
    event = schedule[index]
    name = event[1]
    for rule in data.eventCount
        # Check if event has the same name as rule
        if name != rule[1]
            continue
        end
        # Check if event has the same duration as rule
        duration = rule[3]
        if (event[3] - event[2]) != duration 
            continue
        end
        # Check if event is using a per weekday repetition E.g. per monday
        period = split(rule[4], " ")[2]
        if period ∈ numberToWeek 
            # Check if the event location matches the rule weekday
            day = event[2] ÷ 1440
            if weekToNumber[period] != (day % 7) 
                return true
            end
            if checkEventCountInDay(schedule, day, index, rule) 
                return true
            end
        elseif period == "week" 
            week = (event[2] ÷ 1440) ÷ 7
            if checkEventCountInWeek(schedule, week, index, rule) 
                return true
            end
        elseif period == "month" 
            if checkEventCountInMonth(schedule, rule) 
                return true
            end
        else # "day"
            day = event[2] ÷ 1440
            if checkEventCountInDay(schedule, day, index, rule) 
                return true
            end
        end
    end
    return false
end

function checkEventCountInDay(schedule::Vector{Tuple{String,Int64,Int64}}, day::Int64, index::Int64, rule::Tuple{String,Int64,Int64,String})::Bool
    current = index - 1
    count = 1
    # Count events going backwards from added element
    while true
        if current == 0
            break
        end
        event = schedule[current]
        event_day = event[3] ÷ 1440
        # Check if no more events in target day
        if event_day != day
            break
        end
        # Check if rule applies to current event
        if event[1] != rule[1]
            current -= 1
            continue
        end
        # Check if event duration is the same as rule duration
        if (event[3] - event[2]) != rule[3]
            continue
        end
        count += 1
        current -= 1
        
    end

    # Count events going forward -->
    current = index + 1
    while true
        event = schedule[current]
        event_day = event[2] ÷ 1440
        # Check if no more events in target day
        if event_day != day
            break
        end
        # Check if rule applies to current event
        if event[1] != rule[1]
            current += 1
            continue
        end
        # Check if event duration is the same as rule duration
        if (event[3] - event[2]) != rule[3]
            continue
        end
        count += 1
        current += 1
    end

    if count > rule[2]
        return true
    end
    return false
end

function checkEventCountInWeek(schedule::Vector{Tuple{String,Int64,Int64}}, week::Int64, index::Int64, rule::Tuple{String,Int64,Int64,String})::Bool
    current = index - 1
    count = 1
    # Count events going backwards <--
    while true
        event = schedule[current]
        if event == ("START", -1, 0)
            break
        end
        event_week = (event[3] ÷ 1440) ÷ 7
        # Check if no more events in target week
        if event_week != week
            break
        end
        # Check if rule applies to current event
        if event[1] != rule[1]
            current -= 1
            continue
        end
        # Check if event duration is the same as rule duration
        if (event[3] - event[2]) != rule[3]
            continue
        end
        count += 1
        current -= 1
    end

    # Count events going forward -->
    current = index + 1
    while true
        event = schedule[current]
        if event == ("END", 40320, 40321)
            break
        end
        event_week = (event[2] ÷ 1440) ÷ 7
        # Check if no more events in target week
        if event_week != week
            break
        end
        # Check if rule applies to current event
        if event[1] != rule[1]
            current += 1
            continue
        end
        # Check if event duration is the same as rule duration
        if (event[3] - event[2]) != rule[3]
            continue
        end
        count += 1
        current += 1
    end

    if count > rule[2]
        return true
    end
    return false
end

function checkEventCountInMonth(schedule::Vector{Tuple{String,Int64,Int64}}, rule::Tuple{String,Int64,Int64,String})::Bool
    count = 0
    for event in schedule
        # Check if rule applies to current event
        if event[1] != rule[1]
            continue
        end
        # Check if event duration is the same as rule duration
        if (event[3] - event[2]) != rule[3]
            continue
        end
        count += 1
    end

    if count > rule[2]
        return true
    end
    return false
end

function checkFirst(schedule::Vector{Tuple{String,Int64,Int64}}, data::Scheduler)::Bool
    lastCheckedDay = nothing
    for i in range(2, length(schedule) - 1)
        event = schedule[i]
        eventStartDay = event[2] ÷ 1440
        eventEndDay = event[3] ÷ 1440
        if lastCheckedDay == eventStartDay
            if eventStartDay == eventEndDay
                continue
            else
                for day in range(eventStartDay + 1, eventEndDay +1)
                    allowed_events = data.firstEvents[
                        numberToWeek[(day % 7) + 1]]
                    lastCheckedDay = day
                    # Check if there are any rules for the day
                    if isempty(allowed_events)
                        continue
                    end
                    if event[1] ∉ allowed_events
                        return true
                    end
                end
            end
        else
            lastCheckedDay = eventStartDay
            # Check if event is the first event of the start day until the end day
            for day in range(eventStartDay, eventEndDay)
                allowed_events = data.firstEvents[
                    numberToWeek[(day % 7) + 1]]
                lastCheckedDay = day
                # Check if there are any rules for the day
                if isempty(allowed_events)
                    continue
                end
                if event[1] ∉ allowed_events
                    return true
                end
            end
        end
    end
    return false
end

function checkLast(schedule::Vector{Tuple{String,Int64,Int64}}, data::Scheduler)::Bool
    lastCheckedDay = nothing
    for i in range(length(schedule) - 1, 2, step=-1)
        event = schedule[i]
        eventStartDay = event[2] ÷ 1440
        eventEndDay = event[3] ÷ 1440
        if lastCheckedDay == eventStartDay
            if eventStartDay == eventEndDay
                continue
            else
                for day in range(eventEndDay +1, eventStartDay + 1, step=-1)
                    allowed_events = data.lastEvents[
                        numberToWeek[(day % 7) + 1]]
                    lastCheckedDay = day
                    # Check if there are any rules for the day
                    if isempty(allowed_events)
                        continue
                    end
                    if event[1] ∉ allowed_events
                        return true
                    end
                end
            end
        else
            lastCheckedDay = eventEndDay
            # Check if event is the last event of the end day until the start day
            for day in range(eventEndDay, eventStartDay, step=-1)
                allowed_events = data.lastEvents[
                    numberToWeek[(day % 7) + 1]]
                lastCheckedDay = day
                # Check if there are any rules for the day
                if isempty(allowed_events)
                    continue
                end
                if event[1] ∉ allowed_events
                    return true
                end
            end
        end
    end
    return false
end

function checkEventTimes(schedule::Vector{Tuple{String,Int64,Int64}}, index::Int64, data::Scheduler)::Bool
    # Current schedule is only valid if one rule fully allows it
    event = schedule[index]
    eventStartDay = (event[2] ÷ 1440)

    for rule in data.eventTimes
        if event[1] != rule[1] continue end
        if rule[6] == "every day"
            # Checks absolute allowed time (uses event minute system)
            allowedStart = (eventStartDay * 1440) + (rule[2] * 60) + rule[3]
            allowedEnd = (eventStartDay * 1440) + (rule[4] * 60) + rule[5]
            if allowedEnd < allowedStart # For rules that end in the next day
                allowedEnd += 1440
            end
            if event[2] >= allowedStart && event[3] <= allowedEnd 
                return false 
            end
        else # weekdays
            weekNumber = weekToNumber[split(rule[6], " ")[2]]
            # Iterate over absolute allowed times (uses event minute system)
            for i in range(0, 3)
                allowedStart = ((weekNumber + i) * 1440) + (rule[2] * 60) + rule[3]
                allowedEnd = ((weekNumber + i) * 1440) + (rule[4] * 60) + rule[5]
                if allowedEnd < allowedStart # For rules that end in the next day
                    allowedEnd += 1440
                end
                if event[2] >= allowedStart && event[3] <= allowedEnd 
                    return false 
                end
            end
        end
    end
    return true
end

function fit(current::Vector{Tuple{String,Int64,Int64}}, item::Tuple{String, Int32}, time::Int64)#::Tuple{Vector{Tuple{String,Int64,Int64}},Int64,Int64}
    # Check if the event being fitted can fit at the specified location
    # check if the two adjacent events allow it to be fitted between
    index = nothing
    new_time = 0
    duration = 0
    for i in range(1, length(current) - 1)
        start1, end1 = current[i][2:3]
        start2 = current[i + 1][2]
        duration = item[2]
        if time ≥ start1 && time < end1
            # Time is in the middle of event1
            # Jump to the end of event1 and place event
            if (end1 + duration) < start2
                index = i + 1
                new_time = end1
                break
            end
        elseif time ≥ end1 && time < start2
            # Time is between event1 and event2
            if (time + duration) ≤ start2
                index = i + 1
                new_time = time
                break
            end
        end
    end

    if index === nothing
        return nothing, 0, time
    end

    # Fit the event and return
    newCurrent = current[:]
    insert!(newCurrent, index, (item[1], new_time, (new_time + duration)))
    return newCurrent, index, new_time
end

function backtrack(current::Vector{Tuple{String,Int64,Int64}}, itemsLeft::Vector{Tuple{String, Int32}}, add_index::Int64, data::Scheduler)::Bool
    # Base cases
    if invalid(current, add_index, isempty(itemsLeft), data)
        return false
    end
    if isempty(itemsLeft)
        data.schedule = current[2:end-1]
        return true
    end

    # Recursive logic
    time = 0
    a = length(itemsLeft)
    while true
        # if a == data.maxEventsLeft
        #     println(time)
        # end
        newCurrent, new_add_index, newTime = fit(
            current, itemsLeft[1], time)
        if newCurrent !== nothing
            newItemsLeft = itemsLeft[2:end]
            if backtrack(newCurrent, newItemsLeft, new_add_index, data)
                return true
            end
            time = newTime
        end
        time += data.fitInterval
        if time > 40320
            break
        end
    end
    return false
end

function fillEmptyGaps(oldSchedule::Vector{Tuple{String,Int64,Int64}})::Vector{Tuple{String,Int64,Int64}}
    """
    Fill empty gaps between event so that every minute has a related event.
    """
    schedule = []
    push!(schedule, ("", -1, 0))
    append!(oldSchedule, [("END", 40320, 40321)])

    for event in oldSchedule
        if event[2] != schedule[end][3]
            push!(schedule, ("", schedule[end][3], event[2]))
        end
        push!(schedule, event)
    end
    return schedule[2:end-1]
end

function separateMultidayEvents(schedule::Vector{Tuple{String,Int64,Int64}})::Vector{Tuple{String,Int64,Int64}}
    newSchedule = []
    for event in schedule
        startDay = event[2] ÷ 1440
        endDay = event[3] ÷ 1440
        if event[3] % 1440 == 0
            endDay -= 1
        end
        if startDay != endDay
            push!(newSchedule, (event[1], event[2], (startDay + 1) * 1440))
            for day in range(startDay + 1, endDay - 1)
                push!(newSchedule, (event[1], day * 1440, (day + 1) * 1440))
            end
            push!(newSchedule, (event[1], endDay * 1440, event[3]))
        else
            push!(newSchedule, event)
        end
    end
    return newSchedule
end

function createDataframe(data::Vector{Tuple{String,Int64,Int64}})::Vector{DataFrame}
    """
    Creates the dataframes used to plot the schedule graphs.
    """
    # After separateMultidayEvents(), events are assumed to not be multiday
    filledSchedule = fillEmptyGaps(data)
    schedule = separateMultidayEvents(filledSchedule)

    # Events are separated into dataframes representing the 4 weeks of a month
    w1 = DataFrame(name=String[], day=String[], hour=Float64[], order=Int64[], fill_color=RGB[],opacity=Float16[], line_color=RGB[], display=String[])
    w2 = DataFrame(name=String[], day=String[], hour=Float64[], order=Int64[], fill_color=RGB[],opacity=Float16[], line_color=RGB[], display=String[])
    w3 = DataFrame(name=String[], day=String[], hour=Float64[], order=Int64[], fill_color=RGB[],opacity=Float16[], line_color=RGB[], display=String[])
    w4 = DataFrame(name=String[], day=String[], hour=Float64[], order=Int64[], fill_color=RGB[],opacity=Float16[], line_color=RGB[], display=String[])
    weeks = [w1, w2, w3, w4]
    pos = 0

    # Unique and distinguishable colors are created for each event
    uniqueElements = Set([i[1] for i in schedule])
    uniqueCount = length(uniqueElements)
    scheme = ColorScheme(distinguishable_colors(uniqueCount, [RGB(1,1,1), RGB(0,0,0)], dropseed=true))
    Allcolors = get(scheme, [i/(uniqueCount-1) for i in range(0, uniqueCount-1)])
    colors = Dict(pop!(uniqueElements) => color for color in Allcolors)
    
    # Add each event to the appropriate DataFrame
    for event in schedule
        day = event[3] ÷ 1440
        timeEnd = (event[3] / 60) % 24
        if event[3] % 1440 == 0
            timeEnd = 24
            day -= 1
        end
        timeStart = (event[2] / 60) % 24
        weekday = numberToWeek[(day%7)+1]
        height = timeEnd - timeStart
        timeStart = (event[2] / 60) % 24
        index = ((event[2] ÷ 1440) ÷ 7) + 1
        fill_color = colors[event[1]]
        line_color = RGB(0,0,0)
        fill_opacity = 1.0
        if event[1] == ""  # Spaces between events are background colored
            fill_color = RGB(0,0,1)
            fill_opacity = 0.0
            line_color = RGB(0,0,0)
        end
        text = string(event[2], "-", event[3], "<br>", 23)
        push!(weeks[index], (event[1], weekday, height, pos, fill_color,fill_opacity,line_color, text))
        pos -= 1
    end
    return weeks
end

function plotSchedule(df::DataFrame)
    """
    Plots the schedule using the provided DataFrame.
    Assumes DataFrame has been provided by createDataframe().
    """
    layout = Layout(
        title_text="Week 1", height=500,
        barmode="stack", showlegend=false,
        xaxis=attr(
            categoryorder="array", 
            categoryarray=["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], showgrid=true
        ),
        yaxis=attr(
            tickmode="linear", dtick=1, range=[0, 24], showgrid=true
        ),
    )
    config = PlotConfig(
        scrollZoom=false, displayModeBar=false
    )
    fig = plot(
        df, x=:x, y=:y, marker_color=:color, text=:name, hovertext=:display,
        kind="bar", layout=layout, config=config, marker_line=attr(color="black", width=0.2),
        hovertemplate="%{hovertext}"
    )
    return fig
    end

end