
using TestItems

@testitem "Empty" begin
    """Tests most basic case (no data passed)."""
    scheduler = Scheduler()
    @test create_schedule(scheduler) == []
end

@testitem "1xMax59min" begin
    """Tests 1 event of at most 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.eventCount = Set([("chem", 1, 30, "per month")])
    @test create_schedule(scheduler) == [("chem", 0, 30)]
    scheduler.eventCount = Set([("chem", 1, 45, "per month")])
    @test create_schedule(scheduler) == [("chem", 0, 45)]
    scheduler.eventCount = Set([("chem", 1, 59, "per month")])
    @test create_schedule(scheduler) == [("chem", 0, 59)]
end

@testitem "1xMax1439min" begin
    """Tests 2 event of at most 23 hours and 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.eventCount = Set([("chem", 1, 60, "per month")])
    @test create_schedule(scheduler) == [("chem", 0, 60)]
    scheduler.eventCount = Set([("chem", 1, 87, "per month")])
    @test create_schedule(scheduler) == [("chem", 0, 87)]
    scheduler.eventCount = Set([("chem", 1, 119, "per month")])
    @test create_schedule(scheduler) == [("chem", 0, 119)]
    scheduler.eventCount = Set([("chem", 1, 453, "per month")])
    @test create_schedule(scheduler) == [("chem", 0, 453)]
    scheduler.eventCount = Set([("chem", 1, 1439, "per month")])
    @test create_schedule(scheduler) == [("chem", 0, 1439)]
end

@testitem "1xPerTuesday" begin
    """Tests 1 event with 1 occurence per weekday."""
    scheduler = Scheduler()
    scheduler.eventCount = Set([("chem", 1, 30, "per tuesday")])
    @test create_schedule(scheduler) == [
        ("chem", 2880, 2910), ("chem", 12960, 12990),
        ("chem", 23040, 23070), ("chem", 33120, 33150)]
end

@testitem "1xPerWeek" begin
    """Tests 1 event with 1 occurence per week."""
    scheduler = Scheduler()
    scheduler.eventCount = Set([("chem", 1, 30, "per week")])
    @test create_schedule(scheduler) == [
        ("chem", 0, 30), ("chem", 10080, 10110),
        ("chem", 20160, 20190), ("chem", 30240, 30270)]
end

@testitem "1xPerMonth" begin
    """Tests 1 event with 1 occurence per month."""
    scheduler = Scheduler()
    scheduler.eventCount = Set([("pt", 2, 300, "per month")])
    @test create_schedule(scheduler) == [("pt", 0, 300), ("pt", 300, 600)]
end

@testitem "1xPerDay" begin
    """Tests 1 event with 1 occurence per weekday."""
    scheduler = Scheduler()
    scheduler.eventCount = Set([("chem", 1, 30, "per day")])
    @test create_schedule(scheduler) == [
        ("chem", 1440 * i, (1440 * i) + 30) for i in range(0, 27)]
end

@testitem "2xMax59min" begin
    """Tests 2 event of at most 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.eventCount = Set([("chem", 1, 30, "per month"), ("math", 1, 45, "per month")])
    @test create_schedule(scheduler) ∈ [[("chem", 0, 30), ("math", 30, 75)],[("math", 0, 45), ("chem", 45, 75)]]
    scheduler.eventCount = Set([("chem", 1, 1, "per month"), ("math", 1, 45, "per month")])
    @test create_schedule(scheduler) ∈ [[("chem", 0, 1), ("math", 1, 46)],[("math", 0, 45), ("chem", 45, 46)]]
    scheduler.eventCount = Set([("chem", 1, 59, "per month"), ("math", 1, 45, "per month")])
    @test create_schedule(scheduler) ∈ [[("math", 0, 45), ("chem", 45, 104)],[("chem", 0, 59), ("math", 59, 104)]]
    scheduler.eventCount = Set([("chem", 1, 59, "per month"), ("math", 1, 59, "per month")])
    @test create_schedule(scheduler) == [("chem", 0, 59), ("math", 59, 118)]
end

@testitem "2xMax1439min" begin
    """Tests 2 event of at most 23 hours and 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.eventCount = Set([("chem", 1, 60, "per month"), ("math", 1, 45, "per month")])
    @test create_schedule(scheduler) ∈ [[("math", 0, 45), ("chem", 45, 105)],[("chem", 0, 60), ("math", 60, 105)]]
    scheduler.eventCount = Set([("chem", 1, 160, "per month"), ("math", 1, 35, "per month")])
    @test create_schedule(scheduler) ∈ [[("math", 0, 35), ("chem", 35, 195)],[("chem", 0, 160), ("math", 160, 195)]]
    scheduler.eventCount = Set([("chem", 1, 235, "per month"), ("math", 1, 165, "per month")])
    @test create_schedule(scheduler) ∈ [[("math", 0, 165), ("chem", 165, 400)],[("chem", 0, 235), ("math", 235, 400)]]
end

@testitem "3xMax59min" begin
    """Tests 3 event of at most 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.eventCount = Set([("chem", 2, 30, "per month"), ("math", 1, 45, "per month")])
    @test create_schedule(scheduler) == [("chem", 0, 30), ("chem", 30, 60), ("math", 60, 105)]
end

@testitem "3xMax1439min" begin
    """Tests 3 event of at most 23 hours and 59 minutes duration."""
    scheduler = Scheduler()
    scheduler.eventCount = Set([("chem", 2, 300, "per month"), ("math", 1, 200, "per month")])
    @test create_schedule(scheduler) == [("chem", 0, 300), ("chem", 300, 600), ("math", 600, 800)]
end

@testitem "cleanEvents" begin
    """Tests the cleanBlockedTimeLogic() function."""
    scheduler = Scheduler()
    @test cleanEvents(Vector{Tuple{String,Int64,Int64}}()) == []
    blocks = [
        ("BLOCKED", 0, 10), ("BLOCKED", 17, 35), 
        ("BLOCKED", 20, 45), ("BLOCKED", 60, 100)]
    @test cleanEvents(blocks) == [
        ("BLOCKED", 0, 10), ("BLOCKED", 17, 45), ("BLOCKED", 60, 100)]
    blocks = [
        ("BLOCKED", 2, 10), ("BLOCKED", 5, 35), 
        ("BLOCKED", 20, 45), ("BLOCKED", 40, 100)]
    @test cleanEvents(blocks) == [
        ("BLOCKED", 2, 100)]
end

@testitem "blockedTime" begin
    """Tests blocked times functionality."""
    scheduler = Scheduler()
    # One block everyday
    scheduler.eventCount = Set([("math", 1, 55, "per month")])
    scheduler.blockedTimes = Set(Set([(0, 0, 3, 0, "every day")]))
    ans = [("BLOCKED", a*1440, (a*1440)+(60*3)) for a in range(0, 27)]
    insert!(ans, 2, ("math", 180, 235))
    @test create_schedule(scheduler) == ans
    # One block every sunday
    scheduler.eventCount = Set([("math", 1, 55, "per month")])
    scheduler.blockedTimes = Set([(0, 0, 23, 20, "every sunday")])
    ans = [("BLOCKED", 10080*a, (10080*a) + (23*60) + 20) for a in range(0, 3)]
    insert!(ans, 2, ("math", 1400, 1455))
    @test create_schedule(scheduler) == ans
end

@testitem "1xAfterLogic" begin
    """Tests event logic functionality with 1 after-based logic."""
    scheduler = Scheduler()
    scheduler.logic = Set([("break", "after", "math")])
    scheduler.eventCount = Set([("break", 1, 15, "per month"), ("math", 1, 5, "per month")])
    @test create_schedule(scheduler) == [("math", 0, 5), ("break", 5, 20)]
    scheduler.eventCount = Set([("break", 1, 40310, "per month"), ("math", 1, 5, "per month")])
    @test create_schedule(scheduler) == [("math", 0, 5), ("break", 5, 40315)]
    scheduler.logic = Set([("math", "after", "break")])
    scheduler.eventCount = Set([("break", 1, 40, "per month"), ("math", 1, 5, "per month")])
    @test create_schedule(scheduler) ∈ [[("break", 0, 40), ("math", 40, 45)]]
end

@testitem "1xBeforeLogic" begin
    """Tests event logic functionality with 1 before-based logic."""
    scheduler = Scheduler()
    scheduler.logic = Set([("break", "before", "math")])
    scheduler.eventCount = Set([("break", 1, 5, "per month"), ("math", 1, 40, "per month")])
    @test create_schedule(scheduler) ∈ [[("break", 0, 5), ("math", 5, 45)],[("math", 0, 40), ("break", 1440, 1445)]]
    scheduler.logic = Set([("math", "before", "break")])
    scheduler.eventCount = Set([("break", 1, 40200, "per month"), ("math", 1, 40, "per month")])
    @test create_schedule(scheduler) == [("math", 0, 40), ("break", 40, 40240)]
end

@testitem "1x1x1EventTimes" begin
    """Tests the EventTimes functionality with 1 event, 1 rule and 1 day."""
    scheduler = Scheduler()
    scheduler.eventTimes = Set([("math", 2, 30, 4, 0, "every day")])
    scheduler.eventCount = Set([("math", 1, 30, "per month")])
    @test create_schedule(scheduler) == [("math", 150, 180)]
    scheduler.eventCount = Set([("math", 1, 91, "per month")])
    @test create_schedule(scheduler) == []
    scheduler.eventCount = Set([("math", 1, 30, "per month")])
    scheduler.eventTimes = Set([("math", 2, 30, 4, 0, "every sunday")])
    @test create_schedule(scheduler) == [("math", 150, 180)]
    scheduler.eventTimes = Set([("math", 2, 30, 4, 0, "every monday")])
    @test create_schedule(scheduler) == [("math", 1590, 1620)]
    scheduler.eventTimes = Set([("math", 14, 30, 15, 0, "every day")])
    @test create_schedule(scheduler) == [("math", 870, 900)]
end

@testitem "1x2x1EventTimes" begin
    """Tests the EventTimes functionality with 1 event, 2 rules and 1 day."""
    scheduler = Scheduler()
    scheduler.eventTimes = Set([("math", 2, 30, 2, 45, "every day"),("math", 5, 0, 5, 30, "every day")])
    scheduler.eventCount = Set([("math", 1, 30, "per month")])
    @test create_schedule(scheduler) == [("math", 300, 330)]
end

@testitem "2x1x1EventTimes" begin
    """Tests the EventTimes functionality with 2 events, 1 rule and 1 day."""
    scheduler = Scheduler()
    scheduler.eventTimes = Set([("math", 0, 0, 1, 30, "every day")])
    scheduler.eventCount = Set([("math", 2, 30, "per month")])
    @test create_schedule(scheduler) == [("math", 0, 30),("math", 30, 60)]
end

@testitem "2x1x2CheckEventTimes" begin
    """Tests the checkEventTimes() function with 2 events, 1 rule and 2 days."""
    scheduler = Scheduler()
    scheduler.eventTimes = Set([("math", 23, 30, 1, 30, "every day")])
    scheduler.eventCount = Set([("math", 29, 60, "per month")])
    @test checkEventTimes([("START", -1, 0),("math", 1410, 1470), 
        ("math", 1470, 1530),("END", 40320, 40321)],2,scheduler) == false
end

@testitem "fillEmptyGaps" begin
    """Tests the fillEmptyGaps() function."""
    scheduler = Scheduler()
    scheduler.schedule = []
    @test fillEmptyGaps(scheduler.schedule) == [("", 0, 40320)]
    scheduler.schedule = [("math", 0, 1250), ("chem", 1305, 1440)]
    @test fillEmptyGaps(scheduler.schedule) == [
        ("math", 0, 1250),("", 1250, 1305),("chem", 1305, 1440),("", 1440, 40320)]
end

@testitem "separateMultidayEvents" begin
    """Tests the separateMultidayEvents() function."""
    scheduler = Scheduler()
    @test separateMultidayEvents(scheduler.schedule) == []
    @test separateMultidayEvents([("math", 0, 1000)]) == [("math", 0, 1000)]
    @test separateMultidayEvents([("math", 0, 1440)]) == [("math", 0, 1440)]
    @test separateMultidayEvents([("math", 0, 1500)]) == [
        ("math", 0, 1440),("math", 1440, 1500)]
    @test separateMultidayEvents([("math", 0, 3000)]) == [
        ("math", 0, 1440),("math", 1440, 2880),("math", 2880, 3000)]
    @test separateMultidayEvents([("math", 0, 1500),("chem", 1500, 3000)]) == [
        ("math", 0, 1440),("math", 1440, 1500),("chem", 1500, 2880),("chem", 2880, 3000)]
end
