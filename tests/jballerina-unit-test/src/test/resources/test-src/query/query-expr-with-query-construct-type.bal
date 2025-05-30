// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

type PersonX record {|
    string firstName;
    string lastName;
    int age;
|};

type EmployeeX record {|
    string firstName;
    string lastName;
    string dept;
|};

type DepartmentX record {
    string dept;
};

type EmpProfileX record {|
    string firstName;
    string lastName;
    int age;
    string dept;
    string status;
|};

type PersonValueX record {|
    PersonX value;
|};

type EmployeeValueX record {|
    EmployeeX value;
|};

type EmpProfileValueX record {|
    EmpProfileX value;
|};

type CustomerX record {|
    readonly int id;
    readonly string name;
    int noOfItems;
|};

type CustomerTableX table<CustomerX> key(id, name);

type CustomerKeyLessTableX table<CustomerX>;

type CustomerValueX record {|
    CustomerX value;
|};

function getPersonValue((record {|PersonX value;|}|error?)|(record {|PersonX value;|}?) returnedVal)
returns PersonValueX? {
    var result = returnedVal;
    if (result is PersonValueX) {
        return result;
    } else {
        return ();
    }
}

function getEmployeeValue((record {|EmployeeX value;|}|error?)|(record {|EmployeeX value;|}?) returnedVal)
returns EmployeeValueX? {
    var result = returnedVal;
    if (result is EmployeeValueX) {
        return result;
    } else {
        return ();
    }
}

function getEmpProfileValue((record {|EmpProfileX value;|}|error?)|(record {|EmpProfileX value;|}?) returnedVal)
returns EmpProfileValueX? {
    var result = returnedVal;
    if (result is EmpProfileValueX) {
        return result;
    } else {
        return ();
    }
}

function getCustomer(record {|CustomerX value;|}? returnedVal) returns CustomerX? {
    if (returnedVal is CustomerValueX) {
        return returnedVal.value;
    } else {
        return ();
    }
}

// functions to test query-construct-type --> stream

function testSimpleQueryReturnStream() returns boolean {
    boolean testPassed = true;

    PersonX p1 = {firstName: "Alex", lastName: "George", age: 23};
    PersonX p2 = {firstName: "Ranjan", lastName: "Fonseka", age: 30};
    PersonX p3 = {firstName: "John", lastName: "David", age: 33};

    PersonX[] personList = [p1, p2, p3];

    stream<PersonX> outputPersonStream = stream from var person in personList
        where person.firstName == "John"
        let int newAge = 34
        select {
            firstName: person.firstName,
            lastName: person.lastName,
            age: newAge
        };

    record {|PersonX value;|}? person = getPersonValue(outputPersonStream.next());
    testPassed = testPassed && person?.value?.firstName == "John" && person?.value?.lastName == "David" &&
    person?.value?.age == 34;

    person = getPersonValue(outputPersonStream.next());
    testPassed = testPassed && person == ();

    return testPassed;
}

function testSimpleQueryReturnStream2() {
    boolean testPassed = true;

    PersonX p1 = {firstName: "Alex", lastName: "George", age: 23};
    PersonX p2 = {firstName: "Ranjan", lastName: "Fonseka", age: 30};
    PersonX p3 = {firstName: "John", lastName: "David", age: 33};

    PersonX[] personList = [p1, p2, p3];

    var outputPersonStream = stream from var person in personList
        where person.firstName == "John"
        let int newAge = 34
        select {
            firstName: person.firstName,
            lastName: person.lastName,
            age: newAge
        };

    assertTrue(outputPersonStream is stream<PersonX>);
    stream<PersonX> _ = outputPersonStream;

    record {|PersonX value;|}? person = getPersonValue(outputPersonStream.next());
    testPassed = testPassed && person?.value?.firstName == "John" && person?.value?.lastName == "David" &&
    person?.value?.age == 34;

    person = getPersonValue(outputPersonStream.next());
    testPassed = testPassed && person == ();

    assertTrue(testPassed);
}

type ValueRecordX record {|
    string value;
|};

type TestStreamX stream<string, error?>;

class TestGeneratorX {
    public isolated function next() returns ValueRecordX|error? {
        return {value: "Ballerina"};
    }
}

function testSimpleQueryReturnStream3() {
    TestGeneratorX generator = new ();
    TestStreamX testStream = new (generator);

    var outputIntPersonStream = stream from var _ in testStream
        select 1;
    assertTrue(outputIntPersonStream is stream<int, error?>);
    stream<int, error?> _ = outputIntPersonStream;
    (record {|int value;|}|error)? x1 = outputIntPersonStream.next();
    if (x1 is record {|int value;|}) {
        assertEqual(x1.value, 1);
    } else {
        assertTrue(false);
    }

    var outputStringPersonStream = stream from var _ in testStream
        select "ABCD";
    assertTrue(outputStringPersonStream is stream<string, error?>);
    stream<string, error?> _ = outputStringPersonStream;
    (record {|string value;|}|error)? x2 = outputStringPersonStream.next();
    if (x2 is record {|string value;|}) {
        assertEqual(x2.value, "ABCD");
    } else {
        assertTrue(false);
    }
}

function testStreamInFromClauseWithReturnStream() returns boolean {
    boolean testPassed = true;

    PersonX p1 = {firstName: "Alex", lastName: "George", age: 23};
    PersonX p2 = {firstName: "Ranjan", lastName: "Fonseka", age: 30};
    PersonX p3 = {firstName: "John", lastName: "David", age: 33};

    PersonX[] personList = [p1, p2, p3];

    stream<EmployeeX> outputEmployeeStream = stream from var {firstName, lastName, dept} in
                    <stream<EmployeeX>>personList.toStream().filter(function(PersonX person) returns boolean {
            return person.firstName == "John";
        }).'map(function(PersonX person) returns EmployeeX {
            EmployeeX employee = {
                firstName: person.firstName,
                lastName: person.lastName,
                dept: "Engineering"
            };
            return employee;
        })
        select {
            firstName: firstName,
            lastName: lastName,
            dept: dept
        };

    record {|EmployeeX value;|}? employee = getEmployeeValue(outputEmployeeStream.next());
    testPassed = testPassed && employee?.value?.firstName == "John" && employee?.value?.lastName == "David" &&
    employee?.value?.dept == "Engineering";

    employee = getEmployeeValue(outputEmployeeStream.next());
    testPassed = testPassed && employee == ();

    return testPassed;
}

function testStreamInFromClauseWithReturnStream2() {
    boolean testPassed = true;

    PersonX p1 = {firstName: "Alex", lastName: "George", age: 23};
    PersonX p2 = {firstName: "Ranjan", lastName: "Fonseka", age: 30};
    PersonX p3 = {firstName: "John", lastName: "David", age: 33};

    PersonX[] personList = [p1, p2, p3];

    var outputEmployeeStream = stream from var {firstName, lastName, dept} in
                    <stream<EmployeeX>>personList.toStream().filter(function(PersonX person) returns boolean {
            return person.firstName == "John";
        }).'map(function(PersonX person) returns EmployeeX {
            EmployeeX employee = {
                firstName: person.firstName,
                lastName: person.lastName,
                dept: "Engineering"
            };
            return employee;
        })
        select {
            firstName: firstName,
            lastName: lastName,
            dept: dept
        };

    assertTrue(outputEmployeeStream is stream<EmployeeX>);
    stream<EmployeeX> _ = outputEmployeeStream;

    record {|EmployeeX value;|}? employee = getEmployeeValue(outputEmployeeStream.next());
    testPassed = testPassed && employee?.value?.firstName == "John" && employee?.value?.lastName == "David" &&
    employee?.value?.dept == "Engineering";

    employee = getEmployeeValue(outputEmployeeStream.next());
    testPassed = testPassed && employee == ();
    assertTrue(testPassed);
}

function testMultipleFromWhereAndLetReturnStream() returns boolean {
    boolean testPassed = true;

    EmployeeX e1 = {firstName: "John", lastName: "Fonseka", dept: "Engineering"};
    EmployeeX e2 = {firstName: "John", lastName: "David", dept: "HR"};

    DepartmentX d1 = {dept: "Support"};
    DepartmentX d2 = {dept: "Dev"};

    EmployeeX[] employeeList = [e1, e2];
    DepartmentX[] departmentList = [d1, d2];

    stream<EmployeeX> outputEmployeeStream = stream from var emp in employeeList
        from var department in departmentList
        where emp.firstName == "John"
        where emp.dept == "Engineering"
        let string fname = "Johns"
        let string deptName = "Research"
        select {
            firstName: fname,
            lastName: emp.lastName,
            dept: deptName
        };

    record {|EmployeeX value;|}? employee = getEmployeeValue(outputEmployeeStream.next());
    testPassed = testPassed && employee?.value?.firstName == "Johns" && employee?.value?.lastName == "Fonseka" &&
        employee?.value?.dept == "Research";

    employee = getEmployeeValue(outputEmployeeStream.next());
    testPassed = testPassed && employee?.value?.firstName == "Johns" && employee?.value?.lastName == "Fonseka" &&
        employee?.value?.dept == "Research";

    employee = getEmployeeValue(outputEmployeeStream.next());
    testPassed = testPassed && employee == ();

    return testPassed;
}

function testMultipleFromWhereAndLetReturnStream2() {
    boolean testPassed = true;

    EmployeeX e1 = {firstName: "John", lastName: "Fonseka", dept: "Engineering"};
    EmployeeX e2 = {firstName: "John", lastName: "David", dept: "HR"};

    DepartmentX d1 = {dept: "Support"};
    DepartmentX d2 = {dept: "Dev"};

    EmployeeX[] employeeList = [e1, e2];
    DepartmentX[] departmentList = [d1, d2];

    var outputEmployeeStream = stream from var emp in employeeList
        from var department in departmentList
        where emp.firstName == "John"
        where emp.dept == "Engineering"
        let string fname = "Johns"
        let string deptName = "Research"
        select {
            firstName: fname,
            lastName: emp.lastName,
            dept: deptName
        };

    assertTrue(outputEmployeeStream is stream<EmployeeX>);
    stream<EmployeeX> _ = outputEmployeeStream;

    record {|EmployeeX value;|}? employee = getEmployeeValue(outputEmployeeStream.next());
    testPassed = testPassed && employee?.value?.firstName == "Johns" && employee?.value?.lastName == "Fonseka" &&
        employee?.value?.dept == "Research";

    employee = getEmployeeValue(outputEmployeeStream.next());
    testPassed = testPassed && employee?.value?.firstName == "Johns" && employee?.value?.lastName == "Fonseka" &&
        employee?.value?.dept == "Research";

    employee = getEmployeeValue(outputEmployeeStream.next());
    testPassed = testPassed && employee == ();
    assertTrue(testPassed);
}

type Employee2X record {
    readonly string name;
    int salary;
};

type TblX table<Employee2X> key(name);

function testConstructTablesWithRecords() {
    table<Employee2X> key(name) t = table [
        {name: "John", salary: 100},
        {name: "Jane", salary: 200}
    ];

    var ct = from Employee2X e in t
        select e;
    assertTrue(ct is table<Employee2X>);
    table<Employee2X> a = ct;
    assertEqual(a.toString(), "[{\"name\":\"John\",\"salary\":100},{\"name\":\"Jane\",\"salary\":200}]");

    table<record {readonly string name; int salary;}> key(name) t2 = table [
        {name: "John", salary: 100},
        {name: "Jane", salary: 200}
    ];

    var ct2 = from record {readonly string name; int salary;} e in t2
        select e;
    assertTrue(ct2 is table<record {readonly string name; int salary;}>);
    table<record {readonly string name; int salary;}> a2 = ct2;
    assertEqual(a2.toString(), "[{\"name\":\"John\",\"salary\":100},{\"name\":\"Jane\",\"salary\":200}]");

    var ct3 = from Employee2X e in t
        select {name: e.name};
    assertTrue(ct3 is table<record {string name;}>);
    table<record {string name;}> a3 = ct3;
    assertEqual(a3.toString(), "[{\"name\":\"John\"},{\"name\":\"Jane\"}]");

    TblX t3 = table [
        {name: "John", salary: 100},
        {name: "Jane", salary: 200}
    ];

    var ct4 = from Employee2X e in t3
        select e;
    assertTrue(ct4 is table<Employee2X>);
    table<Employee2X> a4 = ct4;
    assertEqual(a4.toString(), "[{\"name\":\"John\",\"salary\":100},{\"name\":\"Jane\",\"salary\":200}]");
}

function testConstructMapsWithTuples() {
    map<int> a = {"a": 1, "b": 2};

    var cm = map from var i in a
        select ["A", 1];
    assertTrue(cm is map<int>);
    map<int> cm2 = cm;
    assertEqual(cm2, {"A": 1});
}

function testInnerJoinAndLimitReturnStream() returns boolean {
    boolean testPassed = true;

    PersonX p1 = {firstName: "Alex", lastName: "George", age: 23};
    PersonX p2 = {firstName: "Ranjan", lastName: "Fonseka", age: 30};

    EmployeeX e1 = {firstName: "Alex", lastName: "George", dept: "Engineering"};
    EmployeeX e2 = {firstName: "John", lastName: "David", dept: "HR"};
    EmployeeX e3 = {firstName: "Ranjan", lastName: "Fonseka", dept: "Operations"};

    PersonX[] personList = [p1, p2];
    EmployeeX[] employeeList = [e1, e2, e3];

    stream<EmpProfileX> outputEmpProfileStream = stream from var person in personList.toStream()
        join EmployeeX employee in employeeList.toStream()
            on person.firstName equals employee.firstName
        limit 1
        select {
            firstName: employee.firstName,
            lastName: employee.lastName,
            age: person.age,
            dept: employee.dept,
            status: "Permanent"
        };

    record {|EmpProfileX value;|}? empProfile = getEmpProfileValue(outputEmpProfileStream.next());
    testPassed = testPassed && empProfile?.value?.firstName == "Alex" && empProfile?.value?.lastName == "George" &&
        empProfile?.value?.age == 23 && empProfile?.value?.dept == "Engineering" &&
        empProfile?.value?.status == "Permanent";

    empProfile = getEmpProfileValue(outputEmpProfileStream.next());
    testPassed = testPassed && empProfile == ();

    return testPassed;
}

function testInnerJoinAndLimitReturnStream2() {
    boolean testPassed = true;

    PersonX p1 = {firstName: "Alex", lastName: "George", age: 23};
    PersonX p2 = {firstName: "Ranjan", lastName: "Fonseka", age: 30};

    EmployeeX e1 = {firstName: "Alex", lastName: "George", dept: "Engineering"};
    EmployeeX e2 = {firstName: "John", lastName: "David", dept: "HR"};
    EmployeeX e3 = {firstName: "Ranjan", lastName: "Fonseka", dept: "Operations"};

    PersonX[] personList = [p1, p2];
    EmployeeX[] employeeList = [e1, e2, e3];

    var outputEmpProfileStream = stream from var person in personList.toStream()
        join EmployeeX employee in employeeList.toStream()
            on person.firstName equals employee.firstName
        limit 1
        select {
            firstName: employee.firstName,
            lastName: employee.lastName,
            age: person.age,
            dept: employee.dept,
            status: "Permanent"
        };

    assertTrue(outputEmpProfileStream is stream<EmpProfileX>);
    stream<EmpProfileX> _ = outputEmpProfileStream;

    record {|EmpProfileX value;|}? empProfile = getEmpProfileValue(outputEmpProfileStream.next());
    testPassed = testPassed && empProfile?.value?.firstName == "Alex" && empProfile?.value?.lastName == "George" &&
        empProfile?.value?.age == 23 && empProfile?.value?.dept == "Engineering" &&
        empProfile?.value?.status == "Permanent";

    empProfile = getEmpProfileValue(outputEmpProfileStream.next());
    testPassed = testPassed && empProfile == ();
    assertTrue(testPassed);
}

// functions to test query-construct-type --> table

function testSimpleQueryExprReturnTable() returns boolean {
    boolean testPassed = true;

    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};

    CustomerX[] customerList = [c1, c2, c3];

    CustomerTableX customerTable = table key(id, name) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        };

    if (customerTable is CustomerTableX) {
        var itr = customerTable.iterator();
        CustomerX? customer = getCustomer(itr.next());
        testPassed = testPassed && customer == customerList[0];
        customer = getCustomer(itr.next());
        testPassed = testPassed && customer == customerList[1];
        customer = getCustomer(itr.next());
        testPassed = testPassed && customer == customerList[2];
        customer = getCustomer(itr.next());
        testPassed = testPassed && customer == ();
    }

    return testPassed;
}

function testSimpleQueryExprReturnTable2() {
    boolean testPassed = true;

    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};

    CustomerX[] customerList = [c1, c2, c3];

    var customerTable = table key(id, name) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        };

    assertTrue(customerTable is CustomerTableX);
    CustomerTableX _ = customerTable;

    if (customerTable is CustomerTableX) {
        var itr = customerTable.iterator();
        CustomerX? customer = getCustomer(itr.next());
        testPassed = testPassed && customer == customerList[0];
        customer = getCustomer(itr.next());
        testPassed = testPassed && customer == customerList[1];
        customer = getCustomer(itr.next());
        testPassed = testPassed && customer == customerList[2];
        customer = getCustomer(itr.next());
        testPassed = testPassed && customer == ();
    }

    assertTrue(testPassed);
}

function testTableWithDuplicateKeys() {
    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};

    CustomerX[] customerList = [c1, c2, c1];

    CustomerTableX customerTable = table key(id, name) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        };

    assertEqual(customerTable, table key(id, name) [
                {"id": 1, "name": "Melina", "noOfItems": 12},
                {"id": 2, "name": "James", "noOfItems": 5}
            ]);
}

function testTableWithDuplicateKeys2() {
    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};

    CustomerX[] customerList = [c1, c2, c1];

    var customerTable = table key(id, name) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        };

    assertTrue(customerTable is CustomerTableX);
    CustomerTableX _ = customerTable;

    assertEqual(customerTable, table key(id, name) [
                {"id": 1, "name": "Melina", "noOfItems": 12},
                {"id": 2, "name": "James", "noOfItems": 5}
            ]);
}

function testTableNoDuplicatesAndOnConflictReturnTable() returns boolean {
    boolean testPassed = true;
    error onConflictError = error("Key Conflict", message = "cannot insert.");

    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};

    CustomerX[] customerList = [c1, c2, c3];

    CustomerTableX|error customerTable = table key(id, name) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict onConflictError;

    if (customerTable is CustomerTableX) {
        var itr = customerTable.iterator();
        CustomerX? customer = getCustomer(itr.next());
        testPassed = testPassed && customer == customerList[0];
        customer = getCustomer(itr.next());
        testPassed = testPassed && customer == customerList[1];
        customer = getCustomer(itr.next());
        testPassed = testPassed && customer == customerList[2];
        customer = getCustomer(itr.next());
        testPassed = testPassed && customer == ();
    }

    return testPassed;
}

function testTableWithDuplicatesAndOnConflictReturnTable() {
    error onConflictError = error("Key Conflict", message = "cannot insert.");

    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};

    CustomerX[] customerList = [c1, c2, c1];

    CustomerTableX|error customerTable = table key(id, name) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict onConflictError;

    validateKeyConflictError(customerTable);
}

function testQueryExprWithOtherClausesReturnTable() {
    error onConflictError = error("Key Conflict", message = "cannot insert.");

    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};

    PersonX p1 = {firstName: "Amy", lastName: "Melina", age: 23};
    PersonX p2 = {firstName: "Frank", lastName: "James", age: 30};

    CustomerX[] customerList = [c1, c2, c1];
    PersonX[] personList = [p1, p2];

    CustomerTableX|error customerTable = table key(id, name) from var customer in customerList
        from var person in personList
        let int items = 25
        let string customerName = "Bini"
        where customer.id == 1
        where person.firstName == "Amy"
        select {
            id: customer.id,
            name: customerName,
            noOfItems: items
        }
        on conflict onConflictError;

    validateKeyConflictError(customerTable);
}

function validateKeyConflictError(any|error value) {
    if (value is error) {
        any|error detailMessage = value.detail()["message"];
        if (value.message() == "Key Conflict"
            && detailMessage is string
            && detailMessage == "cannot insert.") {
            return;
        }
        panic error("Assertion error");
    }
    panic error("Expected error, found: " + (typeof value).toString());
}

function testQueryExprWithJoinClauseReturnTable() {
    error onConflictError = error("Key Conflict", message = "cannot insert.");

    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};

    PersonX p1 = {firstName: "Amy", lastName: "Melina", age: 23};
    PersonX p2 = {firstName: "Frank", lastName: "James", age: 30};

    CustomerX[] customerList = [c1, c2, c1];
    PersonX[] personList = [p1, p2];

    CustomerTableX|error customerTable = table key(id, name) from var customer in customerList
        join var person in personList
        on customer.name equals person.lastName
        select {
            id: customer.id,
            name: person.firstName,
            noOfItems: customer.noOfItems
        }
        on conflict onConflictError;

    validateKeyConflictError(customerTable);
}

function testQueryExprWithLimitClauseReturnTable() returns boolean {
    boolean testPassed = true;
    error onConflictError = error("Key Conflict", message = "cannot insert.");

    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Melina", noOfItems: 25};

    CustomerX[] customerList = [c1, c2, c3];

    CustomerTableX|error customerTable = table key(id, name) from var customer in customerList.toStream()
        where customer.name == "Melina"
        limit 1
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict onConflictError;

    if (customerTable is CustomerTableX) {
        var itr = customerTable.iterator();
        CustomerX? customer = getCustomer(itr.next());
        testPassed = testPassed && customer == customerList[0];
        customer = getCustomer(itr.next());
        testPassed = testPassed && customer == ();
    }

    return testPassed;
}

function testKeyLessTableWithReturnTable() returns boolean {
    boolean testPassed = true;

    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};

    CustomerX[] customerList = [c1, c2, c3];

    CustomerKeyLessTableX customerTable = table key(id, name) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        };

    if (customerTable is CustomerKeyLessTableX) {
        var itr = customerTable.iterator();
        CustomerX? customer = getCustomer(itr.next());
        testPassed = testPassed && customer == customerList[0];
        customer = getCustomer(itr.next());
        testPassed = testPassed && customer == customerList[1];
        customer = getCustomer(itr.next());
        testPassed = testPassed && customer == customerList[2];
        customer = getCustomer(itr.next());
        testPassed = testPassed && customer == ();
    }

    return testPassed;
}

type UserX record {
    readonly int id;
    string firstName;
    string lastName;
    int age;
};

function testQueryConstructingTableUpdateKeyPanic1() returns error? {
    table<UserX> key(id) users = table [
        {id: 1, firstName: "John", lastName: "Doe", age: 25}
    ];

    var result = table key(id, name) from var user in users
        where user.age > 21 && user.age < 60
        select {id: user.id, name: user.firstName, user};

    var r2 = <record {
        int id;
        string name;
        UserX user;
    }>result[1, "John"];

    r2.id = 1;
}

type NewUserX record {|
    readonly int id;
    readonly string name;
    UserX user;
|};

function testQueryConstructingTableUpdateKeyPanic2() returns error? {
    table<UserX> key(id) users = table [
        {id: 1, firstName: "John", lastName: "Doe", age: 25}
    ];

    table<record {|readonly int id; readonly string name; UserX user;|}> key(id, name) result =
                                table key(id, name) from var user in users
    where user.age > 21 && user.age < 60
    select {id: user.id, name: user.firstName, user};

    var r2 = <record {
        int id;
        string name;
        UserX user;
    }>result[1, "John"];

    r2.id = 2;
}

type CustomErrorDetailX record {|
    string message;
    int code;
|};

type CustomErrorX error<CustomErrorDetailX>;

function testTableOnConflict() {
    error? onConflictError1 = error("Key Conflict", message = "cannot insert.");
    error|null onConflictError2 = ();
    error|null onConflictError3 = null;
    CustomErrorX? onConflictError4 = error("error msg 1", message = "error 1", code = 500);
    CustomErrorX? onConflictError5 = error("error msg 2", message = "error 2", code = 500);

    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 1, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};

    CustomerX[] customerList = [c1, c2, c3];

    var customerTable1 = table key(id) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict onConflictError1;

    assertEqual(customerTable1, onConflictError1);

    var customerTable2 = table key(id) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict onConflictError2;

    assertEqual(customerTable2, table key(id) [
                {"id": 1, "name": "James", "noOfItems": 5},
                {"id": 3, "name": "Anne", "noOfItems": 20}
            ]);

    var customerTable3 = table key(id) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict onConflictError3;

    assertEqual(customerTable3, table key(id) [
                {"id": 1, "name": "James", "noOfItems": 5},
                {"id": 3, "name": "Anne", "noOfItems": 20}
            ]);

    var customerTable4 = table key(id) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict onConflictError4;

    assertEqual(customerTable4, onConflictError4);

    var customerTable5 = table key(id) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict onConflictError5;

    assertEqual(customerTable5, onConflictError5);

    var customerTable6 = table key(id) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict null;

    assertEqual(customerTable6, table key(id) [
                {"id": 1, "name": "James", "noOfItems": 5},
                {"id": 3, "name": "Anne", "noOfItems": 20}
            ]);

    var customerTable7 = table key(id) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict ();

    assertEqual(customerTable7, table key(id) [
                {"id": 1, "name": "James", "noOfItems": 5},
                {"id": 3, "name": "Anne", "noOfItems": 20}
            ]);
}

type Token record {|
    readonly int idx;
    string value;
|};

type TokenTable table<Token> key(idx);

function testQueryConstructingTableWithOnConflictClauseHavingNonTableQueryInLetClause() {
    TokenTable|error tbl1 = table key(idx) from int i in 1 ... 3
        let int[] arr = from var j in 1 ... 3
            select j
        select {
            idx: arr[i - 1],
            value: "A" + i.toString()
        }
        on conflict error("Duplicate Key");

    TokenTable expectedTbl = table [
        {"idx": 1, "value": "A1"},
        {"idx": 2, "value": "A2"},
        {"idx": 3, "value": "A3"}
    ];

    assertEqual(true, tbl1 is TokenTable);
    if tbl1 is TokenTable {
        assertEqual(expectedTbl, tbl1);
    }

    TokenTable|error tbl2 = table key(idx) from int i in [1, 2, 1]
        let int[] arr = from var j in 1 ... 3
            select j
        select {
            idx: arr[i],
            value: "A" + i.toString()
        }
        on conflict error("Duplicate Key");

    assertEqual(true, tbl2 is error);
    if tbl2 is error {
        assertEqual("Duplicate Key", tbl2.message());
    }
}

function testQueryConstructingTableWithOnConflictClauseHavingNonTableQueryInWhereClause() {
    TokenTable|error tbl1 = table key(idx) from int i in 1 ... 3
        let int[] arr = [1, 2, 3]
        where arr == from int j in 1 ... 3
            select j
        select {
            idx: i,
            value: "A" + i.toString()
        }
        on conflict error("Duplicate Key");

    TokenTable expectedTbl = table [
        {"idx": 1, "value": "A1"},
        {"idx": 2, "value": "A2"},
        {"idx": 3, "value": "A3"}
    ];

    assertEqual(true, tbl1 is TokenTable);
    if tbl1 is TokenTable {
        assertEqual(expectedTbl, tbl1);
    }

    TokenTable|error tbl2 = table key(idx) from int i in [1, 2, 1]
        let int[] arr = [1, 2, 3]
        where arr == from int j in 1 ... 3
            select j
        select {
            idx: i,
            value: "A" + i.toString()
        }
        on conflict error("Duplicate Key");

    assertEqual(true, tbl2 is error);
    if tbl2 is error {
        assertEqual("Duplicate Key", tbl2.message());
    }
}

function testQueryConstructingTableWithOnConflictsWithVarRef() {
    TokenTable|error tbl1 = table key(idx) from int i in [1, 2, 3, 1, 2, 3]
        let string value = "A" + i.toString()
        select {
            idx: i,
            value
        }
        on conflict error(string `Duplicate Key: ${i} Value: ${value}`);

    assertEqual(true, tbl1 is error);
    assertEqual("Duplicate Key: 1 Value: A1", (<error>tbl1).message());

    int duplicateKey = 1;
    TokenTable|error tbl2 = table key(idx) from int i in [1, 2, 3, 1, 2, 3]
        let string value = "A" + i.toString()
        select {
            idx: i,
            value
        }
        on conflict error(string `Duplicate Key: ${duplicateKey} Value: ${value}`);
    assertEqual(true, tbl2 is error);
    assertEqual("Duplicate Key: 1 Value: A1", (<error>tbl2).message());
}

function testMapConstructingQueryExpr() {
    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};

    CustomerX[] list1 = [c1, c2, c3];

    map<CustomerX> map1 = map from var customer in list1
        select [customer.id.toString(), customer];
    assertEqual(map1, {"1": {id: 1, name: "Melina", noOfItems: 12}, "2": {id: 2, name: "James", noOfItems: 5}, "3": {id: 3, name: "Anne", noOfItems: 20}});

    [string:Char, decimal] t1 = ["a", 1.234d];
    [string:Char, int] t2 = ["b", 123];
    string:Char[2] t3 = ["c", "a"];

    [string:Char, string|int|decimal][] list2 = [t1, t2, t3];

    map<string|int|decimal> map2 = map from var item in list2
        select [item[0], item[1]];
    assertEqual(map2, {"a": 1.234d, "b": 123, "c": "a"});

    [string:Char, byte|int:Signed8] t4 = ["a", 123];
    [string:Char, int:Signed16] t5 = ["b", 123];
    [string, int] t6 = ["c", -123];
    [string, int:Unsigned32] t7 = ["zero", 0];

    [string, int][] list3 = [t4, t5, t6, t7];

    map<string|int> map3 = map from var item in list3
        select [item[0], item[1]];
    assertEqual(map3, {"a": 123, "b": 123, "c": -123, "zero": 0});

    [string:Char, byte|int:Signed8] t8 = ["a", 123];
    [string:Char, int:Signed16] t9 = ["b", 123];
    [string, int|error] t10 = ["c", error("Error")];
    [string, int:Unsigned32] t11 = ["zero", 0];

    [string, int|error][] list4 = [t8, t9, t10, t11];

    map<string|int|error> map4 = map from var item in list4
        select [item[0], item[1]];

    map<string|int|error> expectedMap = {"a": 123, "b": 123, "c": error("Error"), "zero": 0};

    assertEqual(expectedMap.length(), (<map<string|int|error>>map4).length());
    foreach var key in expectedMap.keys() {
        assertEqual(expectedMap[key], (<map<string|int|error>>map4)[key]);
    }
}

function testMapConstructingQueryExpr2() {
    map<int> map1 = map from var e in map from var e in [1, 2, 10, 3, 5, 20]
            order by e descending
            select [e.toString(), e]
        order by e ascending
        select [e.toString(), e];
    assertEqual(map1, {"1": 1, "2": 2, "3": 3, "5": 5, "10": 10, "20": 20});

    map<int> map2 = map from var e in (from var e in [1, 2, 5, 4]
            let int f = e / 2
            order by f ascending
            select f)
        order by e descending
        select [e.toString(), e];
    assertEqual(map2, {"2": 2, "1": 1, "0": 0});
}

function testMapConstructingQueryExprWithDuplicateKeys() {
    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};

    CustomerX[] list1 = [c1, c2, c3, c1, c2, c3];

    var map1 = map from var customer in list1
        select [customer.id.toString(), customer];
    assertEqual(map1, {"1": {id: 1, name: "Melina", noOfItems: 12}, "2": {id: 2, name: "James", noOfItems: 5}, "3": {id: 3, name: "Anne", noOfItems: 20}});

    string[*] t1 = ["a", "ABC"];
    [string:Char, int] t2 = ["b", 123];
    string:Char[2] t3 = ["c", "a"];

    [string, string|int][] list2 = [t1, t2, t3, t1, t2, t3];

    map<string|int> map2 = map from var item in list2
        select [item[0], item[1]];
    assertEqual(map2, {"a": "ABC", "b": 123, "c": "a"});

    [string:Char, byte|int:Signed8] t4 = ["a", 123];
    [string:Char, int:Signed16] t5 = ["b", 123];
    [string, int] t6 = ["c", -123];
    [string, int:Unsigned32] t7 = ["zero", 0];

    [string, int][] list3 = [t4, t5, t4, t6, t6, t7, t7, t4];

    map<string|int> map3 = map from var item in list3
        select [item[0], item[1]];
    assertEqual(map3, {"a": 123, "b": 123, "c": -123, "zero": 0});
}

function testMapConstructingQueryExprWithOnConflict() {
    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};
    ()|error conflictMsg1 = ();

    CustomerX[] list1 = [c1, c2, c3, c1, c2, c3];

    var mapWithOnConflict1 = map from var customer in list1
        select [customer.id.toString(), customer]
        on conflict conflictMsg1;

    var mapWithOutOnConflict1 = map from var customer in list1
        select [customer.id.toString(), customer];
    assertEqual(mapWithOnConflict1, {"1": {id: 1, name: "Melina", noOfItems: 12}, "2": {id: 2, name: "James", noOfItems: 5}, "3": {id: 3, name: "Anne", noOfItems: 20}});
    assertEqual(mapWithOnConflict1, mapWithOutOnConflict1);

    string[*] t1 = ["a", "ABC"];
    [string:Char, int] t2 = ["b", 123];
    string:Char[2] t3 = ["c", "a"];
    ()|error conflictMsg2 = error("Error 1");

    [string, string|int][] list2 = [t1, t2, t3, t1, t2, t3];

    map<string|int>|error map2 = map from var item in list2
        select [item[0], item[1]]
        on conflict conflictMsg2;
    assertEqual(map2, error("Error 1"));

    [string:Char, byte|int:Signed8] t4 = ["a", 123];
    [string:Char, int:Signed16] t5 = ["b", 123];
    [string, int] t6 = ["c", -123];
    [string, int:Unsigned32] t7 = ["zero", 0];
    CustomErrorX? onConflictError4 = error("error msg 1", message = "Error 2", code = 500);
    [string, int][] list3 = [t4, t5, t4, t6, t6, t7, t7, t4];

    map<string|int>|error map3 = map from var item in list3
        select [item[0], item[1]]
        on conflict onConflictError4;
    assertEqual(map3, onConflictError4);

    [string, int][] list4 = [t4, t5, t6, t7];

    map<string|int>|error map4 = map from var item in list4
        select [item[0], item[1]]
        on conflict onConflictError4;
    assertEqual(map4, {"a": 123, "b": 123, "c": -123, "zero": 0});
}

function testMapConstructingQueryExprWithOtherClauses() {
    error onConflictError = error("Key Conflict", message = "cannot insert.");

    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};

    PersonX p1 = {firstName: "Amy", lastName: "Melina", age: 23};
    PersonX p2 = {firstName: "Frank", lastName: "James", age: 30};

    CustomerX[] customerList1 = [c1, c2, c2];
    PersonX[] personList = [p1, p2];

    var selectedCustomers1 = map from var customer in customerList1
        from var person in personList
        let string fullName = person.firstName + " " + person.lastName
        where customer.name == person.lastName
        where customer.noOfItems >= 5
        where person.age <= 25
        select [
            fullName,
            {
                id: customer.id,
                name: fullName
            }
        ]
        on conflict onConflictError;
    assertEqual(selectedCustomers1, {"Amy Melina": {"id": 1, "name": "Amy Melina"}});

    CustomerX c3 = {id: 1, name: "Melina", noOfItems: 22};
    CustomerX c4 = {id: 2, name: "James", noOfItems: 15};
    CustomerX c5 = {id: 1, name: "Melina", noOfItems: 10};
    CustomerX c6 = {id: 2, name: "James", noOfItems: 11};

    CustomerX[] customerList2 = [c1, c2, c3, c4, c5, c6];

    map<CustomerX>|error selectedCustomers2 = map from var customer in customerList2
        from var person in personList
        let string fullName = person.firstName + " " + person.lastName
        where customer.name == person.lastName
        where customer.noOfItems >= 10
        where person.age <= 25
        select [
            fullName,
            {
                id: customer.id,
                name: fullName,
                noOfItems: customer.noOfItems
            }
        ]
        on conflict onConflictError;
    assertEqual(selectedCustomers2, onConflictError);

    var selectedCustomers3 = map from var customer in customerList2
        from var person in personList
        let string fullName = person.firstName + " " + person.lastName
        where customer.name == person.lastName
        where customer.noOfItems >= 10
        where person.age <= 25
        select [
            fullName,
            {
                id: customer.id,
                name: fullName
            }
        ]
        on conflict null;
    assertEqual(selectedCustomers3, {"Amy Melina": {"id": 1, "name": "Amy Melina"}});
}

function testMapConstructingQueryExprWithJoinClause() {
    error onConflictError = error("Key Conflict", message = "cannot insert.");

    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};

    PersonX p1 = {firstName: "Amy", lastName: "Melina", age: 23};
    PersonX p2 = {firstName: "Frank", lastName: "James", age: 30};

    CustomerX[] customerList1 = [c1, c2, c1];
    PersonX[] personList = [p1, p2];

    var customerMap1 = map from var customer in customerList1
        join var person in personList
        on customer.name equals person.lastName
        select [
            customer.id.toString(),
            {
                id: customer.id,
                name: person.firstName,
                age: person.age,
                noOfItems: customer.noOfItems
            }
        ]
        on conflict onConflictError;
    assertEqual(customerMap1, onConflictError);

    CustomerX[] customerList2 = [c1, c2];

    var customerMap2 = map from var customer in customerList2
        join var person in personList
        on customer.name equals person.lastName
        select [
            customer.id.toString(),
            {
                id: customer.id,
                name: person.firstName,
                age: person.age,
                noOfItems: customer.noOfItems
            }
        ]
        on conflict onConflictError;
    assertEqual(customerMap2, {"1": {"id": 1, "name": "Amy", "age": 23, "noOfItems": 12}, "2": {"id": 2, "name": "Frank", "age": 30, "noOfItems": 5}});
}

function testMapConstructingQueryExprWithLimitClause() {
    error onConflictError = error("Key Conflict", message = "cannot insert.");

    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Melina", noOfItems: 25};

    CustomerX[] customerList = [c1, c2, c3];

    map<CustomerX>|error customerMap1 = map from var customer in customerList.toStream()
        where customer.name == "Melina"
        limit 1
        select [
            customer.name,
            {
                id: customer.id,
                name: customer.name,
                noOfItems: customer.noOfItems
            }
        ]
        on conflict onConflictError;
    assertEqual(customerMap1, {"Melina": {"id": 1, "name": "Melina", "noOfItems": 12}});
}

function testMapConstructingQueryExprWithOrderByClause() {
    map<int> sorted1 = map from var e in [1, 2, 10, 3, 5, 20]
        order by e ascending
        select [e.toString(), e];
    assertEqual(sorted1, {"1": 1, "2": 2, "3": 3, "5": 5, "10": 10, "20": 20});

    map<int> sorted2 = map from var e in [1, 2, 10, 3, 5, 20]
        order by e descending
        select [e.toString(), e];
    assertEqual(sorted2, {"20": 20, "10": 10, "5": 5, "3": 3, "2": 2, "1": 1});

    var sorted3 = map from var e in ["1", "2", "10", "3", "5", "20"]
        order by e ascending
        select [e, e]
        on conflict ();
    assertEqual(sorted3, {"1": "1", "10": "10", "2": "2", "20": "20", "3": "3", "5": "5"});

    var sorted4 = map from var e in [1, 2, 5, 4]
        let int f = e / 2
        order by f ascending
        select [f.toString(), e]
        on conflict error("Error");
    assertEqual(sorted4, error("Error"));
}

type Error error;

type Json json;

type IntOrString int|string;

type ZeroOrOne 1|0;

type MapOfJsonOrError map<Json>|Error;

type MapOfIntOrError map<int>|Error;

type ErrorOrMapOfZeroOrOne Error|map<ZeroOrOne>;

function testMapConstructingQueryExprWithReferenceTypes() {
    map<ZeroOrOne> sorted1 = map from var e in [1, 0, 1, 0, 1, 1]
        order by e ascending
        select [e.toString(), <ZeroOrOne>e];
    assertEqual(sorted1, {"0": 0, "1": 1});

    ErrorOrMapOfZeroOrOne sorted2 = map from var e in [1, 0, 1, 0, 0, 0]
        order by e ascending
        select [e.toString(), <ZeroOrOne>e];
    assertEqual(sorted2, {"0": 0, "1": 1});

    map<Json> sorted3 = map from var e in ["1", "2", "10", "3", "5", "20"]
        order by e ascending
        select [e, e]
        on conflict ();
    assertEqual(sorted3, {"1": "1", "10": "10", "2": "2", "20": "20", "3": "3", "5": "5"});

    MapOfJsonOrError sorted4 = map from var e in ["1", "2", "10", "3", "5", "20"]
        order by e ascending
        select [e, e]
        on conflict error("Error");
    assertEqual(sorted4, {"1": "1", "10": "10", "2": "2", "20": "20", "3": "3", "5": "5"});

    MapOfIntOrError sorted5 = map from var e in [1, 2, 5, 4]
        let int f = e / 2
        order by f ascending
        select [f.toString(), e]
        on conflict error("Error");
    assertEqual(sorted5, error("Error"));
}

function testReadonlyTable() {
    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};

    CustomerX[] customerList1 = [c1, c2, c3];

    CustomerKeyLessTableX & readonly customerTable1 = table key(id, name) from var customer in customerList1
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        };
    any _ = <readonly>customerTable1;
    assertEqual((typeof (customerTable1)).toString(), "typedesc [{\"id\":1,\"name\":\"Melina\",\"noOfItems\":12},{\"id\":2,\"name\":\"James\",\"noOfItems\":5},{\"id\":3,\"name\":\"Anne\",\"noOfItems\":20}]");
    assertEqual(customerTable1.toString(), [{"id": 1, "name": "Melina", "noOfItems": 12}, {"id": 2, "name": "James", "noOfItems": 5}, {"id": 3, "name": "Anne", "noOfItems": 20}].toString());

    CustomerX[] & readonly customerList2 = [c1, c2, c3].cloneReadOnly();

    CustomerKeyLessTableX & readonly|error customerTable2 = table key(id, name) from var customer in customerList2
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict error("Error");
    any _ = <readonly>(checkpanic customerTable2);
    assertEqual((typeof (checkpanic customerTable2)).toString(), "typedesc [{\"id\":1,\"name\":\"Melina\",\"noOfItems\":12},{\"id\":2,\"name\":\"James\",\"noOfItems\":5},{\"id\":3,\"name\":\"Anne\",\"noOfItems\":20}]");
    assertEqual((checkpanic customerTable2).toString(), [{"id": 1, "name": "Melina", "noOfItems": 12}, {"id": 2, "name": "James", "noOfItems": 5}, {"id": 3, "name": "Anne", "noOfItems": 20}].toString());

    CustomerKeyLessTableX customerTable3 = table key(id, name) from var customer in customerList2
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict ();
    assertEqual((typeof (customerTable3)).toString(), "typedesc table<CustomerX> key(id, name)");
    assertEqual(customerTable3.toString(), [{"id": 1, "name": "Melina", "noOfItems": 12}, {"id": 2, "name": "James", "noOfItems": 5}, {"id": 3, "name": "Anne", "noOfItems": 20}].toString());
}

function testReadonlyTable2() {
    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};

    CustomerX[] customerList1 = [c1, c2, c3];

    CustomerTableX & readonly customerTable1 = table key(id, name) from var customer in customerList1
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        };
    any _ = <readonly>customerTable1;
    assertEqual((typeof customerTable1).toString(), "typedesc [{\"id\":1,\"name\":\"Melina\",\"noOfItems\":12},{\"id\":2,\"name\":\"James\",\"noOfItems\":5},{\"id\":3,\"name\":\"Anne\",\"noOfItems\":20}]");
    assertEqual(customerTable1.toString(), [{"id": 1, "name": "Melina", "noOfItems": 12}, {"id": 2, "name": "James", "noOfItems": 5}, {"id": 3, "name": "Anne", "noOfItems": 20}].toString());

    CustomerX[] customerList2 = [c1, c2, c3];

    CustomerTableX & readonly|error customerTable2 = table key(id, name) from var customer in customerList2
        select customer.cloneReadOnly()
        on conflict error("Error");
    any _ = <readonly>(checkpanic customerTable2);
    assertEqual((typeof (checkpanic customerTable2)).toString(), "typedesc [{\"id\":1,\"name\":\"Melina\",\"noOfItems\":12},{\"id\":2,\"name\":\"James\",\"noOfItems\":5},{\"id\":3,\"name\":\"Anne\",\"noOfItems\":20}]");
    assertEqual((checkpanic customerTable2).toString(), [{"id": 1, "name": "Melina", "noOfItems": 12}, {"id": 2, "name": "James", "noOfItems": 5}, {"id": 3, "name": "Anne", "noOfItems": 20}].toString());

    CustomerTableX customerTable3 = table key(id, name) from var customer in customerList2
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict ();
    assertEqual((typeof (customerTable3)).toString(), "typedesc table<CustomerX> key(id, name)");
    assertEqual(customerTable3.toString(), [{"id": 1, "name": "Melina", "noOfItems": 12}, {"id": 2, "name": "James", "noOfItems": 5}, {"id": 3, "name": "Anne", "noOfItems": 20}].toString());
}

type IdRec record {|
    readonly int id;
|};

function testReadonlyTable3() {
    table<IdRec> key(id) & readonly|error tbl = table key(id) from var i in [1, 2, 3, 4, 2, 3]
        select {
            id: i
        }
        on conflict ();

    assertEqual((typeof (tbl)).toString(), "typedesc [{\"id\":1},{\"id\":2},{\"id\":3},{\"id\":4}]");
    assertEqual(tbl, table key(id) [
                {"id": 1},
                {"id": 2},
                {"id": 3},
                {"id": 4}
            ]);

    if tbl !is error {
        IdRec? member1 = tbl[1];
        assertEqual(member1, {"id": 1});
    }

    table<IdRec> & readonly tbl2 = table key() from var i in [1, 2, 3, 4, 2, 3]
        select {
            id: i
        };

    assertEqual((typeof (tbl2)).toString(), "typedesc [{\"id\":1},{\"id\":2},{\"id\":3},{\"id\":4},{\"id\":2},{\"id\":3}]");
    assertEqual(tbl2, table key() [
                {"id": 1},
                {"id": 2},
                {"id": 3},
                {"id": 4},
                {"id": 2},
                {"id": 3}
            ]);
}

function testConstructingListOfTablesUsingQueryWithReadonly() {
    table<UserX> key(id) & readonly users1 = table [
        {id: 1, firstName: "John", lastName: "Doe", age: 25}
    ];

    (table<UserX> key(id))[] uList = [users1];

    (table<UserX & readonly> key(id))[] & readonly result = from var user in uList
        select user.cloneReadOnly();
    assertEqual((typeof (result)).toString(), "typedesc [[{\"id\":1,\"firstName\":\"John\",\"lastName\":\"Doe\",\"age\":25}]]");
    assertEqual(result, [table key(id) [{"id": 1, "firstName": "John", "lastName": "Doe", "age": 25}]]);
}

function testConstructingListOfRecordsUsingQueryWithReadonly() {
    EmployeeX emp1 = {firstName: "A1", lastName: "B1", dept: "C1"};
    EmployeeX emp2 = {firstName: "A2", lastName: "B2", dept: "C2"};
    EmployeeX emp3 = {firstName: "A3", lastName: "B3", dept: "C3"};

    (EmployeeX & readonly)[] & readonly result = from var user in [emp1, emp2, emp3]
        select user.cloneReadOnly();
    assertEqual((typeof (result)).toString(), "typedesc [{\"firstName\":\"A1\",\"lastName\":\"B1\",\"dept\":\"C1\"},{\"firstName\":\"A2\",\"lastName\":\"B2\",\"dept\":\"C2\"},{\"firstName\":\"A3\",\"lastName\":\"B3\",\"dept\":\"C3\"}]");
    assertEqual(result, [{"firstName": "A1", "lastName": "B1", "dept": "C1"}, {"firstName": "A2", "lastName": "B2", "dept": "C2"}, {"firstName": "A3", "lastName": "B3", "dept": "C3"}]);
}

function testConstructingListOfXMLsUsingQueryWithReadonly() {
    xml a = xml `<id> 1 </id> <name> John </name>`;

    (xml & readonly)[] & readonly result = from var user in a
        select user.cloneReadOnly();
    assertEqual((typeof (result)).toString(), "typedesc [`<id> 1 </id>`,` `,`<name> John </name>`]");
    assertEqual(result, [xml `<id> 1 </id>`, xml ` `, xml `<name> John </name>`]);
}

type Type1 int[]|string;

function testConstructingListOfListsUsingQueryWithReadonly() {
    Type1[] & readonly result = from var user in [[1, 2], "a", "b", [-1, int:MAX_VALUE]]
        select user.cloneReadOnly();
    assertEqual((typeof (result)).toString(), "typedesc [[1,2],\"a\",\"b\",[-1,9223372036854775807]]");
    assertEqual(result, [[1, 2], "a", "b", [-1, 9223372036854775807]]);
}

function testConstructingListOfMapsUsingQueryWithReadonly() {
    map<Type1>[] & readonly result = from var item in [[1, 2], "a", "b", [-1, int:MAX_VALUE]]
        select {item: item}.cloneReadOnly();

    assertEqual((typeof (result)).toString(), "typedesc [{\"item\":[1,2]},{\"item\":\"a\"},{\"item\":\"b\"},{\"item\":[-1,9223372036854775807]}]");
    assertEqual(result, [{"item": [1, 2]}, {"item": "a"}, {"item": "b"}, {"item": [-1, 9223372036854775807]}]);
}

type T record {
    string[] params;
};

function testConstructingListInRecordsUsingQueryWithReadonly() {
    T rec1 = {params: from var s in ["a", "b", "c", "abc"]
            select s};
    assertEqual(rec1, {"params": ["a", "b", "c", "abc"]});
}

type DepartmentDetails record {
    string dept;
};

type ImmutableMapOfDept map<DepartmentDetails> & readonly;

type ImmutableMapOfInt map<int> & readonly;

type ErrorOrImmutableMapOfInt ImmutableMapOfInt|error;

function testReadonlyMap1() {
    map<int> & readonly mp1 = map from var item in [["1", 1], ["2", 2], ["3", 3], ["4", 4]]
        select item;
    any _ = <readonly>mp1;
    assertEqual((typeof (mp1)).toString(), "typedesc {\"1\":1,\"2\":2,\"3\":3,\"4\":4}");
    assertEqual(mp1, {"1": 1, "2": 2, "3": 3, "4": 4});

    ImmutableMapOfInt mp2 = map from var item in [["1", 1], ["2", 2], ["3", 3], ["4", 4]]
        select item;
    any _ = <readonly>mp2;
    assertEqual((typeof (mp2)).toString(), "typedesc {\"1\":1,\"2\":2,\"3\":3,\"4\":4}");
    assertEqual(mp2, {"1": 1, "2": 2, "3": 3, "4": 4});

    ImmutableMapOfDept mp3 = map from var item in ["ABC", "DEF", "XY"]
        let DepartmentDetails & readonly dept = {dept: item}
        select [item, dept];
    any _ = <readonly>mp3;
    assertEqual((typeof (mp3)).toString(), "typedesc {\"ABC\":{\"dept\":\"ABC\"},\"DEF\":{\"dept\":\"DEF\"},\"XY\":{\"dept\":\"XY\"}}");
    assertEqual(mp3, {"ABC": {"dept": "ABC"}, "DEF": {"dept": "DEF"}, "XY": {"dept": "XY"}});

    ErrorOrImmutableMapOfInt mp4 = map from var item in [["1", 1], ["2", 2], ["3", 3], ["4", 4]]
        where item[1] > 1
        select item;
    any _ = <readonly>(checkpanic mp4);
    assertEqual((typeof (mp4)).toString(), "typedesc {\"2\":2,\"3\":3,\"4\":4}");
    assertEqual(mp4, {"2": 2, "3": 3, "4": 4});

    [string:Char, int[]][] & readonly list = [["a", [1, 2]], ["b", [3, 4]], ["c", [4]], ["c", [3]]];
    map<int[]>|error mp5 = map from var item in list
        select item;
    assertEqual(mp5, {"a": [1, 2], "b": [3, 4], "c": [3]});

    map<int[]> & readonly|error mp6 = map from var item in list
        select item;
    assertEqual(mp6, {"a": [1, 2], "b": [3, 4], "c": [3]});
    any _ = <readonly>(checkpanic mp6);

    map<int[]> & readonly|error mp7 = map from var item in list
        select item
        on conflict error("Error");
    assertEqual(mp7, error("Error"));
}

function testReadonlyMap2() {
    map<int> & readonly mp1 = map from var item in [["1", 1], ["2", 2], ["2", 3], ["4", 4]]
        select [item[0], item[1] * 2]
        on conflict ();
    assertEqual(mp1, {"1": 2, "2": 6, "4": 8});

    ImmutableMapOfInt|error mp2 = map from var item in [["1", 1], ["2", 2], ["2", 3], ["4", 4]]
        select item
        on conflict error("Error 1");
    assertEqual(mp2, error("Error 1"));

    error? conflictMsg = error("Error 2");
    ImmutableMapOfDept|error mp3 = map from var item in ["ABC", "DEF", "XY", "ABC"]
        let DepartmentDetails & readonly dept = {dept: item}
        select [item, dept]
        on conflict conflictMsg;
    assertEqual(mp3, error("Error 2"));

    conflictMsg = null;
    ErrorOrImmutableMapOfInt mp4 = map from var item in [["1", 1], ["2", 2], ["3", 3], ["1", 4]]
        where item[1] > 1
        select item
        on conflict conflictMsg;
    assertEqual(mp4, {"2": 2, "3": 3, "1": 4});
}

class EvenNumberGenerator {
    int i = 0;

    public isolated function next() returns record {|int value;|}|error {
        return error("Greater than 20!");
    }
}

type ResultValue record {|
    int value;
|};

type NumberRecord record {|
    readonly int id;
    string value;
|};

function testQueryConstructingMapsAndTablesWithClausesMayCompleteSEarlyWithError() {
    EvenNumberGenerator evenGen = new ();
    stream<int, error> evenNumberStream = new (evenGen);

    map<int>|error map1 = map from var item in evenNumberStream
        select [item.toBalString(), item];
    assertEqual(map1, error("Greater than 20!"));

    table<ResultValue>|error table1 = table key() from var item in evenNumberStream
        select {value: item};
    assertEqual(table1, error("Greater than 20!"));

    table<NumberRecord> key(id)|error table2 = table key(id) from var item in evenNumberStream
        select {id: item, value: item.toBalString()};
    assertEqual(table2, error("Greater than 20!"));

    // Enable following tests after fixing issue - lang/#36746
    // map<int>|error map2 = map from var firstNo in [1, 4, 9, 10]
    //                         join var secondNo in evenNumberStream
    //                         on firstNo equals secondNo
    //                         select [secondNo.toBalString(), secondNo];
    // assertEqual(map2, error("Greater than 20!"));

    // table<NumberRecord> key()|error table3 = table key() from var firstNo in [1, 4, 9, 10]
    //                         join var secondNo in evenNumberStream
    //                         on firstNo equals secondNo
    //                         select {id: secondNo, value: secondNo.toBalString()};
    // assertEqual(table3, error("Greater than 20!"));

    // table<NumberRecord> key(id)|error table4 = table key(id) from var firstNo in [1, 4, 9, 10]
    //                         join var secondNo in evenNumberStream
    //                         on firstNo equals secondNo
    //                         select {id: secondNo, value: secondNo.toBalString()};
    // assertEqual(table4, error("Greater than 20!"));

    map<int>|error map3 = map from var firstNo in [1, 4, 4, 10]
        select [firstNo.toBalString(), firstNo]
        on conflict error("Error");
    assertEqual(map3, error("Error"));

    table<NumberRecord> key(id)|error table6 = table key(id) from var firstNo in [1, 4, 4, 10]
        select {id: firstNo, value: firstNo.toBalString()}
        on conflict error("Error");
    assertEqual(table6, error("Error"));
}

function testQueryConstructingMapWithOnConflictsWithVarRef() {
    map<string>|error mp1 = map from int i in [1, 2, 3, 1, 2, 3]
        let string value = "A" + i.toString()
        select [i.toString(), value]
        on conflict error(string `Duplicate Key: ${i} Value: ${value}`);

    assertEqual(mp1 is error, true);
    assertEqual((<error>mp1).message(), "Duplicate Key: 1 Value: A1");

    int duplicateKey = 1;
    map<string>|error mp2 = map from int i in [1, 2, 3, 1, 2, 3]
        let string value = "A" + i.toString()
        select [i.toString(), value]
        on conflict error(string `Duplicate Key: ${duplicateKey} Value: ${value}`);
    assertEqual(mp2 is error, true);
    assertEqual((<error>mp2).message(), "Duplicate Key: 1 Value: A1");
}

function testQueryConstructingMapsAndTablesWithClausesMayCompleteSEarlyWithError2() {
    EvenNumberGenerator evenGen = new ();
    stream<int, error> evenNumberStream = new (evenGen);

    map<int>|error map1 = map from var item in (stream from var integer in evenNumberStream
            select integer)
        select [item.toBalString(), item];
    assertEqual(map1, error("Greater than 20!"));

    table<ResultValue>|error table1 = table key() from var item in (stream from var integer in evenNumberStream
            select integer)
        select {value: item};
    assertEqual(table1, error("Greater than 20!"));

    table<NumberRecord> key(id)|error table2 = table key(id) from var item in (stream from var integer in evenNumberStream
            select integer)
        select {id: item, value: item.toBalString()};
    assertEqual(table2, error("Greater than 20!"));

    map<int>|error map3 = map from var item in (stream from var integer in (stream from var integer in evenNumberStream
                select integer)
            select integer)
        select [item.toBalString(), item];
    assertEqual(map3, error("Greater than 20!"));

    table<ResultValue>|error table4 = table key() from var item in
                                        (stream from var integer in (stream from var integer in evenNumberStream
                select integer)
            select integer)
        select {value: item};
    assertEqual(table4, error("Greater than 20!"));
}

type FooBar1 ("foo"|"bar"|string)[2];

type FooBar2 ("foo"|"bar")[2];

type FooBar3 "foo"|"bar";

type FooBar4 "foo"|"bar"|string:Char;

type FooBar5 "foo"|"bar"|string;

function testMapConstructingQueryExprWithStringSubtypes() {
    FooBar1[] list1 = [["key1", "foo"], ["key2", "foo"], ["key3", "foo"]];
    map<string>|error mp1 = map from var item in list1
        select item;
    assertEqual(mp1, {"key1": "foo", "key2": "foo", "key3": "foo"});

    FooBar2[] list2 = [["foo", "foo"], ["bar", "foo"], ["foo", "foo"]];
    map<string>|error mp2 = map from var item in list2
        select item;
    assertEqual(mp2, {"foo": "foo", "bar": "foo"});

    FooBar3[][2] list3 = [["foo", "bar"], ["bar", "foo"], ["foo", "bar"]];
    map<string>|error mp3 = map from var item in list3
        select item;
    assertEqual(mp3, {"foo": "bar", "bar": "foo"});

    FooBar4[][2] list4 = [["foo", "4"], ["bar", "2"], ["foo", "3"]];
    map<string>|error mp4 = map from var item in list4
        select item;
    assertEqual(mp4, {"foo": "3", "bar": "2"});
    map<string>|error mp5 = map from var item in list4
        select item
        on conflict error("Error");
    assertEqual(mp5, error("Error"));

    FooBar5[][2] list5 = [["key1", "1.4"], ["key2", "2"], ["key3", "3"]];
    map<string>|error mp6 = map from var item in list5
        select item;
    assertEqual(mp6, {"key1": "1.4", "key2": "2", "key3": "3"});

    [FooBar3, int|float][] list6 = [["foo", 1.4], ["bar", 2], ["foo", 3]];
    map<int|float>|error mp7 = map from var item in list6
        select item;
    assertEqual(mp7, {"foo": 3, "bar": 2});
    map<int|float>|error mp8 = map from var item in list6
        select item
        on conflict error("Error");
    assertEqual(mp8, error("Error"));

    [FooBar4, int|float][] list7 = [["foo", 1.4], ["bar", 2], ["foo", 3]];
    map<int|float>|error mp9 = map from var item in list7
        select item;
    assertEqual(mp9, {"foo": 3, "bar": 2});
    map<int|float>|error mp10 = map from var item in list7
        select item
        on conflict error("Error");
    assertEqual(mp10, error("Error"));

    [FooBar5, int|float][] list8 = [["key1", 1.4], ["key2", 2], ["key3", 3]];
    map<int|float>|error mp11 = map from var item in list8
        select item;
    assertEqual(mp11, {"key1": 1.4, "key2": 2, "key3": 3});
}

function testDiffQueryConstructsUsedAsFuncArgs() returns error? {
    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};

    CustomerX[] customerList = [c1, c2, c3];

    int tblLength = getTableLength(table key(id, name) from var customer in customerList
                select {
                    id: customer.id,
                    name: customer.name,
                    noOfItems: customer.noOfItems
                });
    assertEqual(tblLength, 3);

    FooBar1[] list1 = [["key1", "foo"], ["key2", "foo"], ["key3", "foo"]];
    int mapLength = getMapLength(map from var item in list1
                select item);
    assertEqual(mapLength, 3);
}

function getTableLength(CustomerTableX tbl) returns int {
    return tbl.length();
}

function getMapLength(map<string> strMap) returns int {
    return strMap.length();
}

type Row record {|
    readonly string:RegExp rec;
|};

function testQueryExprConstructingTableWithRegExp() {
    string:RegExp[] arr1 = [re `A`, re `B`, re `C`];
    table<Row> key(rec) res = table key(rec) from var reg in arr1
        where reg != re `B`
        select {
            rec: reg
        };
    table<Row> key(rec) tbl = table [
        {rec: re `A`},
        {rec: re `C`}
    ];
    assertEqual(tbl, res);

    table<Row> key(rec)|error res2 = table key(rec) from var reg in [re `A`, re `B`, re `A`]
        where reg != re `B`
        select {
            rec: reg
        }
        on conflict error("Duplicate Key");
    assertEqual(true, res2 is error);
    if (res2 is error) {
        assertEqual("Duplicate Key", (<error>res2).message());
    }
}

function testQueryExprConstructingMapWithRegExp() {
    string:RegExp[] arr1 = [re `A`, re `B`, re `C`];
    map<string:RegExp> res = map from var reg in arr1
        let string:RegExp v = re `1`
        where reg != re `B`
        select [reg.toString() + v.toString(), reg];
    assertEqual({A1: re `A`, C1: re `C`}, res);

    map<string:RegExp>|error res2 = map from var reg in [re `A`, re `B`, re `C`, re `A`]
        let string:RegExp v = re `1`
        where reg != re `B`
        select [reg.toString() + v.toString(), reg]
        on conflict error("Duplicate Key");

    assertEqual(true, res2 is error);
    if (res2 is error) {
        assertEqual("Duplicate Key", (<error>res2).message());
    }
}

function testQueryExprConstructingStreamWithRegExpWithInterpolations() {
    string:RegExp[] arr1 = [re `A`, re `B2`, re `C`];
    int v = 1;
    stream<string:RegExp> arr2 = stream from var reg in arr1
        where reg != re `B${v + 1}`
        select reg;
    var t = arr2.iterator();
    assertEqual({value: re `A`}, t.next());
    assertEqual({value: re `C`}, t.next());
    assertEqual((), t.next());
}

function testNestedQueryExprConstructingTableWithRegExp() {
    string:RegExp[] arr1 = [re `A`, re `B2`, re `C`];
    int v = 1;
    table<Row> res = table key() from var re in (from string:RegExp reg in arr1
            where reg != re `B${v + 1}`
            select reg)
        let string:RegExp a = re `A`
        where re != re `A`
        select {
            rec: re `${re.toString() + a.toString()}`
        };
    table<Row> key() tbl = table [{rec: re `CA`}];
    assertEqual(tbl, res);
}

function testJoinedQueryExprConstructingMapWithRegExp() {
    string:RegExp[] arr1 = [re `A`, re `B`, re `C`, re `D`];
    string:RegExp[] arr2 = [re `A`, re `B`];
    int v = 1;
    map<string> arr3 = map from var re1 in arr1
        join string:RegExp re2 in arr2
        on re1 equals re2
        let string:RegExp a = re `AB*(A|B|[ab-fgh]+(?im-x:[cdeg-k]??${v})|)|^|PQ?`
        select [re1.toString() + "1", re1.toString() + a.toString()];
    assertEqual({
                    A1: "AAB*(A|B|[ab-fgh]+(?im-x:[cdeg-k]??1)|)|^|PQ?",
                    B1: "BAB*(A|B|[ab-fgh]+(?im-x:[cdeg-k]??1)|)|^|PQ?"
                }, arr3);
}

type ModuleDecls [string, FuncDecl...];

type FuncDecl [string, Signature];

public type Signature [string, string[], string];

type ModuleDeclsMemo record {|
    readonly string id;
    map<Signature> funcs = {};
|};

function testInnerQueryConstructedWithCEP() {
    map<ModuleDeclsMemo> funcMap = {
        "1": {id: "01", funcs: {"func1": ["foo", ["int", "string"], "boolean"]}},
        "2": {id: "02", funcs: {"func2": ["bar", ["int", "int"], "boolean"]}}
    };
    ModuleDecls[] decl = from var {id, funcs} in funcMap
        select [
            id,
            ...from var [name, sig] in funcs.entries()
                where name.equalsIgnoreCaseAscii("func1")
                select <FuncDecl>[name, sig]
        ];

    assertEqual([["01", ["func1", ["foo", ["int", "string"], "boolean"]]], ["02"]], decl);
}

error onConflictError = error("Key Conflict", message = "cannot insert.");

function testTableConstructQueryWithNonConflictingKeys() {
    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};
    CustomerX[] customerList = [c1, c2, c3];
    CustomerTableX|error customerTable = getQueryResult(onConflictError, customerList);
    assertEqual(true, customerTable is CustomerTableX);
    CustomerTableX expectedTableValue = table [
        {id: 1, name: "Melina", noOfItems: 12},
        {id: 2, name: "James", noOfItems: 5},
        {id: 3, name: "Anne", noOfItems: 20}
    ];
    assertEqual(customerTable, expectedTableValue);
}

function testTableConstructQueryWithConflictingKeys() {
    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};
    CustomerX[] customerList = [c1, c2, c3, c1];
    CustomerTableX|error customerTable = getQueryResult(onConflictError, customerList);
    assertEqual(customerTable is error, true);
    assertEqual((<error>customerTable).message(), "Key Conflict");
}

function getQueryResult(error onConflictError, CustomerX[] customerList) returns CustomerTableX|error {
    return <CustomerTableX|error>table key(id, name) from var customer in customerList
        select {
            id: customer.id,
            name: customer.name,
            noOfItems: customer.noOfItems
        }
        on conflict onConflictError;
}

function testMapConstructNestedQueryWithConflictingKeys() {
    CustomerX c1 = {id: 1, name: "Melina", noOfItems: 12};
    CustomerX c2 = {id: 2, name: "James", noOfItems: 5};
    CustomerX c3 = {id: 3, name: "Anne", noOfItems: 20};
    CustomerX[] customerList = [c1, c2, c3, c1];
    (anydata|error)[] result = from var i in [1]
        select table key(id, name) from var customer in customerList
            select {
                id: customer.id,
                name: customer.name,
                noOfItems: customer.noOfItems
            }
            on conflict error(string `Error key: ${customer.id} iteration: ${i}`);
    assertEqual(result[0] is error, true);
    assertEqual((<error>result[0]).message(), "Error key: 1 iteration: 1");
}

function testMapConstructQueryWithConflictingKeys() {
    CustomerX c1 = {id: 1, name: "Abba", noOfItems: 10};
    CustomerX c2 = {id: 2, name: "Jim", noOfItems: 20};
    CustomerX c3 = {id: 3, name: "James", noOfItems: 30};
    CustomerX c4 = {id: 3, name: "Abba", noOfItems: 40};
    CustomerX[] customerList = [c1, c2, c3, c4];
    anydata|error result = map from var {name, noOfItems} in customerList
                            group by name
                            select [name, [noOfItems]]
                            on conflict error(string `value: ${[noOfItems].toString()}`);
    assertEqual(result is map<anydata>, true);
}

function assertEqual(anydata|error actual, anydata|error expected) {
    anydata expectedValue = (expected is error)? (<error> expected).message() : expected;
    anydata actualValue = (actual is error)? (<error> actual).message() : actual;
    if expectedValue == actualValue {
        return;
    }
    panic error(string `expected '${expectedValue.toBalString()}', found '${actualValue.toBalString()}'`);
}

function assertTrue(anydata|error actual) {
    assertEqual(true, actual);
}
