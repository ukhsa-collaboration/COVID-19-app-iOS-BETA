import re

class Scenario:

    @classmethod
    def from_json(cls, json):
        name = json['scenario']
        timeline = [Day.from_json(day) for day in json['timeline']]
        return cls(name, timeline)

    def __init__(self, name, timeline):
        self.name = name
        self.timeline = timeline

    def test_name(self):
        return re.subn(r'\W+', '', ''.join([ word.capitalize() for word in self.name.split()]).replace('-', '_'))[0]

class Day:

    @classmethod
    def from_json(cls, json):
        date = json['date']
        actions = [Action.from_json(action) for action in json['actions']]
        return cls(date, actions)

    def __init__(self, date, actions):
        self.date = date
        self.actions = actions

    def currentDate(self):
        year, month, day = [ int(x) for x in self.date.split('-') ]
        return 'Calendar.current.date(from: DateComponents(year: {}, month: {}, day: {}))!'.format(year, month, day)

class Action:

    @classmethod
    def from_json(cls, json):
        if 'event' in json:
            return Event.from_json(json['event'])
        elif 'assert' in json:
            return Assert.from_json(json['assert'])
        else:
            raise RuntimeError('invalid action: {}'.format(json))

    def __init__(self, code, throws=False):
        self.code = code
        self.throws = throws

class Event(Action):

    @classmethod
    def from_json(cls, json):
        if 'exposure' in json:
            return Exposure.from_json(json)
        elif 'test_result' in json:
            return TestResult.from_json(json)
        elif 'checkin' in json:
            return Checkin.from_json(json)
        elif 'self_diagnose' in json:
            return SelfDiagnose.from_json(json['self_diagnose'])
        else:
            raise RuntimeError('invalid event: {}'.format(json))

class Assert(Action):

    @classmethod
    def from_json(cls, json):
        if 'status' in json:
            return Status.from_json(json)
        elif 'drawer' in json:
            return Drawer.from_json(json)
        elif 'notification' in json:
            return Notification.from_json(json)
        else:
            raise RuntimeError('invalid action: {}'.format(json))

class Status(Assert):

    @classmethod
    def from_json(cls, json):
        if json['status'] == 'ok':
            return Ok.from_json(json)
        if json['status'] == 'exposed':
            return Exposed.from_json(json)
        if json['status'] == 'positive':
            return Positive.from_json(json)
        if json['status'] == 'exposed_symptomatic':
            return ExposedSymptomatic.from_json(json)
        if json['status'] == 'symptomatic':
            return Symptomatic.from_json(json)
        else:
            raise RuntimeError('invalid status assertion: {}'.format(json))

class Drawer(Assert):

    @classmethod
    def from_json(cls, json):
        drawer = json['drawer']
        if drawer:
            return cls("XCTAssertEqual(self.drawerMailbox.receive(), .{})".format(drawer)) 
        else:
            return cls("XCTAssertNil(self.drawerMailbox.receive())")

class Notification(Assert):

    @classmethod
    def from_json(cls, json):
        identifier = json['notification']
        if identifier:
            return cls("""\
let request = try XCTUnwrap(self.userNotificationCenter.requests.first)
XCTAssertEqual(request.identifier, "{}")
self.userNotificationCenter.requests.removeFirst()
""".format(identifier), True)
        else:
            return cls("XCTAssertTrue(self.userNotificationCenter.requests.isEmpty)")

class Exposure(Event):

    @classmethod
    def from_json(cls, json):
        date = json['exposure']
        year, month, day = [ int(x) for x in date.split('-') ]
        return cls("""\
let startDate = Calendar.current.date(from: DateComponents(year: {}, month: {}, day: {}))!
self.machine.exposed(on: startDate)""".format(year, month, day))

class TestResult(Event):

    @classmethod
    def from_json(cls, json):
        result = json['test_result']
        year, month, day = [ int(x) for x in json['test_date'].split('-') ]
        return cls("""\
let testDate = Calendar.current.date(from: DateComponents(year: {}, month: {}, day: {}))!
let testResult = TestResult(
    result: .{},
    testTimestamp: testDate,
    type: nil,
    acknowledgementUrl: nil
)
self.machine.received(testResult)""".format(year, month, day, result))

class Checkin(Event):

    @classmethod
    def from_json(cls, json):
        symptoms = ', '.join([ '.{}'.format(s) for s in json['checkin']])
        return cls("""\
machine.checkin(symptoms: [{}])""".format(symptoms))

class SelfDiagnose(Event):

    @classmethod
    def from_json(cls, json):
        symptoms = ', '.join([ '.{}'.format(s) for s in json['symptoms']])
        year, month, day = [ int(x) for x in json['start_date'].split('-') ]
        return cls("""\
let startDate = Calendar.current.date(from: DateComponents(year: {}, month: {}, day: {}))!
try machine.selfDiagnose(symptoms: [{}], startDate: startDate)""".format(year, month, day, symptoms), True)

class Ok(Status):

    @classmethod
    def from_json(cls, json):
        return cls("XCTAssertEqual(self.machine.state, .ok(StatusState.Ok()))")

class Exposed(Status):

    @classmethod
    def from_json(cls, json):
        year, month, day = [ int(x) for x in json['end_date'].split('-') ]
        return cls("""\
let endDate = Calendar.current.date(from: DateComponents(year: {}, month: {}, day: {}, hour: 7))!
guard case .exposed(let exposed) = self.machine.state else {{
    XCTFail("Expected state to be exposed, got \(self.machine.state)")
    return
}}
XCTAssertEqual(exposed.expiryDate, endDate)""".format(year, month, day))

class Positive(Status):

    @classmethod
    def from_json(cls, json):
        year, month, day = [ int(x) for x in json['end_date'].split('-') ]
        return cls("""\
let endDate = Calendar.current.date(from: DateComponents(year: {}, month: {}, day: {}, hour: 7))!
guard case .positive(let positive) = self.machine.state else {{
    XCTFail("Expected state to be positive, got \(self.machine.state)")
    return
}}
XCTAssertEqual(positive.checkinDate, endDate)""".format(year, month, day))

class ExposedSymptomatic(Status):

    @classmethod
    def from_json(cls, json):
        year, month, day = [ int(x) for x in json['end_date'].split('-') ]
        return cls("""\
let endDate = Calendar.current.date(from: DateComponents(year: {}, month: {}, day: {}, hour: 7))!
guard case .exposedSymptomatic(let exposedSymptomatic) = self.machine.state else {{
    XCTFail("Expected state to be exposedSymptomatic, got \(self.machine.state)")
    return
}}
XCTAssertEqual(exposedSymptomatic.checkinDate, endDate)""".format(year, month, day))

class Symptomatic(Status):

    @classmethod
    def from_json(cls, json):
        year, month, day = [ int(x) for x in json['end_date'].split('-') ]
        return cls("""\
let endDate = Calendar.current.date(from: DateComponents(year: {}, month: {}, day: {}, hour: 7))!
guard case .symptomatic(let symptomatic) = self.machine.state else {{
    XCTFail("Expected state to be symptomatic, got \(self.machine.state)")
    return
}}
XCTAssertEqual(symptomatic.checkinDate, endDate)""".format(year, month, day))
