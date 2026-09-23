// Script to create a fully-populated Student__c record with all 12 fields and related Enrolments

// 1. Program
Program__c prog = [SELECT Id, Name, Department__c FROM Program__c LIMIT 1];

// 2. Faculty Advisor (Standard User)
User advisor = [SELECT Id, Name FROM User WHERE IsActive = true AND UserType = 'Standard' ORDER BY CreatedDate ASC LIMIT 1];

// 3. Create Student with all 12 fields populated
Student__c student = new Student__c(
    Student_Name__c = 'Aarav Sharma',
    Program__c = prog.Id,
    Semester__c = 'Semester 4',
    Faculty_Advisor__c = advisor.Id,
    Cumulative_GPA__c = 3.85,
    Attendance__c = 92.50,
    Fee_Status__c = 'Paid',
    Enrolment_Status__c = 'Active',
    Admission_Date__c = Date.newInstance(2023, 8, 1),
    Email__c = 'aarav.sharma@example.edu',
    Phone__c = '+91 98765 43210',
    Expected_Graduation_Date__c = Date.newInstance(2027, 5, 30),
    Academic_Standing__c = 'Good Standing'
);
insert student;
System.debug('CREATED_STUDENT_ID:' + student.Id);

// 4. Create fresh Course Offerings with ample capacity
String uniqueSuffix = String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0, 4);
Course_Offering__c off1 = new Course_Offering__c(
    Program__c = prog.Id,
    Course_Code__c = 'CS-' + uniqueSuffix + 'A',
    Course_Name__c = 'Advanced Cloud Computing',
    Credits__c = 4,
    Term__c = 'Spring 2026',
    Max_Capacity__c = 100,
    Is_Open_For_Registration__c = true
);
Course_Offering__c off2 = new Course_Offering__c(
    Program__c = prog.Id,
    Course_Code__c = 'CS-' + uniqueSuffix + 'B',
    Course_Name__c = 'Modern Artificial Intelligence',
    Credits__c = 3,
    Term__c = 'Spring 2026',
    Max_Capacity__c = 100,
    Is_Open_For_Registration__c = true
);
insert new List<Course_Offering__c>{ off1, off2 };
List<Course_Offering__c> offerings = new List<Course_Offering__c>{ off1, off2 };

// 5. Create Enrolments so Registered_Courses_Count__c roll-up calculates
List<Enrolment__c> enrolments = new List<Enrolment__c>();
for (Course_Offering__c off : offerings) {
    enrolments.add(new Enrolment__c(
        Student__c = student.Id,
        Course_Offering__c = off.Id,
        Enrolment_Status__c = 'Registered',
        Attendance_Percentage__c = 92.5,
        Registration_Date__c = Date.today()
    ));
}
if (!enrolments.isEmpty()) {
    insert enrolments;
}

// 6. Query and verify all 12 fields on the created student
Student__c verified = [
    SELECT Id, Name, Student_Name__c, Student_ID__c, Program__r.Name, Department__c,
           Semester__c, Faculty_Advisor__r.Name, Cumulative_GPA__c, Attendance__c,
           Fee_Status__c, Registered_Courses_Count__c, Enrolment_Status__c, Admission_Date__c
    FROM Student__c
    WHERE Id = :student.Id
];

System.debug('=== VERIFIED STUDENT RECORD ===');
System.debug('1. Student Name: ' + verified.Student_Name__c);
System.debug('2. Student ID: ' + verified.Student_ID__c);
System.debug('3. Program: ' + verified.Program__r.Name);
System.debug('4. Department: ' + verified.Department__c);
System.debug('5. Semester: ' + verified.Semester__c);
System.debug('6. Faculty Advisor: ' + verified.Faculty_Advisor__r.Name);
System.debug('7. Cumulative GPA: ' + verified.Cumulative_GPA__c);
System.debug('8. Attendance: ' + verified.Attendance__c + '%');
System.debug('9. Fee Status: ' + verified.Fee_Status__c);
System.debug('10. Registered Courses: ' + verified.Registered_Courses_Count__c);
System.debug('11. Enrolment Status: ' + verified.Enrolment_Status__c);
System.debug('12. Admission Date: ' + verified.Admission_Date__c);
