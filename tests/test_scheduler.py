"""Scheduler tests."""
from scheduler import Scheduler


def test_empty_class():
    """Tests all conditions being empty."""
    scheduler = Scheduler()
    assert scheduler.create_schedule() == []


def test_1xMax59min():
    """Tests 1 event of at most 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.fit_interval = 1
    scheduler.items = {"chem"}
    scheduler.event_count = {("chem", 1, 30, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 30)]
    scheduler.event_count = {("chem", 1, 45, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 45)]
    scheduler.event_count = {("chem", 1, 59, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 59)]


def test_1xMax1439min():
    """Tests 1 event of at most 23 hours and 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.fit_interval = 1
    scheduler.items = {"chem"}
    scheduler.event_count = {("chem", 1, 60, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 60)]
    scheduler.event_count = {("chem", 1, 87, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 87)]
    scheduler.event_count = {("chem", 1, 119, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 119)]
    scheduler.event_count = {("chem", 1, 453, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 453)]
    scheduler.event_count = {("chem", 1, 1439, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 1439)]


def test_1xPerTuesday():
    """Tests 1 event with 1 occurence per weekday."""
    scheduler = Scheduler()
    scheduler.fit_interval = 10
    scheduler.items = {"chem"}
    scheduler.event_count = {("chem", 1, 30, "per tuesday")}
    assert scheduler.create_schedule() == [
        ('chem', 2880, 2910), ('chem', 12960, 12990),
        ('chem', 23040, 23070), ('chem', 33120, 33150)]


def test_1xPerWeek():
    """Tests 1 event with 1 occurence per weekday."""
    scheduler = Scheduler()
    scheduler.fit_interval = 10
    scheduler.items = {"chem"}
    scheduler.event_count = {("chem", 1, 30, "per week")}
    assert scheduler.create_schedule() == [
        ('chem', 0, 30), ('chem', 10080, 10110),
        ('chem', 20160, 20190), ('chem', 30240, 30270)]


def test_1xPerMonth():
    """Tests 1 event with 1 occurence per weekday."""
    scheduler = Scheduler()
    scheduler.fit_interval = 100
    scheduler.items = {"pt"}
    scheduler.event_count = {("pt", 2, 300, "per month")}
    assert scheduler.create_schedule() == [('pt', 0, 300), ('pt', 300, 600)]


def test_1xPerDay():
    """Tests 1 event with 1 occurence per weekday."""
    scheduler = Scheduler()
    scheduler.items = {"chem"}
    scheduler.event_count = {("chem", 1, 30, "per day")}
    scheduler.fit_interval = 10
    assert scheduler.create_schedule() == [
        ("chem", 1440 * i, (1440 * i) + 30) for i in range(28)]


def test_2xMax59min():
    """Tests 2 event of at most 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.fit_interval = 1
    scheduler.items = {"chem", "math"}
    scheduler.event_count = [
        ("chem", 1, 30, "per month"), ("math", 1, 45, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 30), ("math", 30, 75)]
    scheduler.event_count = [
        ("chem", 1, 1, "per month"), ("math", 1, 45, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 1), ("math", 1, 46)]
    scheduler.event_count = [
        ("chem", 1, 59, "per month"), ("math", 1, 45, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 59), ("math", 59, 104)]
    scheduler.event_count = [
        ("chem", 1, 59, "per month"), ("math", 1, 59, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 59), ("math", 59, 118)]


def test_2xMax1439min():
    """Tests 2 event of at most 23 hours and 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.fit_interval = 5
    scheduler.items = {"chem", "math"}
    scheduler.event_count = [
        ("chem", 1, 60, "per month"), ("math", 1, 45, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 60), ("math", 60, 105)]
    scheduler.event_count = [
        ("chem", 1, 160, "per month"), ("math", 1, 35, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 160), ("math", 160, 195)]
    scheduler.event_count = [
        ("chem", 1, 235, "per month"), ("math", 1, 165, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 235), ("math", 235, 400)]


def test_3xMax59min():
    """Tests 3 event of at most 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.fit_interval = 15
    scheduler.items = {"chem", "math"}
    scheduler.event_count = [
        ("chem", 2, 30, "per month"), ("math", 1, 45, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 30),
        ("chem", 30, 60),
        ("math", 60, 105)]


def test_3xMax1439min():
    """Tests 3 event of at most 23 hours and 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.items = {"chem", "math"}
    scheduler.fit_interval = 50
    scheduler.event_count = [
        ("chem", 2, 300, "per month"), ("math", 1, 200, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 300),
        ("chem", 300, 600),
        ("math", 600, 800)]


def test_cleanBlockedTimeLogic():
    """Tests the function cleanBlockedTimeLogic."""
    scheduler = Scheduler()
    blocks = []
    assert scheduler.cleanBlockedTimeLogic(blocks) == []
    blocks = [
        ('BLOCKED', 17, 35), ('BLOCKED', 20, 45),
        ('BLOCKED', 0, 10), ('BLOCKED', 60, 100)]
    assert scheduler.cleanBlockedTimeLogic(blocks) == [
        ('BLOCKED', 0, 10), ('BLOCKED', 17, 45), ('BLOCKED', 60, 100)]
    blocks = [
        ('BLOCKED', 5, 35), ('BLOCKED', 20, 45),
        ('BLOCKED', 2, 10), ('BLOCKED', 40, 100)]
    assert scheduler.cleanBlockedTimeLogic(blocks) == [
        ('BLOCKED', 2, 100)]


def test_blockedTime():
    """Tests period blocking functionality."""
    # One block everyday
    scheduler = Scheduler()
    scheduler.items = {"chem", "math"}
    scheduler.fit_interval = 5
    scheduler.event_count = [("math", 1, 55, "per month")]
    scheduler.blocked_times = {(0, 0, 3, 0, "every day")}
    ans = [('BLOCKED', a*1440, (a*1440)+(60*3)) for a in range(28)]
    ans.insert(1, ('math', 180, 235))
    assert scheduler.create_schedule() == ans
    # One block every sunday
    scheduler.event_count = [("math", 1, 55, "per month")]
    scheduler.blocked_times = {(0, 0, 23, 20, "every sunday")}
    ans = [('BLOCKED', 10080*a, (10080*a) + (23*60) + 20) for a in range(4)]
    ans.insert(1, ('math', 1400, 1455))
    assert scheduler.create_schedule() == ans


def test_afterLogic():
    """Tests event logic functionality."""
    scheduler = Scheduler()
    scheduler.items = {"chem", "math"}
    scheduler.logic = {("break", "after", "math")}
    scheduler.fit_interval = 1
    scheduler.event_count = [
        ("break", 1, 40310, "per month"),
        ("math", 1, 5, "per month")]
    assert scheduler.create_schedule() == [
        ('math', 0, 5), ('break', 5, 40315)]
    scheduler.event_count = [
        ("break", 1, 15, "per month"),
        ("math", 1, 5, "per month")]
    assert scheduler.create_schedule() == [
        ('break', 0, 15), ('math', 1440, 1445)]
    scheduler.logic = {("math", "after", "break")}
    scheduler.event_count = [
        ("break", 1, 40, "per month"),
        ("math", 1, 5, "per month")]
    assert scheduler.create_schedule() == [
        ('break', 0, 40), ('math', 40, 45)]


def test_beforeLogic():
    """Tests event logic functionality."""
    scheduler = Scheduler()
    scheduler.items = {"chem", "math"}
    scheduler.logic = {("break", "before", "math")}
    scheduler.fit_interval = 1
    scheduler.event_count = [
        ("break", 1, 5, "per month"),
        ("math", 1, 40, "per month")]
    assert scheduler.create_schedule() == [
        ('break', 0, 5), ('math', 5, 45)]
    scheduler.logic = {("math", "before", "break")}
    scheduler.event_count = [
        ("break", 1, 40200, "per month"),
        ("math", 1, 40, "per month")]
    assert scheduler.create_schedule() == [
        ('math', 0, 40), ('break', 40, 40240)]


def test_firstEvent():
    # scheduler = Scheduler()
    # scheduler.items = {"chem", "math"}
    # scheduler.event_count = {
    #     ("chem", 1, 30, "per month"), ("math", 1, 30, "per month")}    
    # scheduler.first_events["sunday"] = ["chem"]
    # scheduler.fit_interval = 15
    # scheduler.optimize()
    # schedule = [
    #     ("START", -1, 0), ('BLOCKED', 90, 40315), ("END", 40320, 40321)]
    # scheduler.backtrack(schedule, [('math', 30), ('chem', 30)], 0)
    # assert scheduler.schedule[1:-1] == [
    #     ('chem', 0, 30), ('math', 30, 60), ('BLOCKED', 90, 40315)]
    # scheduler.first_events["sunday"] = ["math"]
    # scheduler.backtrack(schedule, [('math', 30), ('chem', 30)], 0)
    # assert scheduler.schedule[1:-1] == [
    #     ('math', 0, 30), ('chem', 30, 60), ('BLOCKED', 90, 40315)]


    scheduler = Scheduler()
    scheduler.items = {"chem", "math"}
    scheduler.event_count = [
        ("chem", 2, 100, "per month"), ("math", 1, 100, "per month")]   
    scheduler.first_events["sunday"] = ["math"]
    scheduler.fit_interval = 100
    assert scheduler.create_schedule() == [
        ('math', 0, 100), ('chem', 100, 200), ('chem', 200, 300)]



 

def test_lastEvent():
    scheduler = Scheduler()
    assert False

def test_eventTimes():
    scheduler = Scheduler()
    assert False
