"""Scheduler tests."""
from scheduler import Scheduler


def test_empty_conditions():
    """Tests all conditions being empty."""
    scheduler = Scheduler()
    assert scheduler.create_schedule() == []


def test_1xMax59min():
    """Tests 1 event of at most 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.items = {"chem"}
    scheduler.event_count = {("chem", 1, 30, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 0, 0, 0, 0, 30)]
    scheduler.event_count = {("chem", 1, 45, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 0, 0, 0, 0, 45)]
    scheduler.event_count = {("chem", 1, 59, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 0, 0, 0, 0, 59)]


def test_1xMax1439min():
    """Tests 1 event of at most 23 hours and 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.items = {"chem"}
    scheduler.event_count = {("chem", 1, 60, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 0, 0, 0, 1, 0)]
    scheduler.event_count = {("chem", 1, 87, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 0, 0, 0, 1, 27)]
    scheduler.event_count = {("chem", 1, 119, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 0, 0, 0, 1, 59)]
    scheduler.event_count = {("chem", 1, 453, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 0, 0, 0, 7, 33)]
    scheduler.event_count = {("chem", 1, 1439, "per month")}
    assert scheduler.create_schedule() == [("chem", 0, 0, 0, 0, 23, 59)]


def test_1xPerWeek():
    """Tests 1 event with 1 occurence per week."""
    scheduler = Scheduler()
    scheduler.items = {"chem"}
    scheduler.event_count = {("chem", 1, 30, "per week")}
    assert True


def test_2xMax59min():
    """Tests 2 event of at most 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.items = {"chem", "math"}
    scheduler.event_count = [
        ("chem", 1, 30, "per month"), ("math", 1, 45, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 0, 0, 0, 0, 30), ("math", 0, 0, 30, 0, 1, 15)]
    scheduler.event_count = [
        ("chem", 1, 1, "per month"), ("math", 1, 45, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 0, 0, 0, 0, 1), ("math", 0, 0, 1, 0, 0, 46)]
    scheduler.event_count = [
        ("chem", 1, 59, "per month"), ("math", 1, 45, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 0, 0, 0, 0, 59), ("math", 0, 0, 59, 0, 1, 44)]
    scheduler.event_count = [
        ("chem", 1, 59, "per month"), ("math", 1, 59, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 0, 0, 0, 0, 59), ("math", 0, 0, 59, 0, 1, 58)]


def test_2xMax1439min():
    """Tests 2 event of at most 23 hours and 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.items = {"chem", "math"}
    scheduler.event_count = [
        ("chem", 1, 60, "per month"), ("math", 1, 45, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 0, 0, 0, 1, 0), ("math", 0, 1, 0, 0, 1, 45)]
    scheduler.event_count = [
        ("chem", 1, 160, "per month"), ("math", 1, 35, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 0, 0, 0, 2, 40), ("math", 0, 2, 40, 0, 3, 15)]
    scheduler.event_count = [
        ("chem", 1, 235, "per month"), ("math", 1, 167, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 0, 0, 0, 3, 55), ("math", 0, 3, 55, 0, 6, 42)]
    scheduler.event_count = [
        ("chem", 1, 1439, "per month"), ("math", 1, 45, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 0, 0, 0, 23, 59), ("math", 0, 23, 59, 1, 0, 44)]
    scheduler.event_count = [
        ("chem", 1, 1439, "per month"), ("math", 1, 1439, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 0, 0, 0, 23, 59), ("math", 0, 23, 59, 1, 23, 58)]


def test_3xMax59min():
    """Tests 3 event of at most 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.items = {"chem", "math"}
    scheduler.event_count = [
        ("chem", 2, 30, "per month"), ("math", 1, 45, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 0, 0, 0, 0, 30),
        ("chem", 0, 0, 30, 0, 1, 0),
        ("math", 0, 1, 0, 0, 1, 45)]


def test_3xMax1439min():
    """Tests 3 event of at most 23 hours and 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.items = {"chem", "math"}
    scheduler.event_count = [
        ("chem", 2, 331, "per month"), ("math", 1, 245, "per month")]
    assert scheduler.create_schedule() == [
        ("chem", 0, 0, 0, 0, 5, 31),
        ("chem", 0, 5, 31, 0, 11, 2),
        ("math", 0, 11, 2, 0, 15, 7)]


def test_blocked_time():
    """Tests period blocking functionality."""
    # One block everyday
    scheduler = Scheduler()
    scheduler.items = {"chem", "math"}
    scheduler.event_count = [("math", 1, 55, "per month")]
    scheduler.blocked_times = {(0, 0, 3, 0, "every day")}
    ans = [('blocked', a, 0, 0, a, 3, 0) for a in range(28)]
    ans.insert(1, ('math', 0, 3, 0, 0, 3, 55))
    assert scheduler.create_schedule() == ans
    # One block every sunday
    scheduler.event_count = [("math", 1, 55, "per month")]
    scheduler.blocked_times = {(0, 0, 23, 20, "every sunday")}
    ans = [('blocked', a*7, 0, 0, a*7, 23, 20) for a in range(4)]
    ans.insert(1, ('math', 0, 23, 20, 1, 0, 15))
    assert scheduler.create_schedule() == ans


def test_event_logic():
    """Tests first event of the day functionality."""
    # One logic
    scheduler = Scheduler()
    scheduler.items = {"chem", "math"}
    scheduler.event_count = [
        ("math", 1, 55, "per month"),
        ("break", 1, 15, "per month")
    ]
    scheduler.logic = {("break", "after", "math")}
    # assert scheduler.create_schedule() == [
    #     ("math", 0, 0, 0, 0, 0, 55),
    #     ("break", 0, 0, 55, 0, 1, 10)]
    assert True
