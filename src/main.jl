using Dash, DashBootstrapComponents

items = String[
    string("test", i) for i in range(1, 200)
]
event_count = Set{Tuple{String,Int64,Int64,String}}([
    ("math", 2, 3, "per week")])
blocked_times = Set{Tuple{Int64,Int64,Int64,Int64,String}}([
    (12, 4, 21, 45, "per day")
])
event_times = Set{Tuple{String,Int64,Int64,Int64,Int64,String}}([
    ("math", 2, 34, 15, 7, "every day")
])
logic = Set{Tuple{String, String, String}}([
    ("math", "before", "meth")
])
first_events = Dict{String, Vector{String}}(
    "monday"=>[], "tuesday"=>[],
    "wednesday"=>[], "thursday"=>[],
    "friday"=>[], "saturday"=>[],
    "sunday"=>[]
)
last_events = Dict{String, Vector{String}}(
    "monday"=>[], "tuesday"=>[],
    "wednesday"=>[], "thursday"=>[],
    "friday"=>[], "saturday"=>[],
    "sunday"=>[]
)
frequency_checklist_pattern = r"(?P<event>.+) (?P<frequency>[0-9]+)x(?P<duration>[0-9]+)min (?P<interval>per [a-z]+)"
blocked_checklist_pattern = r"(?P<hour1>[0-9]+):(?P<minutes1>[0-9]+)-(?P<hour2>[0-9]+):(?P<minutes2>[0-9]+) (?P<interval>every .+)"
allowed_checklist_pattern = r"(?P<event>.+) (?P<hour1>[0-9]+):(?P<minutes1>[0-9]+)-(?P<hour2>[0-9]+):(?P<minutes2>[0-9]+) (?P<interval>every .+)"
logic_checklist_pattern = r"(?P<event1>.+) (?P<logic>before|after) (?P<event2>.+)"

app = dash(
    external_stylesheets=[dbc_themes.BOOTSTRAP]
)

app.layout = html_div(style=Dict("padding" => "15px")) do 
    dbc_row([
        html_h1(
            "Automatic event scheduler", 
            style=Dict("margin-bottom" => "5px")
        ),
        html_h6("by Pedro Kobori", style=Dict("margin-bottom" => "25px"))
    ]),
    dbc_row([
        dbc_col([dbc_accordion([
            dbc_accordionitem([dbc_row([
                dbc_col([
                    html_h6("Add and remove events"),
                    dbc_input(
                        id="events_input",
                        placeholder="Press enter to add event",
                        type="text",
                        debounce=true,
                        size="md",
                        maxlength="25"),
                    dbc_tooltip(
                        "Input will automatically be formatted \
                            to lowercase",
                        target="events_input", placement="right")
                ]),
                dbc_col([
                    html_h6("Define event frequency"),
                    dbc_select(
                        id="select_event", 
                        placeholder="Event"),
                    dbc_row([
                        dbc_col(dbc_input(
                            id="select_frequency",
                            placeholder="Frequency",
                            size="md", type="number"
                        )),
                        dbc_col([
                            dbc_input(
                                id="select_duration",
                                placeholder="Duration",
                                size="md", type="number"),
                            dbc_tooltip(
                                "Type value in minutes (maximum value is 1440)",
                                target="select_duration")
                        ])
                    ], className="g-0"),
                    dbc_select(
                        id="select_interval", placeholder="Interval", 
                        options=[
                            Dict("label"=>"per day", "value"=>"per day"),
                            Dict("label"=>"per week", "value"=>"per week"),
                            Dict("label"=>"per month", "value"=>"per month"),
                            Dict("label"=>"per monday", "value"=>"per monday"),
                            Dict("label"=>"per tuesday", "value"=>"per tuesday"),
                            Dict("label"=>"per wednesday", "value"=>"per wednesday"),
                            Dict("label"=>"per thursday", "value"=>"per thursday"),
                            Dict("label"=>"per friday", "value"=>"per friday"),
                            Dict("label"=>"per saturday", "value"=>"per saturday"),
                            Dict("label"=>"per sunday", "value"=>"per sunday")]
                    ),
                    dbc_button(
                        "Add frequency rule", id="frequency_button",
                        color="secondary", outline=false)
                ]),
                dbc_col([
                    html_h6("Define blocked periods"),
                    dbc_row([
                        dbc_col(dbc_input(
                            id="select_hour1",
                            placeholder="Hour 1",
                            size="md", type="number",
                            min=0, max=23, step=1)),
                        dbc_col(dbc_input(
                            id="select_minutes1",
                            placeholder="Minute 1",
                            size="md", type="number",
                            min=0, max=59, step=1))
                    ], className="g-0"),
                    dbc_row([
                        dbc_col(dbc_input(
                            id="select_hour2",
                            placeholder="Hour 2",
                            size="md", type="number",
                            min=0, max=23, step=1)),
                        dbc_col(dbc_input(
                            id="select_minutes2",
                            placeholder="Minute 2",
                            size="md", type="number",
                            min=0, max=59, step=1)),
                        dbc_select(
                            id="select_blocked_interval", placeholder="Interval", 
                            options= [
                                Dict("label"=>"every day", "value"=>"every day"),
                                Dict("label"=>"every week", "value"=>"every week"),
                                Dict("label"=>"every month", "value"=>"every month"),
                                Dict("label"=>"every monday", "value"=>"every monday"),
                                Dict("label"=>"every tuesday", "value"=>"every tuesday"),
                                Dict("label"=>"every wednesday", "value"=>"every wednesday"),
                                Dict("label"=>"every thursday", "value"=>"every thursday"),
                                Dict("label"=>"every friday", "value"=>"every friday"),
                                Dict("label"=>"every saturday", "value"=>"every saturday"),
                                Dict("label"=>"every sunday", "value"=>"every sunday")]
                        ),
                        dbc_button(
                            "Add blocked rule", id="blocked_button",
                            color="secondary", outline=false)
                    ], className="g-0")
                ])
            ])], 
                title="Add events, Define frequency and Free time ↓", 
                item_id="a1"),
            dbc_accordionitem([
                dbc_row([
                    dbc_col(html_h6("Sunday"), width=2),
                    dbc_col(dcc_dropdown(id="first_sunday",
                        placeholder="First event", multi=true)),
                    dbc_col(dcc_dropdown(id="last_sunday",
                        placeholder="Last event", multi=true))
                ], className="g-0"),
                dbc_row([
                    dbc_col(html_h6("Monday"), width=2),
                    dbc_col(dcc_dropdown(id="first_monday",
                        placeholder="First event", multi=true)),
                    dbc_col(dcc_dropdown(id="last_monday",
                        placeholder="Last event", multi=true))
                ], className="g-0"),
                dbc_row([
                    dbc_col(html_h6("Tuesday"), width=2),
                    dbc_col(dcc_dropdown(id="first_tuesday",
                        placeholder="First event", multi=true)),
                    dbc_col(dcc_dropdown(id="last_tuesday",
                        placeholder="Last event", multi=true))
                ], className="g-0"),
                dbc_row([
                    dbc_col(html_h6("Wednesday"), width=2),
                    dbc_col(dcc_dropdown(id="first_wednesday",
                        placeholder="First event", multi=true)),
                    dbc_col(dcc_dropdown(id="last_wednesday",
                        placeholder="Last event", multi=true))
                ], className="g-0"),
                dbc_row([
                    dbc_col(html_h6("Thursday"), width=2),
                    dbc_col(dcc_dropdown(id="first_thursday",
                        placeholder="First event", multi=true)),
                    dbc_col(dcc_dropdown(id="last_thursday",
                        placeholder="Last event", multi=true))
                ], className="g-0"),
                dbc_row([
                    dbc_col(html_h6("Friday"), width=2),
                    dbc_col(dcc_dropdown(id="first_friday",
                        placeholder="First event", multi=true)),
                    dbc_col(dcc_dropdown(id="last_friday",
                        placeholder="Last event", multi=true))
                ], className="g-0"),
                dbc_row([
                    dbc_col(html_h6("Saturday"), width=2),
                    dbc_col(dcc_dropdown(id="first_saturday",
                        placeholder="First event", multi=true)),
                    dbc_col(dcc_dropdown(id="last_saturday",
                        placeholder="Last event", multi=true))
                ], className="g-0")
            ],
                title="First and Last events of the day ↓", 
                item_id="a2"),
            dbc_accordionitem([dbc_row([
                dbc_col([
                    html_h6("Define allowed times"),
                    dbc_select(
                        id="select_allowed_event",
                        placeholder="Event"),
                    dbc_row([
                        dbc_col(dbc_input(
                            id="allowed_hour1",
                            placeholder="Hour 1",
                            size="md", type="number",
                            min=0, max=23, step=1)),
                        dbc_col(dbc_input(
                            id="allowed_minutes1",
                            placeholder="Minute 1",
                            size="md", type="number",
                            min=0, max=59, step=1))
                    ], className="g-0"),
                    dbc_row([
                        dbc_col(dbc_input(
                            id="allowed_hour2",
                            placeholder="Hour 2",
                            size="md", type="number",
                            min=0, max=23, step=1)),
                        dbc_col(dbc_input(
                            id="allowed_minutes2",
                            placeholder="Minute 2",
                            size="md", type="number",
                            min=0, max=59, step=1))
                    ], className="g-0"),
                    dbc_select(
                        id="select_allowed_interval", placeholder="Interval", 
                        options= [
                            Dict("label"=>"every day", "value"=>"every day"),
                            Dict("label"=>"every monday", "value"=>"every monday"),
                            Dict("label"=>"every tuesday", "value"=>"every tuesday"),
                            Dict("label"=>"every wednesday", "value"=>"every wednesday"),
                            Dict("label"=>"every thursday", "value"=>"every thursday"),
                            Dict("label"=>"every friday", "value"=>"every friday"),
                            Dict("label"=>"every saturday", "value"=>"every saturday"),
                            Dict("label"=>"every sunday", "value"=>"every sunday")]
                    ),
                    dbc_button(
                        "Add allowed rule", id="allowed_button",
                        color="secondary", outline=false)
                ]),
                dbc_col([
                    html_h6("Define sequential logic"),
                    dbc_select(
                        id="select_logic_event1",
                        placeholder="Event"),
                    dbc_select(
                        id="select_logic_interval", placeholder="Before or after", 
                        options= [
                            Dict("label"=>"before", "value"=>"before"),
                            Dict("label"=>"after", "value"=>"after")]
                    ),
                    dbc_select(
                        id="select_logic_event2",
                        placeholder="Event"),
                    dbc_button(
                        "Add logic rule", id="logic_button",
                        color="secondary", outline=false)
                ])
            ])],
                title="Breaks and Allowed event times ↓", 
                item_id="a3")
        ], always_open=true, active_item=["a1", "a2", "a3"])]),
        dbc_col([
            dbc_tabs([
                dbc_tab(label="Events", tab_id="Events", children=[
                    dbc_col([
                        dcc_checklist(
                            id="event_checklist",
                            labelStyle=Dict("display"=>"block"),
                            persistence=true,
                            persistence_type="local",
                            className="mainChecklistStyle")
                    ], className="checklistContainer")                    
                ]),
                dbc_tab(label="Frequency", tab_id="Frequency", children=[
                    dbc_col([
                        dcc_checklist(
                            id="frequency_rules_checklist",
                            labelStyle=Dict("display"=>"block"),
                            persistence=true,
                            persistence_type="local",
                            className="subChecklistStyle")
                    ], className="checklistContainer")                    
                ]),
                dbc_tab(label="Blocked", tab_id="Blocked", children=[
                    dbc_col([
                        dcc_checklist(
                            id="blocked_rules_checklist",
                            labelStyle=Dict("display"=>"block"),
                            persistence=true,
                            persistence_type="local",
                            className="subChecklistStyle")
                    ], className="checklistContainer")                    
                ]),
                dbc_tab(label="Allowed", tab_id="Allowed", children=[
                    dbc_col([
                        dcc_checklist(
                            id="allowed_rules_checklist",
                            labelStyle=Dict("display"=>"block"),
                            persistence=true,
                            persistence_type="local",
                            className="subChecklistStyle")
                    ], className="checklistContainer")                    
                ]),
                dbc_tab(label="Sequential", tab_id="Sequential", children=[
                    dbc_col([
                        dcc_checklist(
                            id="logic_rules_checklist",
                            labelStyle=Dict("display"=>"block"),
                            persistence=true,
                            persistence_type="local",
                            className="subChecklistStyle")
                    ], className="checklistContainer")                    
                ])
            ], active_tab="Sequential"),
        ])
    ]),
    dbc_row([
        dbc_row([
            dbc_col(
                dcc_upload(
                    dbc_button("Upload configuration.ini",
                        id="upload_config", color="info", outline=false))
            ),
            dbc_col([
                dbc_button("Download configuration.ini",
                    color="info", outline=false),
                dcc_download(id="download_config")
            ]),
            dbc_col([                
                dbc_button("Download schedule",
                    color="info", outline=false),
                dcc_download(id="download_schedule")
            ])
        ], style=Dict("margin-bottom" => "15px")),
        dbc_row([
            dbc_col(dbc_input(
                        id="select_fit_interval",
                        placeholder="Event fit interval",
                        size="md", type="number",
                        min=1, max=10080, step=1), width=8),
            dbc_tooltip(
                "Select how often a pending event should \
                    try a fit after another set event. Note that \
                        more frequent fits take more time to process",
                target="select_fit_interval"),
            dbc_col(dbc_button(
                "Make schedule", id="make_schedule_button",
                color="success", outline=false
            ))
        ], style=Dict("margin-bottom" => "15px")),
        dbc_row([
            dbc_col(dbc_button(
                "Week 1", id="select_week_1",
                color="primary", outline=false)),
            dbc_col(dbc_button(
                "Week 2", id="select_week_2",
                color="primary", outline=false)),
            dbc_col(dbc_button(
                "Week 3", id="select_week_3",
                color="primary", outline=false)),
            dbc_col(dbc_button(
                "Week 4", id="select_week_4",
                color="primary", outline=false))
        ], style=Dict("margin-bottom" => "15px")),
        dbc_row(
            dcc_graph(id="schedule")
        )
    ], style=Dict("margin-top" => "20px"))
end


# Update event list
callback!(app,
    Output("events_input", "value"),
    Input("events_input", "value")
) do event_input
    if event_input !== nothing
        clean_input = strip(event_input, ' ')
        if clean_input != ""
            if clean_input ∉ items
                push!(items, lowercase(clean_input))
            end
        end
    end
    return ""
end


callback!(app,
    Output("event_checklist", "value"),
    Output("event_checklist", "options"),
    Input("event_checklist", "value"),
    Input("events_input", "value")
) do events, _refresh
    global items
    caller_id = callback_context().triggered[1][1]
    if caller_id == "events_input.value"
        options = [Dict("label"=>i, "value"=>i) for i in items]
        value = items 
    else  # "event_checklist.value
        options = [Dict("label"=>i, "value"=>i) for i in events]
        value = events
        items = [event for event in events]

        # Change checklists to not include deleted event
    end
    return value, options
end

callback!(app,
    Output("first_monday", "options"), Output("last_monday", "options"),
    Output("first_tuesday", "options"), Output("last_tuesday", "options"),
    Output("first_wednesday", "options"), Output("last_wednesday", "options"),
    Output("first_thursday", "options"), Output("last_thursday", "options"),
    Output("first_friday", "options"), Output("last_friday", "options"),
    Output("first_saturday", "options"), Output("last_saturday", "options"),
    Output("first_sunday", "options"), Output("last_sunday", "options"),
    Output("select_logic_event1", "options"), Output("select_logic_event2", "options"),
    Output("select_allowed_event", "options"), Output("select_event", "options"),
    Input("events_input", "value"), Input("event_checklist", "value")
) do _refresh1, _refresh2
    events = [Dict("label"=>i, "value"=>i) for i in items]
    return [events for _ in range(1, 1, 18)]
end

false_list4 = Any[false, false, false, false]
callback!(app,
    Output("select_event", "invalid"),
    Output("select_frequency", "invalid"),
    Output("select_duration", "invalid"),
    Output("select_interval", "invalid"),
    Output("select_event", "value"),
    Output("select_frequency", "value"),
    Output("select_duration", "value"),
    Output("select_interval", "value"),
    Input("frequency_button", "n_clicks"),
    State("select_event", "value"),
    State("select_frequency", "value"),
    State("select_duration", "value"),
    State("select_interval", "value")
) do _refresh, event, frequency, duration, interval
    global event_count
    values = [event, frequency, duration, interval]
    return_value = Any[
        event === nothing, frequency === nothing,
        duration === nothing || duration > 1440, 
        interval === nothing
    ]
    if true ∈ return_value
        if any(x -> x !== true, return_value) # Some arguments
            return [return_value; values]
        else # No arguments
            return [false_list4; values]
        end
    end
    push!(event_count, values)
    return false, false, false, false, nothing, nothing, nothing, nothing
end


callback!(app,
    Output("frequency_rules_checklist", "value"),
    Output("frequency_rules_checklist", "options"),
    Input("frequency_rules_checklist", "value"),
    Input("event_checklist", "value"),
    Input("select_frequency", "invalid"),
) do frequency_rules, _refresh1, _refresh2
    global event_count
    caller_id = callback_context().triggered[1][1]
    if caller_id == "frequency_rules_checklist.value"
        event_count = Set{Tuple{String,Int64,Int64,String}}([
            (res[:event], parse(Int64, res[:frequency]),
                parse(Int64, res[:duration]), res[:interval])
            for res in [match(frequency_checklist_pattern, rule)
                for rule in frequency_rules]
        ])
        value = frequency_rules
        options = [Dict("label"=>i, "value"=>i) for i in value]
    else # select_frequency.invalid or . or event_checklist.value
        value = [
            string(a[1], " ", a[2], "x", a[3], "min ", a[4]) 
            for a in event_count]
        options = [Dict("label"=>i, "value"=>i) for i in value]
    end
    return value, options
end

nothing_list5 = Any[nothing, nothing, nothing, nothing, nothing]
false_list5 = Any[false, false, false, false, false]
callback!(app,
    Output("select_hour1", "invalid"),
    Output("select_minutes1", "invalid"),
    Output("select_hour2", "invalid"),
    Output("select_minutes2", "invalid"),
    Output("select_blocked_interval", "invalid"),
    Output("select_hour1", "value"),
    Output("select_minutes1", "value"),
    Output("select_hour2", "value"),
    Output("select_minutes2", "value"),
    Output("select_blocked_interval", "value"),
    Input("blocked_button", "n_clicks"),
    State("select_hour1", "value"),
    State("select_minutes1", "value"),
    State("select_hour2", "value"),
    State("select_minutes2", "value"),
    State("select_blocked_interval", "value")
) do _refresh, hour1, minutes1, hour2, minutes2, interval
    global blocked_times
    values = [hour1, minutes1, hour2, minutes2, interval]
    return_value = Any[
        hour1 === nothing || hour1 > 23 || hour1 < 0,
        minutes1 === nothing || minutes1 > 59 || minutes1 < 0,
        hour2 === nothing || hour2 > 23 || hour2 < 0,
        minutes2 === nothing || minutes2 > 59 || minutes2 < 0,
        interval === nothing
    ]
    if true ∈ return_value
        if any(x -> x !== true, return_value) # Some arguments
            return [return_value; values]
        else # No arguments
            return [false_list5; values]
        end
    end
    push!(blocked_times, Tuple(values))
    return [false_list5; nothing_list5]
end


callback!(app,
    Output("blocked_rules_checklist", "value"),
    Output("blocked_rules_checklist", "options"),
    Input("blocked_rules_checklist", "value"),
    Input("select_hour1", "invalid"),
    Input("event_checklist", "value")
) do blocked_rules, _refresh1, _refresh2
    global blocked_times
    caller_id = callback_context().triggered[1][1]
    if caller_id == "blocked_rules_checklist.value"
        blocked_times = Set{Tuple{Int64,Int64,Int64,Int64,String}}([
            (parse(Int64, res[:hour1]), parse(Int64, res[:minutes1]),
                parse(Int64, res[:hour2]), parse(Int64, res[:minutes2]),
                res[:interval])
            for res in [match(blocked_checklist_pattern, rule)
                for rule in blocked_rules]
        ])
        value = blocked_rules
        options = [Dict("label"=>i, "value"=>i) for i in value]
    else # select_frequency.invalid or . or event_checklist.value
        value = [
            string(lpad(a[1], 2, "0"), ":", lpad(a[2], 2, "0"), "-", 
                lpad(a[3], 2, "0"), ":", lpad(a[4], 2, "0"), " ", a[5]) 
            for a in blocked_times]
        options = [Dict("label"=>i, "value"=>i) for i in value]
    end
    return value, options
end

callback!(app,
    Output("first_monday", "value"), Output("first_tuesday", "value"),
    Output("first_wednesday", "value"), Output("first_thursday", "value"),
    Output("first_friday", "value"), Output("first_saturday", "value"),
    Output("first_sunday", "value"), Output("last_monday", "value"),
    Output("last_tuesday", "value"), Output("last_wednesday", "value"),
    Output("last_thursday", "value"), Output("last_friday", "value"),
    Output("last_saturday", "value"), Output("last_sunday", "value"),
    Input("first_monday", "value"), Input("first_tuesday", "value"),
    Input("first_wednesday", "value"), Input("first_thursday", "value"),
    Input("first_friday", "value"), Input("first_saturday", "value"),
    Input("first_sunday", "value"), Input("last_monday", "value"),
    Input("last_tuesday", "value"), Input("last_wednesday", "value"),
    Input("last_thursday", "value"), Input("last_friday", "value"),
    Input("last_saturday", "value"), Input("last_sunday", "value"),
    Input("first_monday", "options")
) do first_mon, first_tue, first_wed, first_thu,
first_fri, first_sat, first_sun, last_mon, last_tue,
last_wed, last_thu, last_fri, last_sat, last_sun, _refresh
    global first_events, last_events
    first = Dict(
        "monday" => first_mon, "tuesday" => first_tue,
        "wednesday" => first_wed, "thursday" => first_thu,
        "friday" => first_fri, "saturday" => first_sat,
        "sunday" => first_sun
    )
    last = Dict(
        "monday" => last_mon, "tuesday" => last_tue,
        "wednesday" => last_wed, "thursday" => last_thu,
        "friday" => last_fri, "saturday" => last_sat,
        "sunday" => last_sun
    )
    caller_id = callback_context().triggered[1][1]
    if caller_id != "first_monday.options"
        day = split(caller_id, "_")[2][1:end-6]
        first_events[day] = first[day]
        last_events[day] = last[day]
    end
    println(first_events)
    return first_events["monday"], first_events["tuesday"],
        first_events["wednesday"], first_events["thursday"],
        first_events["friday"], first_events["saturday"],
        first_events["sunday"], last_events["monday"], 
        last_events["tuesday"], last_events["wednesday"],
        last_events["thursday"], last_events["friday"], 
        last_events["saturday"], last_events["sunday"]
end

nothing_list6 = Any[nothing, nothing, nothing, nothing, nothing, nothing]
false_list6 = Any[false, false, false, false, false, false]
callback!(app,
    Output("select_allowed_event", "invalid"),
    Output("allowed_hour1", "invalid"),
    Output("allowed_minutes1", "invalid"),
    Output("allowed_hour2", "invalid"),
    Output("allowed_minutes2", "invalid"),
    Output("select_allowed_interval", "invalid"),
    Output("select_allowed_event", "value"),
    Output("allowed_hour1", "value"),
    Output("allowed_minutes1", "value"),
    Output("allowed_hour2", "value"),
    Output("allowed_minutes2", "value"),
    Output("select_allowed_interval", "value"),
    Input("allowed_button", "n_clicks"),
    State("select_allowed_event", "value"),
    State("allowed_hour1", "value"),
    State("allowed_minutes1", "value"),
    State("allowed_hour2", "value"),
    State("allowed_minutes2", "value"),
    State("select_allowed_interval", "value")
) do _refresh, event, hour1, minutes1, hour2, minutes2, interval
    global event_times
    values = [event, hour1, minutes1, hour2, minutes2, interval]
    return_value = [
        event === nothing,
        hour1 === nothing || hour1 > 23 || hour1 < 0,
        minutes1 === nothing || minutes1 > 59 || minutes1 < 0,
        hour2 === nothing || hour2 > 23 || hour2 < 0,
        minutes2 === nothing || minutes2 > 59 || minutes2 < 0,
        interval === nothing
    ]
    if true ∈ return_value
        if any(x -> x !== true, return_value) # Some arguments
            return [return_value; values]
        else # No arguments
            return [false_list6; values]
        end
    end
    push!(event_times, Tuple(values))
    return [false_list6; nothing_list6]
end


callback!(app,
    Output("allowed_rules_checklist", "value"),
    Output("allowed_rules_checklist", "options"),
    Input("allowed_rules_checklist", "value"),
    Input("allowed_hour1", "invalid"),
    Input("event_checklist", "value")
) do allowed_rules, _refresh, _refresh2
    global event_times
    caller_id = callback_context().triggered[1][1]
    if caller_id == "allowed_rules_checklist.value"
        event_times = Set{Tuple{String,Int64,Int64,Int64,Int64,String}}([
            (res[:event], parse(Int64, res[:hour1]), 
                parse(Int64, res[:minutes1]), parse(Int64, res[:hour2]), 
                parse(Int64, res[:minutes2]), res[:interval])
            for res in [match(allowed_checklist_pattern, rule)
                for rule in allowed_rules]
        ])
        value = allowed_rules
        options = [Dict("label"=>i, "value"=>i) for i in value]
    else # allowed_hour1.invalid or . or event_checklist.value
        value = [
            string(a[1], " ", lpad(a[2], 2, "0"), ":", lpad(a[3], 2, "0"),
                "-", lpad(a[4], 2, "0"), ":", lpad(a[5], 2, "0"), " ", a[6]) 
            for a in event_times]
        options = [Dict("label"=>i, "value"=>i) for i in value]
    end
    return value, options
end




nothing_list3 = Any[nothing, nothing, nothing]
false_list3 = Any[false, false, false]
callback!(app,
    Output("select_logic_event1", "invalid"),
    Output("select_logic_interval", "invalid"),
    Output("select_logic_event2", "invalid"),
    Output("select_logic_event1", "value"),
    Output("select_logic_interval", "value"),
    Output("select_logic_event2", "value"),
    Input("logic_button", "n_clicks"),
    State("select_logic_event1", "value"),
    State("select_logic_interval", "value"),
    State("select_logic_event2", "value")
) do _refresh, event1, logic_rule, event2
    global logic
    values = [event1, logic_rule, event2]
    return_value = [
        event1 === nothing,
        logic_rule === nothing,
        event2 === nothing
    ]
    if true ∈ return_value
        if any(x -> x !== true, return_value) # Some arguments
            return [return_value; values]
        else # No arguments
            return [false_list3; values]
        end
    end
    push!(logic, Tuple(values))
    return [false_list3; nothing_list3]
end


callback!(app,
    Output("logic_rules_checklist", "value"),
    Output("logic_rules_checklist", "options"),
    Input("logic_rules_checklist", "value"),
    Input("select_logic_event1", "invalid"),
    Input("event_checklist", "value")
) do logic_rules, _refresh, _refresh2
    global logic
    caller_id = callback_context().triggered[1][1]
    if caller_id == "logic_rules_checklist.value"
        logic = Set{Tuple{String,String,String}}([
            (res[:event1], res[:logic], res[:event2])
            for res in [match(logic_checklist_pattern, rule)
                for rule in logic_rules]
        ])
        value = logic_rules
        options = [Dict("label"=>i, "value"=>i) for i in value]
    else # allowed_hour1.invalid or . or event_checklist.value
        value = [
            string(a[1], " ", a[2], " ", a[3]) 
            for a in logic]
        options = [Dict("label"=>i, "value"=>i) for i in value]
    end
    return value, options
end






run_server(app, "0.0.0.0", 8050, 
debug = false, dev_tools_hot_reload=true)