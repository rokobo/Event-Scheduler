# Event scheduler

This was a project aimed at developing a recursive backtracking algorithm. While the traditional route would be Sudoku or some kind of grid search, I wanted to do something unique and useful. This is the product of that wish.

## Uses

The project uses a Dash web application to show and interact with the program. It looks like this:

<p align="center">
  <img src="https://github.com/rokobo/Event-Scheduler/blob/main/Demo.png?raw=true"/>
</p>

It interface enables the user to do the following:

+ Define events.
+ Select how often and how long an event should occur.
+ Select what periods of time should have no event (shown in the plot as a translucent event).
+ Define when an event can happen.
+ Define if an event should happen before or after another event.

These rules are shown in the five tabs on the right side of the program. To delete a rule, the user only needs to click the check box in the appropriate tab.

## Plotting

To create the schedule plot, the user needs to specify how often an event should try to be placed in the schedule and then click on the make schedule button. The schedule is separated into 4 plots, consisting of one plot per week of a 28-day month. To see a specific plot, simply click on the appropriate dark blue button.

---

Note that the events were designed to have a colorscheme that best contrasts them against the others. So colors will be fairly diverse and all events with the same name will have the same color.