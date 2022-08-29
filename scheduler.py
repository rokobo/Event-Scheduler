"""Scheduler class."""


from functools import lru_cache
import pandas as pd
from time import perf_counter
import cProfile
import pstats

class Scheduler:
    weekToNumber = {
        'sunday': 0, 'monday': 1, 'tuesday': 2,
        'wednesday': 3, 'thursday': 4, 'friday': 5,
        'saturday': 6
    }
    numberToWeek = [
        'sunday', 'monday', 'tuesday', 'wednesday',
        'thursday', 'friday', 'saturday'
    ]

    def __init__(self) -> None:
        self.items = set()          # ("chem", "math")
        self.event_count = set()    # ("chem", 2, 30, "per week")
        self.blocked_times = set()  # (22, 30, 23, 40, "every day")
        self.first_events = {       # 'monday': ["chem", "math"]
            'monday': None, 'tuesday': None, 'wednesday': None,
            'thursday': None, 'friday': None, 'saturday': None,
            'sunday': None
        }
        self.last_events = {
            'monday': None, 'tuesday': None, 'wednesday': None,
            'thursday': None, 'friday': None, 'saturday': None,
            'sunday': None
        }
        self.logic = set()        # ("break", "after", "mathematics")
        self.event_times = set()  # ("math", 13, 30, 14, 0, "per day")
        self.schedule = []        # (event, time1, time2) time in minutes
        self.fit_interval = 1     # Interval between each fit attempt

        # Optimizations
        self.hasFirstEvents = False
        self.allFirstEvents = ()
        self.maxEventsLeft = 0

    def reset(self) -> None:
        """
        Resets all values to empty values.
        """
        self.items = set()
        self.event_count = set()
        self.blocked_times = set()
        self.first_events = {
            'monday': None, 'tuesday': None, 'wednesday': None,
            'thursday': None, 'friday': None, 'saturday': None,
            'sunday': None
        }
        self.last_events = {
            'monday': None, 'tuesday': None, 'wednesday': None,
            'thursday': None, 'friday': None, 'saturday': None,
            'sunday': None
        }
        self.logic = set()
        self.event_times = set()
        self.schedule = []

    def create_schedule(self) -> list:
        """
        Generates the schedule. Works by parsing the events into
        tuples containing the event name and the duration.

        Returns:
            list: Schedule
        """
        start = perf_counter()
        itemsLeft = self.addEventsLeft()
        self.optimize(itemsLeft)
        schedule = self.addBlockedTimeLogic()
        schedule = [("START", -1, 0)] + schedule + [("END", 40320, 40321)]
        self.backtrack(schedule, itemsLeft, 0)
        self.schedule = self.schedule[1:-1]
        end = perf_counter()
        print(f"Finished in {round((end - start), 3)} seconds")
        return self.schedule

    def optimize(self, left: list) -> None:
        self.loop_interval = int(40320/self.fit_interval)
        if list(self.first_events.values()).count(None) != 7:
            self.hasFirstEvents = True
            self.allFirstEvents = []
            for item in self.first_events.values():
                if item is not None:
                    self.allFirstEvents.extend(item)
            self.allFirstEvents = tuple(set(self.allFirstEvents))

        self.maxEventsLeft = len(left)

    def addEventsLeft(self) -> list:
        """
        Creates a list of events to be fed to the recursive backtracking
        algorithm. It works by translating elements such as:
        ("math", 2, 30, "per month")
        to a list of two events: [("math", 30), ("math", 30)]

        Returns:
            list: List of events left to be placed on the schedule
        """
        itemsLeft = []
        for item in self.event_count:
            if item[3] == "per day":
                for _ in range(item[1] * 28):
                    itemsLeft.append((item[0], item[2]))
            elif item[3] == "per week":
                for _ in range(item[1] * 4):
                    itemsLeft.append((item[0], item[2]))
            elif item[3] == "per month":
                for _ in range(item[1]):
                    itemsLeft.append((item[0], item[2]))
            else:
                for _ in range(item[1] * 4):
                    itemsLeft.append((item[0], item[2]))
        return itemsLeft

    def addBlockedTimeLogic(self) -> list:
        blocks = []
        for block in self.blocked_times:
            frequency = block[4].split(" ")
            if frequency[1] == "day":
                for day in range(28):
                    add = (
                        "BLOCKED",
                        (1440 * day) + (block[0] * 60) + block[1],
                        (1440 * day) + (block[2] * 60) + block[3])
                    blocks.append(add)
            elif len(frequency) == 3:
                pass
            else:
                for week in range(4):
                    add = (
                        "BLOCKED",
                        (week * 10080) + (self.weekToNumber[frequency[1]] * 1440) +
                        (block[0] * 60) + block[1],
                        (week * 10080) + (self.weekToNumber[frequency[1]] * 1440) +
                        (block[2] * 60) + block[3]
                    )
                    blocks.append(add)
        return self.cleanBlockedTimeLogic(blocks)

    def cleanBlockedTimeLogic(self, blocks: list) -> list:
        """
        Joins adjacent BLOCKED events into one singular event.

        Args:
            blocks (list): List of all BLOCKED events

        Returns:
            list: Cleaned BLOCKED events
        """
        if not blocks:
            return []
        blocks.sort()
        schedule = [blocks[0]]
        for index in range(1, len(blocks)):
            current = blocks[index]
            if current[1] <= schedule[-1][2]:
                schedule[-1] = ("BLOCKED", schedule[-1][1], current[2])
            else:
                schedule.append(current)
        return schedule

    def invalid(self, schedule, index) -> bool:
        """
        Determines if the current schedule is invalid.

        Args:
            schedule (list): Current schedule.
            index (int): Index of last added event.

        Returns:
            bool: If the schedule is NOT valid.
        """
        if len(schedule) == 2 or not schedule:
            return False

        if len(schedule) > 3:
            if self.checkEventLogic(schedule, index):
                return True
        if self.checkEventCount(schedule, index):
            return True
        if self.hasFirstEvents:
            if schedule[index][0] in self.allFirstEvents:
                if self.checkFirstOrLast(schedule, True):
                    return True
        # if self.hasLastEvents:
        #     if self.checkFirstOrLast(schedule, False):
        #         return True
        return False

    def checkEventLogic(self, schedule: list, index: int) -> bool:
        """
        Checks the event logic for the given schedule.

        Args:
            schedule (list): current schedule.
            index (int): index of the last added event.

        Returns:
            bool: True if logic violation is found
        """
        for logic in self.logic:
            before = schedule[index - 1]
            event = schedule[index]
            after = schedule[index + 1]
            if logic[0] == event[0]:
                if logic[1] == "before":
                    if (before[2]//1440) != (event[1]//1440):
                        continue
                    if logic[2] != after[0]:
                        return True
                else:  # "after"
                    if (before[2]//1440) != (event[1]//1440):
                        continue
                    if logic[2] != before[0]:
                        return True
                    
            elif logic[2] == event[0]:
                if logic[1] == "before":
                    if (after[2]//1440) != (event[1]//1440):
                        continue
                    if logic[0] != before[0]:
                        return True
                else:  # "after"
                    if (before[2]//1440) != (event[1]//1440):
                        continue
                    if logic[0] != after[0]:
                        return True
        return False

    def checkEventCount(self, schedule: list, index: int) -> bool:
        """
        Checks the rules in self.event_count.

        Args:
            schedule (list): Current schedule
            index (int): Index of last added event

        Returns:
            bool: True if there is a rule violation
        """
        event = schedule[index]
        name = event[0]
        for rule in self.event_count:
            # Check if event has the same name as rule
            if name != rule[0]:
                continue
            # Check if event has the same duration as rule
            duration = rule[2]
            if (event[2] - event[1]) != duration:
                continue
            # Check if event is using a per weekday repetition
            period = rule[3].split(" ")[1]
            if period in self.weekToNumber:
                # Check if the event location matches the rule weekday
                day = event[1] // 1440
                if self.weekToNumber[period] != day % 7:
                    return True
                if self.checkEventCountInDay(schedule, day, index, rule):
                    return True
            elif period == "week":
                week = (event[1] // 1440) // 7
                if self.checkEventCountInWeek(schedule, week, index, rule):
                    return True
            elif period == "month":
                if self.checkEventCountInMonth(schedule, rule):
                    return True
            else:  # "day"
                day = event[1] // 1440
                if self.checkEventCountInDay(schedule, day, index, rule):
                    return True
        return False

    def checkEventCountInDay(self, schedule, day, index, rule):
        current = index - 1
        count = 1

        # Count events going backwards <--
        while True:
            event = schedule[current]
            event_day = event[2] // 1440
            # Check if no more events in target day
            if event_day != day:
                break
            # Check if rule applies to current event
            if event[0] != rule[0]:
                current -= 1
                continue
            # Check if event duration is the same as rule duration
            if (event[2] - event[1]) != rule[2]:
                continue
            count += 1
            current -= 1
            if current == -1:
                break

        # Count events going forward -->
        current = index + 1
        while True:
            event = schedule[current]
            event_day = event[1] // 1440
            # Check if no more events in target day
            if event_day != day:
                break
            # Check if rule applies to current event
            if event[0] != rule[0]:
                current += 1
                continue
            # Check if event duration is the same as rule duration
            if (event[2] - event[1]) != rule[2]:
                continue
            count += 1
            current += 1

        if count > rule[1]:
            return True
        return False

    def checkEventCountInWeek(self, schedule, week, index, rule):
        current = index - 1
        count = 1
        # Count events going backwards <--
        while True:
            event = schedule[current]
            if event == ("START", -1, 0):
                break
            event_week = (event[2] // 1440) // 7
            # Check if no more events in target week
            if event_week != week:
                break
            # Check if rule applies to current event
            if event[0] != rule[0]:
                current -= 1
                continue
            # Check if event duration is the same as rule duration
            if (event[2] - event[1]) != rule[2]:
                continue
            count += 1
            current -= 1

        # Count events going forward -->
        current = index + 1
        while True:
            event = schedule[current]
            if event == ("END", 40320, 40321):
                break
            event_week = (event[1] // 1440) // 7
            # Check if no more events in target week
            if event_week != week:
                break
            # Check if rule applies to current event
            if event[0] != rule[0]:
                current += 1
                continue
            # Check if event duration is the same as rule duration
            if (event[2] - event[1]) != rule[2]:
                continue
            count += 1
            current += 1

        if count > rule[1]:
            return True
        return False

    def checkEventCountInMonth(self, schedule: list, rule: tuple):
        count = 0
        for event in schedule:
            # Check if rule applies to current event
            if event[0] != rule[0]:
                continue
            # Check if event duration is the same as rule duration
            if (event[2] - event[1]) != rule[2]:
                continue
            count += 1

        if count > rule[1]:
            return True
        return False

    def checkFirstOrLast(self, schedule: list, first: bool) -> bool:
        last_day = None
        for i in range(1, len(schedule) - 1):
            event = schedule[i]
            event_start = event[1] // 1440
            event_end = event[2] // 1440
            if last_day == event_start:
                if event_start == event_end:
                    continue
                else:
                    for day in range(event_start + 1, event_end + 1):
                        allowed_events = self.first_events[
                            self.numberToWeek[day % 7]]
                        last_day = day
                        if allowed_events is None:
                            continue
                        if event[0] not in allowed_events:
                            return True
            else:
                last_day = event_start
                for day in range(event_start, event_end + 1):
                    allowed_events = self.first_events[
                        self.numberToWeek[day % 7]]
                    last_day = day
                    if allowed_events is None:
                        continue
                    if event[0] not in allowed_events:
                        return True



        return False

    def fit(self, current: list, item: list, time: int) -> list | bool:
        # Check if the event being fitted can fit at the specified location
        # check if the two adjacent events allow it to be fitted between
        index = None
        new_time = 0
        for i in range(len(current) - 1):
            start1, end1 = current[i][1:]
            start2 = current[i + 1][1]
            duration = item[1]
            if time >= start1 and time < end1:
                # Time is in the middle of event1
                # Jump to the end of event1 and place event
                if (end1 + duration) < start2:
                    index = i + 1
                    new_time = end1
                    break
            if time >= end1 and time < start2:
                # Time is between event1 and event2
                if (time + duration) <= start2:
                    index = i + 1
                    new_time = time
                    break

        if index is None:
            return None, 0, time

        # Fit the event and return
        newCurrent = current[:]
        newCurrent.insert(index, (item[0], new_time, (new_time + duration)))
        return newCurrent, index, new_time

    def backtrack(self, current, itemsLeft, add_index) -> None:
        # Base cases
        if self.invalid(current, add_index):
            return False
        if not itemsLeft:
            self.schedule = current
            return True
        # Recursive logic
        time = 0
        while 1:
            newCurrent, new_add_index, newTime = self.fit(
                current, itemsLeft[0], time)
            #if len(itemsLeft) == self.maxEventsLeft - 2:
            #    print(time, newCurrent, end='\r', flush=True)
            if newCurrent is not None:
                newItemsLeft = itemsLeft[1:]
                if self.backtrack(newCurrent, newItemsLeft, new_add_index):
                    return True
                time = newTime
            time += self.fit_interval
            if time > 40320:
                break

        return False

    def plotable_data(self) -> pd.DataFrame:
        """
        Creates a Dataframe for plotting the data

        Returns:
            pd.DataFrame: Events dataframe.
        """
        df = pd.DataFrame()
        return df

def main():
    scheduler = Scheduler()
    scheduler.items = {"chem", "math"}
    scheduler.event_count = [
        ("chem", 2, 2500, "per month"), ("math", 32, 90, "per month")]   
    scheduler.first_events["sunday"] = ["math"]
    scheduler.fit_interval = 50

    with cProfile.Profile() as pr:
        a = scheduler.create_schedule()

    stats = pstats.Stats(pr)
    stats.sort_stats(pstats.SortKey.TIME)
    stats.print_stats()
    print(a)

if __name__ == "__main__":
    main()