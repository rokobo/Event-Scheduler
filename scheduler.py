"""Scheduler class."""


from functools import lru_cache
import pandas as pd


class Scheduler:
    blockedMap = {
        'sunday': 0, 'monday': 1, 'tuesday': 2,
        'wednesday': 3, 'thursday': 4, 'friday': 5,
        'saturday': 6,
    }

    def __init__(self) -> None:
        # ("chem", "math")
        self.items = set()
        # ("chem", 2, 30, "per week")
        self.event_count = set()
        # (22, 30, 23, 40, "every day"),
        self.blocked_times = set()
        # 'monday': ["chem", "math"]
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
        # ("break", "after", "mathematics")
        self.logic = set()
        # ("math", 13, 30, 14, 0, "per day")
        self.event_times = set()

        # (event, day1, hour1, minute1, day2, hour2, minute2)
        self.schedule = []

    def reset(self) -> None:
        self.items = {}
        self.event_count = {}
        self.blocked_times = {}
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
        self.logic = {}
        self.event_times = {}
        self.schedule = []
        return

    def create_schedule(self) -> None:
        itemsLeft = []
        schedule = []
        for item in self.event_count:
            for _ in range(item[1]):
                itemsLeft.append((item[0], item[2]))
        for block in self.blocked_times:
            frequency = block[4].split(" ")
            if frequency[1] == "day":
                for day in range(28):
                    add = ("blocked", day, block[0], block[1],
                           day, block[2], block[3])
                    schedule.append(add)
            elif len(frequency) == 3:
                pass
            else:
                for week in range(4):
                    add = (
                        "blocked",
                        (7 * week) + self.blockedMap[frequency[1]],
                        block[0], block[1],
                        (7 * week) + self.blockedMap[frequency[1]],
                        block[2], block[3]
                    )
                    schedule.append(add)

        self.backtrack(schedule, itemsLeft)
        return self.schedule

    def invalid(self, schedule) -> bool:
        if not schedule:  # Empty schedule
            return False
        for logic in self.logic:
            if logic[1] == "before":
                pass
            else:  # after
                pass
        return False

    def add_to_schedule(self, current: list, item: list) -> list | bool:
        # First check if event fits between the start of the first
        # day and the next event or if there is no next event
        if current:
            initial_fit = self.canFit(
                0, 0, 0, current[0][1], current[0][2], current[0][3], item[1]
            )
        else:
            initial_fit = True  # Empty schedule
        if initial_fit:
            newCurrent = current[:]
            newCurrent.insert(0, self.makeFit(item[0], 0, 0, 0, item[1]))
            return newCurrent, True
        # Then check the fit between the other events of the schedule
        for index in range(1, len(current)):
            event1 = current[index - 1]
            event2 = current[index]
            if self.canFit(
                event1[4], event1[5], event1[6],
                event2[1], event2[2], event2[3],
                item[1]
            ):
                newCurrent = current[:]
                newCurrent.insert(index, self.makeFit(
                    item[0], event1[4], event1[5], event1[6], item[1]
                ))
                return newCurrent, True
        final_fit = self.canFit(
            current[-1][4], current[-1][5],
            current[-1][6], 28, 0, 0, item[1])
        if final_fit:
            newCurrent = current[:]
            newCurrent.append(self.makeFit(
                item[0], current[-1][4], current[-1][5],
                current[-1][6], item[1]))
            return newCurrent, True
        # If no fit was found return False
        return current, False

    # @lru_cache(maxsize=1000)
    def canFit(self, day1: int, hour1: int, minute1: int, day2: int,
               hour2: int, minute2: int, period: int) -> bool:
        delta = (day2 - day1) * 24 * 60
        delta += (hour2 - hour1) * 60
        delta += minute2 - minute1
        if delta >= period:
            return True
        else:
            return False

    def makeFit(self, name: str, day1: int, hour1: int,
                minute1: int, duration: int) -> tuple:
        days, hours, minutes = self.minutesToDaysHoursMinutes(duration)
        endMinute = minute1 + minutes
        endHour = (endMinute // 60) + hour1 + hours
        endDay = (endHour // 24) + day1 + days
        endMinute = endMinute % 60
        endHour = endHour % 24
        return (name, day1, hour1, minute1, endDay, endHour, endMinute)

    # @lru_cache(maxsize=1000)
    def minutesToDaysHoursMinutes(self, duration: int) -> int:
        days = duration // 1440
        leftover_minutes = duration % 1440
        hours = leftover_minutes // 60
        minutes = duration - (days*1440) - (hours*60)
        return days, hours, minutes

    def backtrack(self, current, itemsLeft) -> None:
        # Base cases
        if self.invalid(current):
            return
        if not itemsLeft:
            self.schedule = current
            return
        # Recursive part
        for index, item_try in enumerate(itemsLeft):
            newCurrent, done = self.add_to_schedule(current, item_try)
            if not done:
                return
            newItemsLeft = itemsLeft[:index] + itemsLeft[index+1:]
            return self.backtrack(newCurrent, newItemsLeft)
        return

    def plotable_data(self) -> pd.DataFrame:
        """
        Creates a Dataframe for plotting the data

        Returns:
            pd.DataFrame: Events dataframe.
        """
        df = pd.DataFrame()
        return df
