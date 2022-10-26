module scheduler
export create_schedule, cleanEvents, checkFirstOrLast
# export setEvents, setBlocked, setLogic
# export getBlocked
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
    eventCount::Set{Tuple{String,Int64,Int64,String}}
    eventTimes::Set{Tuple{String,Int64,Int64,Int64,Int64,String}}
    logic::Set{Tuple{String,String,String}}
    blockedTimes::Set{Tuple{Int64,Int64,Int64,Int64,String}}
    hasFirst::Bool
    hasLast::Bool
    fitInterval::Int64
    allFirst::Set{String}
    allLast::Set{String}
    maxEventsLeft::Int64
    firstEvents::Dict{String, Vector{String}}
    lastEvents::Dict{String, Vector{String}}
    Scheduler() = new(
        Set(), Set(), Set(), Set(), false, false, 1, Set(), Set(), 0,
        Dict("monday"=>[],"tuesday"=>[],"wednesday"=>[],"thursday"=>[],"friday"=>[],"saturday"=>[],"sunday"=>[]),
        Dict("monday"=>[],"tuesday"=>[],"wednesday"=>[],"thursday"=>[],"friday"=>[],"saturday"=>[],"sunday"=>[]),
    )
end

function create_schedule(data::Scheduler)::Vector{Tuple{String,Int64,Int64}}
    itemsLeft = addEventsLeft(data)
    optimize(itemsLeft, data)
    schedule = addBlockedEvents(data)
    schedule = append!([("START", -1, 0)], schedule)
    push!(schedule, ("END", 40320, 40321))
    println("\u001b[96mItems left: ", itemsLeft, "\u001b[0m")
    println("\u001b[96mEvent count: ", data.eventCount, "\u001b[0m")
    println("\u001b[96mFirst events: ", data.allFirst, "\u001b[0m")
    backtrack(schedule, itemsLeft, 1, data)
    global schedule
    schedule = schedule[2:end-1]
    return schedule
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

function invalid(schedule::Vector{Tuple{String,Int64,Int64}}, index::Int64, data::Scheduler)::Bool
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
        if schedule[index][1] ∈ data.allFirst
            if checkFirstOrLast(schedule, true, data)
                return true
            end
        end
    end
    # if hasLastEvents:
    #     if checkFirstOrLast(schedule, false):
    #         return true
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
        #println(println(current))
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
        #println("\u001b[31mInvalid event count in day, count:", 
        #count, ", ", rule, "\u001b[0m")
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

function checkFirstOrLast(schedule::Vector{Tuple{String,Int64,Int64}}, first::Bool, data::Scheduler)::Bool
    lastCheckedDay = nothing
    for i in range(2, length(schedule) - 1)
        event = schedule[i]
        eventStartDay = event[2] ÷ 1440
        eventEndDay = event[3] ÷ 1440
        # Check if 
        if lastCheckedDay == eventStartDay
            if eventStartDay == eventEndDay
                continue
            else
                for day in range(eventStartDay + 1, eventEndDay +1)
                    allowed_events = data.firstEvents[
                        numberToWeek[(day % 7) + 1]]
                    lastCheckedDay = day
                    if allowed_events === nothing
                        continue
                    end
                    if event[1] ∉ allowed_events
                        return true
                    end
                end
            end
        else
            lastCheckedDay = eventStartDay
            # Check if event is the first
            for day in range(eventStartDay, eventEndDay)
                allowed_events = data.firstEvents[
                    numberToWeek[(day % 7) + 1]]
                lastCheckedDay = day
                if allowed_events === nothing
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
    if invalid(current, add_index, data)
        return false
    end
    if isempty(itemsLeft)
        global schedule
        schedule = current
        return true
    end

    # Recursive logic
    time = 0
    while true

        #println("\n\u001b[36mFit time ", time, "\u001b[0m")
        newCurrent, new_add_index, newTime = fit(
            current, itemsLeft[1], time)
        #println("\u001b[33mOld     \u001b[0m", current[2:end-1])
        #println("\u001b[33mNew try \u001b[0m", newCurrent[2:end-1])
        if newCurrent !== nothing
            #println(newCurrent, newTime)
            newItemsLeft = itemsLeft[2:end]
            if backtrack(newCurrent, newItemsLeft, new_add_index, data)
                return true
            end
            #println("Time change ", time, " to newTime: ", newTime)
            time = newTime
        end
        time += data.fitInterval
        if time > 40320
            break
        end
    end
    return false
end
end