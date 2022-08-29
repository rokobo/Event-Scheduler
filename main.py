"""
Automatic task scheduler using Dash.

The scheduler algorithm is implemented using a recursive backtracking 
approach to events with certain possible conditions like:
    Define first event of the day.
    Define last event of the day.
    Define how many times an event should occur (day/week).
    Define unavailable time ranges.
    Define possible times for certain events.
    Define breaks between events (regular breaks and
        longer breaks every n breaks).
    Upload and download the schedule (JSON and SQL).
    Download the schedule in readable format.
    Show all user-defined conditions.
    Multiple visual interfaces of the events.
"""


import re
from dash import Dash, html, dcc, Input, Output, callback
from dash import State, callback_context
import dash_bootstrap_components as dbc
import plotly.express as px
import pandas as pd
from scheduler import Scheduler
import verifier

scheduler = Scheduler()
frequency_checklist_pattern = re.compile(
    '(?P<event>.+) ' +
    '(?P<frequency>[0-9]+)x' +
    '(?P<duration>[0-9]+)min ' +
    '(?P<interval>per [a-z]+)'
)
blocked_checklist_pattern = re.compile(
    '(?P<hour1>[0-9]+):(?P<minutes1>[0-9]+)-' +
    '(?P<hour2>[0-9]+):(?P<minutes2>[0-9]+) ' +
    '(?P<interval>every .+)'
)
allowed_checklist_pattern = re.compile(
    '(?P<event>.+) ' +
    '(?P<hour1>[0-9]+):(?P<minutes1>[0-9]+)-' +
    '(?P<hour2>[0-9]+):(?P<minutes2>[0-9]+) ' +
    '(?P<interval>every .+)'
)
logic_checklist_pattern = re.compile(
    '(?P<event1>.+) (?P<logic>before|after) (?P<event2>.+)'
)
app = Dash(
    __name__,
    title="Automatic Scheduler",
    external_stylesheets=[dbc.themes.BOOTSTRAP]
)
server = app.server

app.layout = html.Div([
    dbc.Row([
        html.H1(
            "Automatic event scheduler",
            style={'textAlign': 'center', 'margin-bottom': '5px'}
        ),
        html.H6(
            "by Pedro Kobori",
            style={'textAlign': 'center', 'margin-bottom': '40px'}
        )
    ]),
    dbc.Row([
        dbc.Col([
            dbc.Accordion([
                dbc.AccordionItem([
                    dbc.Row([
                        dbc.Col([
                            html.Div([
                                html.H6(
                                    "Add and remove events",
                                    style={'textAlign': 'center'}
                                ),
                                dbc.Input(
                                    id="events_input",
                                    placeholder="Press enter to add event",
                                    type='text',
                                    debounce=True,
                                    size='md',
                                    maxLength='32'
                                ),
                                dcc.Checklist(
                                    id="event_checklist",
                                    labelStyle=dict(display='block'),
                                    persistence=True,
                                    persistence_type='local'
                                )
                            ])
                        ]),
                        dbc.Col([
                            dbc.Row(
                                html.Div([
                                    html.H6(
                                        "Define event frequency",
                                        style={'textAlign': 'center'}
                                    )
                                ])
                            ),
                            dbc.Row([
                                dbc.Row([
                                    dbc.Select(
                                        id="select_event",
                                        placeholder="Event or break"
                                    ),
                                ], className="g-0"),
                                dbc.Row([
                                    dbc.Col(
                                        dbc.Input(
                                            id="select_frequency",
                                            placeholder="Frequency",
                                            size="md",
                                            type='number'
                                        )
                                    ),
                                    dbc.Col(
                                        dbc.Input(
                                            id="select_duration",
                                            placeholder="Duration (min)",
                                            size="md",
                                            type='number'
                                        )
                                    )
                                ], className="g-0"),
                                dbc.Row([
                                    dbc.Select(id="select_interval", options=[
                                        {'label': 'per day', 'value': 'per day'},
                                        {'label': 'per week', 'value': 'per week'},
                                        {'label': 'per month', 'value': 'per month'},
                                        {'label': 'per monday',
                                            'value': 'per monday'},
                                        {'label': 'per tuesday',
                                         'value': 'per tuesday'},
                                        {'label': 'per wednesday',
                                         'value': 'per wednesday'},
                                        {'label': 'per thursday',
                                         'value': 'per thursday'},
                                        {'label': 'per friday',
                                            'value': 'per friday'},
                                        {'label': 'per saturday',
                                         'value': 'per saturday'},
                                        {'label': 'per sunday',
                                            'value': 'per sunday'}
                                    ], placeholder="Interval")
                                ], className="g-0"),
                                dbc.Row([
                                    dbc.Button(
                                        "Add frequency rule", id="frequency_button",
                                        color="secondary", outline=False
                                    )
                                ], className="g-0"),
                                dbc.Row([
                                    dcc.Checklist(
                                        id="frequency_rules_checklist",
                                        labelStyle=dict(display='block'),
                                        persistence=True,
                                        persistence_type='local'
                                    )
                                ], className="g-0")
                            ], className="g-0")
                        ]),
                        dbc.Col([
                            dbc.Row(
                                html.Div([
                                    html.H6(
                                        "Define blocked periods",
                                        style={'textAlign': 'center'})
                                ])
                            ),
                            dbc.Row([
                                dbc.Row([
                                    dbc.Col(
                                        dbc.Input(
                                            id="select_hour1",
                                            placeholder="Hour 1",
                                            size="sm",
                                            type='number',
                                        )
                                    ),
                                    dbc.Col(
                                        dbc.Input(
                                            id="select_minutes1",
                                            placeholder="Minutes 1",
                                            size="sm",
                                            type='number',
                                        )
                                    )
                                ], className="g-0"),
                                dbc.Row([
                                    dbc.Col(
                                        dbc.Input(
                                            id="select_hour2",
                                            placeholder="Hour 2",
                                            size="sm",
                                            type='number',
                                        )
                                    ),
                                    dbc.Col(
                                        dbc.Input(
                                            id="select_minutes2",
                                            placeholder="Minutes 2",
                                            size="sm",
                                            type='number',
                                        )
                                    )
                                ], className="g-0"),
                                dbc.Row([
                                    dbc.Select(id="select_blocked_interval", options=[
                                        {'label': 'every day',
                                            'value': 'every day'},
                                        {'label': 'every monday',
                                         'value': 'every monday'},
                                        {'label': 'every tuesday',
                                         'value': 'every tuesday'},
                                        {'label': 'every wednesday',
                                         'value': 'every wednesday'},
                                        {'label': 'every thursday',
                                         'value': 'every thursday'},
                                        {'label': 'every friday',
                                         'value': 'every friday'},
                                        {'label': 'every saturday',
                                         'value': 'every saturday'},
                                        {'label': 'every sunday',
                                         'value': 'every sunday'}
                                    ], placeholder="Interval")
                                ], className="g-0"),
                                dbc.Row([
                                    dbc.Button(
                                        "Add blocked rule", id="blocked_button",
                                        color="secondary", outline=False
                                    )
                                ], className="g-0"),
                                dbc.Row([
                                    dcc.Checklist(
                                        id="blocked_rules_checklist",
                                        labelStyle=dict(display='block'),
                                        persistence=True,
                                        persistence_type='local'
                                    )
                                ], className="g-0")
                            ], className="g-0")
                        ])
                    ])
                ],
                    item_id="item1",
                    title="Add events, Define frequency and Free time ↓"),
                dbc.AccordionItem([
                    dbc.Row([
                        dbc.Col(html.H6("Monday", style={
                            'textAlign': 'center'}), width=2),
                        dbc.Col(
                            dcc.Dropdown(
                                id="first_monday",
                                placeholder="First event",
                                multi=True
                            )
                        ),
                        dbc.Col(
                            dcc.Dropdown(
                                id="last_monday",
                                placeholder="Last event",
                                multi=True
                            )
                        )
                    ], className='g-0'),
                    dbc.Row([
                        dbc.Col(html.H6("Tuesday", style={
                            'textAlign': 'center'}), width=2),
                        dbc.Col(
                            dcc.Dropdown(
                                id="first_tuesday",
                                placeholder="First event",
                                multi=True
                            )
                        ),
                        dbc.Col(
                            dcc.Dropdown(
                                id="last_tuesday",
                                placeholder="Last event",
                                multi=True
                            )
                        )
                    ], className='g-0'),
                    dbc.Row([
                        dbc.Col(html.H6("Wednesday", style={
                            'textAlign': 'center'}), width=2),
                        dbc.Col(
                            dcc.Dropdown(
                                id="first_wednesday",
                                placeholder="First event",
                                multi=True
                            )
                        ),
                        dbc.Col(
                            dcc.Dropdown(
                                id="last_wednesday",
                                placeholder="Last event",
                                multi=True
                            )
                        )
                    ], className='g-0'),
                    dbc.Row([
                        dbc.Col(html.H6("Thursday", style={
                            'textAlign': 'center'}), width=2),
                        dbc.Col(
                            dcc.Dropdown(
                                id="first_thursday",
                                placeholder="First event",
                                multi=True
                            )
                        ),
                        dbc.Col(
                            dcc.Dropdown(
                                id="last_thursday",
                                placeholder="Last event",
                                multi=True
                            )
                        )
                    ], className='g-0'),
                    dbc.Row([
                        dbc.Col(html.H6("Friday", style={
                            'textAlign': 'center'}), width=2),
                        dbc.Col(
                            dcc.Dropdown(
                                id="first_friday",
                                placeholder="First event",
                                multi=True
                            )
                        ),
                        dbc.Col(
                            dcc.Dropdown(
                                id="last_friday",
                                placeholder="Last event",
                                multi=True
                            )
                        )
                    ], className='g-0'),
                    dbc.Row([
                        dbc.Col(html.H6("Saturday", style={
                            'textAlign': 'center'}), width=2),
                        dbc.Col(
                            dcc.Dropdown(
                                id="first_saturday",
                                placeholder="First event",
                                multi=True
                            )
                        ),
                        dbc.Col(
                            dcc.Dropdown(
                                id="last_saturday",
                                placeholder="Last event",
                                multi=True
                            )
                        )
                    ], className='g-0'),
                    dbc.Row([
                        dbc.Col(html.H6("Sunday", style={
                            'textAlign': 'center'}), width=2),
                        dbc.Col(
                            dcc.Dropdown(
                                id="first_sunday",
                                placeholder="First event",
                                multi=True
                            )
                        ),
                        dbc.Col(
                            dcc.Dropdown(
                                id="last_sunday",
                                placeholder="Last event",
                                multi=True
                            )
                        )
                    ], className='g-0')
                ],
                    item_id="item2",
                    title="First and Last events of the day ↓"),
                dbc.AccordionItem([
                    dbc.Row([
                        dbc.Col([
                            html.Div([
                                html.H6(
                                    "Define allowed periods of time for " +
                                    "events and breaks",
                                    style={'textAlign': 'center'})
                            ]),
                            dbc.Row([
                                dbc.Select(
                                    id="select_allowed_event",
                                    placeholder="Event or break"
                                ),
                            ], className="g-0"),
                            dbc.Row([
                                dbc.Col(
                                    dbc.Input(
                                        id="allowed_hour1",
                                        placeholder="Hour 1",
                                        size="sm",
                                        type='number',
                                    )
                                ),
                                dbc.Col(
                                    dbc.Input(
                                        id="allowed_minutes1",
                                        placeholder="Minutes 1",
                                        size="sm",
                                        type='number',
                                    )
                                )
                            ], className="g-0"),
                            dbc.Row([
                                dbc.Col(
                                    dbc.Input(
                                        id="allowed_hour2",
                                        placeholder="Hour 2",
                                        size="sm",
                                        type='number',
                                    )
                                ),
                                dbc.Col(
                                    dbc.Input(
                                        id="allowed_minutes2",
                                        placeholder="Minutes 2",
                                        size="sm",
                                        type='number',
                                    )
                                )
                            ], className="g-0"),
                            dbc.Row([
                                dbc.Select(id="select_allowed_interval", options=[
                                    {'label': 'every day',
                                        'value': 'every day'},
                                    {'label': 'every monday',
                                        'value': 'every monday'},
                                    {'label': 'every tuesday',
                                        'value': 'every tuesday'},
                                    {'label': 'every wednesday',
                                        'value': 'every wednesday'},
                                    {'label': 'every thursday',
                                        'value': 'every thursday'},
                                    {'label': 'every friday',
                                        'value': 'every friday'},
                                    {'label': 'every saturday',
                                        'value': 'every saturday'},
                                    {'label': 'every sunday',
                                        'value': 'every sunday'}
                                ], placeholder="Interval")
                            ], className="g-0"),
                            dbc.Row([
                                dbc.Button(
                                    "Add allowed rule", id="allowed_button",
                                    color="secondary", outline=False
                                )
                            ], className="g-0"),
                            dbc.Row([
                                dcc.Checklist(
                                    id="allowed_rules_checklist",
                                    labelStyle=dict(display='block'),
                                    persistence=True,
                                    persistence_type='local'
                                )
                            ], className="g-0")
                        ]),
                        dbc.Col([
                            html.H6(
                                "Define sequential logic of events and breaks",
                                style={'textAlign': 'center'}
                            ),
                            dbc.Row([
                                dbc.Select(
                                    id="select_logic_event1",
                                    placeholder="Event or break"
                                ),
                            ], className="g-0"),
                            dbc.Row([
                                dbc.Select(id="select_logic_interval", options=[
                                    {'label': 'before',
                                        'value': 'before'},
                                    {'label': 'after',
                                        'value': 'after'}
                                ], placeholder="Before or after")
                            ], className="g-0"),
                            dbc.Row([
                                dbc.Select(
                                    id="select_logic_event2",
                                    placeholder="Event"
                                ),
                            ], className="g-0"),
                            dbc.Row([
                                dbc.Button(
                                    "Add logic rule", id="logic_button",
                                    color="secondary", outline=False
                                )
                            ], className="g-0"),
                            dbc.Row([
                                dcc.Checklist(
                                    id="logic_rules_checklist",
                                    labelStyle=dict(display='block'),
                                    persistence=True,
                                    persistence_type='local'
                                )
                            ], className="g-0")
                        ])
                    ])
                ],
                    item_id="item3",
                    title="Breaks and Allowed event times ↓")
            ], always_open=True, active_item=["item1", "item2", "item3"]) 
        ], width=6),
        dbc.Col([
            dbc.Row([
                dbc.Col([
                    dcc.Upload(
                        dbc.Button(
                            'Upload config.ini', color="info", outline=False
                        ), id='upload_config'
                    )
                ]),
                dbc.Col([
                    dbc.Button(
                        "Download config.ini", color="info", outline=False),
                    dcc.Download(id="download_config")
                ]),
                dbc.Col([
                    dbc.Button(
                        "Download schedule", color="info", outline=False),
                    dcc.Download(id="download_schedule")
                ])
            ]),
            dbc.Row([
                dbc.Col([
                    dbc.Select(id="select_fit_interval", options=[
                        {'label': 'Fit every 1 minute', 'value': 1},
                        {'label': 'Fit every 2 minutes', 'value': 2},
                        {'label': 'Fit every 3 minutes', 'value': 3},
                        {'label': 'Fit every 5 minutes', 'value': 5},
                        {'label': 'Fit every 10 minutes', 'value': 10},
                        {'label': 'Fit every 15 minutes', 'value': 15},
                    ], placeholder="Event fit interval"),
                    dbc.Tooltip(
                        "Select how often a pending event should \
                            try a fit after another set event. Note that\
                                more frequent fits take more time to process",
                        target="select_fit_interval"
                    )
                ]),
                dbc.Col([
                    dbc.Button(
                        "Make schedule", id="make_schedule_button",
                        color="success", outline=False
                    ),
                    dbc.Tooltip(
                        "The monthly schedule will be divided into 4 weeks\
                            that can be accessed using the buttons below",
                        target="make_schedule_button"
                    )
                ], width=4)
            ], style={"margin-top": "20px"}),
            dbc.Row([
                dbc.Col([dbc.Button(
                    "Week 1", id="select_week_1",
                    color="primary", outline=False
                )]),
                dbc.Col([dbc.Button(
                    "Week 2", id="select_week_2",
                    color="primary", outline=False
                )]),
                dbc.Col([dbc.Button(
                    "Week 3", id="select_week_3",
                    color="primary", outline=False
                )]),
                dbc.Col([dbc.Button(
                    "Week 4", id="select_week_4",
                    color="primary", outline=False
                )]),
            ], style={"margin-top": "20px"}),
            dbc.Row([
                dcc.Graph(
                    id="schedule",
                    style={"margin-top": "15px"},
                    config={'staticPlot': True})
            ])
        ], width=6)
    ])
], style={'padding': 15})


@callback(Output('events_input', 'value'),
          Input('events_input', 'value'))
def update_event_list(input: str) -> str:
    """
    Updates the event list.

    Args:
        input (str): new event the user typed.

    Returns:
        str: empty string to clear input field.
    """
    if input is not None:
        if input.strip():
            scheduler.items.add(input.lower())
    return ''


@callback(Output('event_checklist', 'value'),
          Output('event_checklist', 'options'),
          Input('event_checklist', 'value'),
          Input('events_input', 'value'))
def show_event_checklist(value_input: list, _: list) -> list:
    """
    Updates event checklist's options and values.

    Args:
        value_input (list): currently checked values.
        _ (list): dummy variable (used for refresh).

    Returns:
        list: options and values list of the checklist.
    """
    caller_id = callback_context.triggered[0]["prop_id"]
    if caller_id == "events_input.value":
        options = list(scheduler.items)
        value = options
    else:  # "event_checklist.value"
        options = value_input
        value = options
        scheduler.items = set(value_input)

        # Change checklists to not include deleted events
        discard_pile = []
        for rule in scheduler.event_count:
            if rule[0] not in value_input:
                discard_pile.append(rule)
        for rule in discard_pile:
            scheduler.event_count.discard(rule)

        discard_pile = []
        for rule in scheduler.event_times:
            if rule[0] not in value_input:
                discard_pile.append(rule)
        for rule in discard_pile:
            scheduler.event_times.discard(rule)

        discard_pile = []
        for rule in scheduler.logic:
            check1 = rule[0] not in value_input + ["break"]
            check2 = rule[2] not in value_input
            if check1 or check2:
                discard_pile.append(rule)
        for rule in discard_pile:
            scheduler.logic.discard(rule)
    return value, options


@callback(
    Output('first_monday', 'options'), Output('last_monday', 'options'),
    Output('first_tuesday', 'options'), Output('last_tuesday', 'options'),
    Output('first_wednesday', 'options'), Output('last_wednesday', 'options'),
    Output('first_thursday', 'options'), Output('last_thursday', 'options'),
    Output('first_friday', 'options'), Output('last_friday', 'options'),
    Output('first_saturday', 'options'), Output('last_saturday', 'options'),
    Output('first_sunday', 'options'), Output('last_sunday', 'options'),
    Output('select_logic_event2', 'options'),
    Input('events_input', 'value'), Input('event_checklist', 'value'))
def update_all_event_select_box(_input1: str, _input2: str) -> list:
    """
    Displays events in select box for multiple components.

    Args:
        _input1 (str): Used for refreshing events in select box.
        _input2 (str): Used for refreshing events in select box.

    Returns:
        list: All events in dictionary format.
    """
    items = [{"label": item, "value": item} for item in scheduler.items]
    return_value = [items for _ in range(15)]
    return return_value


@callback(Output('select_logic_event1', 'options'),
          Output('select_allowed_event', 'options'),
          Output('select_event', 'options'),
          Input('events_input', 'value'), Input('event_checklist', 'value'))
def update_break_select_box(_input1: str, _input2: str) -> list:
    """Special case of update_all_event_select_box."""
    items = [
        {"label": item, "value": item} for item in scheduler.items
    ] + [{"label": "break", "value": "break"}]
    return_value = [items for _ in range(3)]
    return return_value


@callback(Output('select_event', 'invalid'),
          Output('select_frequency', 'invalid'),
          Output('select_duration', 'invalid'),
          Output('select_interval', 'invalid'),
          Output('select_event', 'value'),
          Output('select_frequency', 'value'),
          Output('select_duration', 'value'),
          Output('select_interval', 'value'),
          Input('frequency_button', 'n_clicks'),
          State('select_event', 'value'),
          State('select_frequency', 'value'),
          State('select_duration', 'value'),
          State('select_interval', 'value'))
def add_frequency_rule(
        clicks: int, event: str, frequency: int, duration: int, interval: str):
    """
    Adds event frequency rule to memory.

    Args:
        clicks (int): number of clicks of the add frequency button.
        event (str): event from define event frequency rule.
        frequency (int): frequency from define event frequency rule.
        duration (int): duration from define event frequency rule.
        interval (str): interval from define event frequency rule.

    Returns:
        Boolean: if the provided input is invalid or not.
    """
    value = (event, frequency, duration, interval)

    if None in value:  # Check for invalid argument
        if not all(v is None for v in value):  # Check for empty input
            return event is None, frequency is None, duration is None,\
                interval is None, event, frequency, duration, interval
        else:
            return False, False, False, False, None, None, None, None

    # Check for invalid rules

    # checked, reason = check_rule(value)
    # if checked:
    scheduler.event_count.add(value)
    return False, False, False, False, None, None, None, None


@callback(Output('frequency_rules_checklist', 'value'),
          Output('frequency_rules_checklist', 'options'),
          Input('frequency_rules_checklist', 'value'),
          Input('frequency_button', 'n_clicks'),
          Input('event_checklist', 'value'))
def show_frequency_rule_checklist(
        value_input: list, _1: int, events: list) -> list:
    """
    Updates frequency rules checklist's options and values.

    Args:
        value_input (list): currently checked values.
        _1 (list): dummy variable (used for refresh).
        events (list): event list (used for checking event deletions).

    Returns:
        list: options and values list of the checklist.
    """
    caller_id = callback_context.triggered[0]["prop_id"]

    # if caller_id == "event_checklist.value": # Check for deleted events
    #     for rule in scheduler.event_count:
    #         if rule[0] not in events:
    #             scheduler.event_count.discard(rule)

    if caller_id == "frequency_rules_checklist.value":
        options = value_input
        value = options
        scheduler.event_count = set(
            re.match(frequency_checklist_pattern, text).groups()
            for text in value_input
        )
    else:  # frequency_button.n_clicks or . or event_checklist.value:
        options = [
            f"{a[0]} {a[1]}x{a[2]}min {a[3]}" for a in scheduler.event_count
        ]
        value = options
    return value, options


@callback(Output('select_hour1', 'invalid'),
          Output('select_minutes1', 'invalid'),
          Output('select_hour2', 'invalid'),
          Output('select_minutes2', 'invalid'),
          Output('select_blocked_interval', 'invalid'),
          Output('select_hour1', 'value'),
          Output('select_minutes1', 'value'),
          Output('select_hour2', 'value'),
          Output('select_minutes2', 'value'),
          Output('select_blocked_interval', 'value'),
          Input('blocked_button', 'n_clicks'),
          State('select_hour1', 'value'),
          State('select_minutes1', 'value'),
          State('select_hour2', 'value'),
          State('select_minutes2', 'value'),
          State('select_blocked_interval', 'value'))
def add_blocked_rule(
        clicks: int, hour1: str, minutes1: int, hour2: int,
        minutes2: str, interval: str):
    """
    Adds blocked period rule to memory.

    Args:
        clicks (int): number of clicks of the add frequency button.
        event (str): event from define event frequency rule.
        frequency (int): frequency from define event frequency rule.
        duration (int): duration from define event frequency rule.
        interval (str): interval from define event frequency rule.

    Returns:
        Boolean: if the provided input is invalid or not.
    """
    value = (hour1, minutes1, hour2, minutes2, interval)
    none = (None, None, None, None, None)
    false = (False, False, False, False, False)
    return_value = (
        hour1 is None or hour1 > 23 or hour1 < 0,
        minutes1 is None or minutes1 > 59 or minutes1 < 0,
        hour2 is None or hour2 > 23 or hour2 < 0,
        minutes2 is None or minutes2 > 59 or minutes2 < 0,
        interval is None
    )

    if True in return_value:  # checks for invalid arguments
        if not all(v for v in return_value):  # checks for empty input
            return return_value + value
        else:
            return false + value

    scheduler.blocked_times.add(value)
    return false + none


@callback(Output('blocked_rules_checklist', 'value'),
          Output('blocked_rules_checklist', 'options'),
          Input('blocked_rules_checklist', 'value'),
          Input('blocked_button', 'n_clicks'))
def show_blocked_rule_checklist(
        value_input: list, _: int) -> list:
    """
    Updates frequency rules checklist's options and values.

    Args:
        value_input (list): currently checked values.
        _ (list): dummy variable (used for refresh).

    Returns:
        list: options and values list of the checklist.
    """
    caller_id = callback_context.triggered[0]["prop_id"]
    if caller_id == "blocked_rules_checklist.value":
        options = value_input
        value = options
        scheduler.blocked_times = set(
            re.match(blocked_checklist_pattern, text).groups()
            for text in value_input
        )
    else:  # blocked_button.n_clicks or .:
        options = [
            "{}:{}-{}:{} {}".format(
                str(a[0]).zfill(2),
                str(a[1]).zfill(2),
                str(a[2]).zfill(2),
                str(a[3]).zfill(2),
                a[4]
            ) for a in scheduler.blocked_times
        ]
        value = options
    return value, options


@callback(
    Output('first_monday', 'value'), Output('first_tuesday', 'value'),
    Output('first_wednesday', 'value'), Output('first_thursday', 'value'),
    Output('first_friday', 'value'), Output('first_saturday', 'value'),
    Output('first_sunday', 'value'), Output('last_monday', 'value'),
    Output('last_tuesday', 'value'), Output('last_wednesday', 'value'),
    Output('last_thursday', 'value'), Output('last_friday', 'value'),
    Output('last_saturday', 'value'), Output('last_sunday', 'value'),

    Input('first_monday', 'value'), Input('first_tuesday', 'value'),
    Input('first_wednesday', 'value'), Input('first_thursday', 'value'),
    Input('first_friday', 'value'), Input('first_saturday', 'value'),
    Input('first_sunday', 'value'), Input('last_monday', 'value'),
    Input('last_tuesday', 'value'), Input('last_wednesday', 'value'),
    Input('last_thursday', 'value'), Input('last_friday', 'value'),
    Input('last_saturday', 'value'), Input('last_sunday', 'value'),
    Input('first_monday', 'options')
)
def add_first_last_events(
    first_monday, first_tuesday, first_wednesday, first_thursday,
    first_friday, first_saturday, first_sunday, last_monday, last_tuesday,
    last_wednesday, last_thursday, last_friday, last_saturday, last_sunday, _
):
    """
    Updates the first and last event selection boxes and their internal values.

    Args:
        first_monday (list): First event of monday.
        first_tuesday (list): First event of monday.
        first_wednesday (list): First event of monday.
        first_thursday (list): First event of monday.
        first_friday (list): First event of monday.
        first_saturday (list): First event of monday.
        first_sunday (list): First event of monday.
        last_monday (list): Last event of monday.
        last_tuesday (list):  Last event of monday.
        last_wednesday (list):  Last event of monday.
        last_thursday (list):  Last event of monday.
        last_friday (list):  Last event of monday.
        last_saturday (list):  Last event of monday.
        last_sunday (list):  Last event of monday.
        _ (dict): Used for knowing if the contents should be updated
            from the internal database.

    Returns:
        list: list of values from the first and last selection boxes.
    """
    first = {
        'monday': first_monday, 'tuesday': first_tuesday,
        'wednesday': first_wednesday, 'thursday': first_thursday,
        'friday': first_friday, 'saturday': first_saturday,
        'sunday': first_sunday
    }
    last = {
        'monday': last_monday, 'tuesday': last_tuesday,
        'wednesday': last_wednesday, 'thursday': last_thursday,
        'friday': last_friday, 'saturday': last_saturday,
        'sunday': last_sunday
    }

    caller_id = callback_context.triggered[0]["prop_id"]
    if caller_id != "first_monday.options":
        day = caller_id.split("_")[1].split(".")[0]
        scheduler.first_events[day] = first[day]
        scheduler.last_events[day] = last[day]
        return list(first.values()) + list(last.values())
    else:
        first = scheduler.first_events
        last = scheduler.last_events
        return list(first.values()) + list(last.values())


@callback(
    Output('select_allowed_event', 'invalid'),
    Output('allowed_hour1', 'invalid'),
    Output('allowed_minutes1', 'invalid'),
    Output('allowed_hour2', 'invalid'),
    Output('allowed_minutes2', 'invalid'),
    Output('select_allowed_interval', 'invalid'),
    Output('select_allowed_event', 'value'),
    Output('allowed_hour1', 'value'),
    Output('allowed_minutes1', 'value'),
    Output('allowed_hour2', 'value'),
    Output('allowed_minutes2', 'value'),
    Output('select_allowed_interval', 'value'),
    Input('allowed_button', 'n_clicks'),
    State('select_allowed_event', 'value'),
    State('allowed_hour1', 'value'),
    State('allowed_minutes1', 'value'),
    State('allowed_hour2', 'value'),
    State('allowed_minutes2', 'value'),
    State('select_allowed_interval', 'value'))
def add_allowed_rule(
        clicks: int, event: str, hour1: str, minutes1: int, hour2: int,
        minutes2: str, interval: str):
    """
    Adds blocked period rule to memory.

    Args:
        clicks (int): number of clicks of the add frequency button.
        event (str): event from define event frequency rule.
        frequency (int): frequency from define event frequency rule.
        duration (int): duration from define event frequency rule.
        interval (str): interval from define event frequency rule.

    Returns:
        Boolean: if the provided input is invalid or not.
    """
    arguments, return_value, not_valid = verifier.time_range(
        event, hour1, minutes1, hour2, minutes2, interval
    )

    if not not_valid:
        scheduler.event_times.add(arguments)
    return return_value

@callback(Output('allowed_rules_checklist', 'value'),
          Output('allowed_rules_checklist', 'options'),
          Input('allowed_rules_checklist', 'value'),
          Input('allowed_button', 'n_clicks'),
          Input('event_checklist', 'value'))
def show_allowed_rule_checklist(
        value_input: list, _1: int, events: list) -> list:
    """
    Updates frequency rules checklist's options and values.

    Args:
        value_input (list): currently checked values.
        _1 (list): dummy variable (used for refresh).
        events (list): event list (used for checking event deletions).

    Returns:
        list: options and values list of the checklist.
    """
    caller_id = callback_context.triggered[0]["prop_id"]

    if caller_id == "allowed_rules_checklist.value":
        options = value_input
        value = options
        scheduler.event_times = set(
            re.match(allowed_checklist_pattern, text).groups()
            for text in value_input
        )
    else:  # allowed_button.n_clicks or . or event_checklist.value:
        options = [
            "{} {}:{}-{}:{} {}".format(
                a[0],
                str(a[1]).zfill(2),
                str(a[2]).zfill(2),
                str(a[3]).zfill(2),
                str(a[4]).zfill(2),
                a[5]
            ) for a in scheduler.event_times
        ]
        value = options
    return value, options


@callback(
    Output('select_logic_event1', 'invalid'),
    Output('select_logic_interval', 'invalid'),
    Output('select_logic_event2', 'invalid'),
    Output('select_logic_event1', 'value'),
    Output('select_logic_interval', 'value'),
    Output('select_logic_event2', 'value'),
    Input('logic_button', 'n_clicks'),
    State('select_logic_event1', 'value'),
    State('select_logic_interval', 'value'),
    State('select_logic_event2', 'value'))
def add_logic_rule(clicks: int, event1: str, logic: str, event2: str) -> None:
    """
    Adds logic rule to memory.

    Args:
        clicks (int): number of clicks of the add frequency button.
        event (str): event from define event frequency rule.
        frequency (int): frequency from define event frequency rule.
        duration (int): duration from define event frequency rule.
        interval (str): interval from define event frequency rule.
    """
    arguments = [event1, logic, event2]
    value = [event1 is None, logic is None, event2 is None]

    if True in value:  # checks for invalid arguments
        if not all(v for v in value):  # checks for empty input
            return_value = value + arguments
        else:
            return_value = [False, False, False] + arguments
    else:
        return_value = [False, False, False, None, None, None]

    if True in value:
        pass
    else:
        scheduler.logic.add(tuple(arguments))
    return return_value

@callback(Output('logic_rules_checklist', 'value'),
          Output('logic_rules_checklist', 'options'),
          Input('logic_rules_checklist', 'value'),
          Input('logic_button', 'n_clicks'),
          Input('event_checklist', 'value'))
def show_logic_rule_checklist(
        value_input: list, _1: int, events: list) -> list:
    """
    Updates frequency rules checklist's options and values.

    Args:
        value_input (list): currently checked values.
        _1 (list): dummy variable (used for refresh).
        events (list): event list (used for checking event deletions).

    Returns:
        list: options and values list of the checklist.
    """
    caller_id = callback_context.triggered[0]["prop_id"]

    if caller_id == "logic_rules_checklist.value":
        options = value_input
        value = options
        scheduler.logic = set(
            re.match(logic_checklist_pattern, text).groups()
            for text in value_input
        )
    else:  # logic_button.n_clicks or . or event_checklist.value:
        options = [
            f"{a[0]} {a[1]} {a[2]}" for a in scheduler.logic
        ]
        value = options
    return value, options

@callback(Output('schedule', 'figure'),
          Input('make_schedule_button', 'n_clicks'),
          Input('select_fit_interval', 'value'))
def display_schedule(_dummy, fit_interval):
    scheduler.fit_length = fit_interval
    days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    data = [
        ["blocked time", 0, 24],
        ["free time", 1, 24],
        ["frsss<br>ssssssee", 2, 16],
        ["casdasdasda<br>sdasdashem", 2, 7.75],
        ["cadasdsadsadasdhem3", 2, 0.25]
    ]

    data.extend([["frasd" + str(x), x, 24] for x in range(3, 7)])
    data = [["frasadsadad" + str(x), i, 24] for x, i in enumerate(days)]

    df = pd.DataFrame(data, columns=[
        "event", 'day', 'duration'
    ])

    fig = px.bar(
        df, hover_data=[
            'event'
        ], color='event',
        x='day', y='duration',
        text="event"
    )
    fig.update_traces(textposition="inside")
    fig.update_xaxes(
        visible=False, showticklabels=False,
        titlefont=dict(color='rgba(0,0,0,0)'))
    fig.update_yaxes(
        autorange="reversed", range=[0, 24], dtick=2,
        titlefont=dict(color='rgba(0,0,0,0)'))
    fig.update_layout(
        margin=dict(l=0, r=0, t=0, b=0),
        plot_bgcolor='rgb(30, 30, 30)',
        paper_bgcolor='rgb(30, 30, 30)',
        font_color='rgb(203, 203, 203)',
        height=900, legend_title_text="",
        legend=dict(
            bgcolor="rgba(68, 68, 68, 0.5)",
            itemclick=False,
            itemdoubleclick=False
        )
    )

    for i in range(len(days)):
        fig.add_annotation(dict(
            font=dict(color='rgb(203, 203, 203)', size=12),
            x=i, y=24.3, showarrow=False,
            text=str(days[i]), textangle=0,
            xref="x", yref="y"
        ))
    return fig


if __name__ == '__main__':
    app.run_server(host="0.0.0.0", port="8050", debug=True, use_reloader=True)
