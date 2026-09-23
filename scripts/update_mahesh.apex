// Script to populate all fields on Mahesh's record
Student__c mahesh = [
    SELECT Id, Name, Student_Name__c, Student_ID__c, Program__c, Semester__c,
           Faculty_Advisor__c, Cumulative_GPA__c, Attendance__c, Fee_Status__c,
           Admission_Date__c, Enrolment_Status__c
    FROM Student__c
    WHERE Student_Name__c = 'Mahesh'
    LIMIT 1
];

User advisor = [SELECT Id, Name FROM User WHERE IsActive = true AND UserType = 'Standard' ORDER BY CreatedDate ASC LIMIT 1];

mahesh.Semester__c = 'Semester 1';
mahesh.Faculty_Advisor__c = advisor.Id;
mahesh.Cumulative_GPA__c = 3.75;
mahesh.Attendance__c = 86.50;
mahesh.Fee_Status__c = 'Paid';
mahesh.Admission_Date__c = Date.newInstance(2024, 8, 15);
mahesh.Enrolment_Status__c = 'Active';
update mahesh;

// Also add a registered enrolment if not present
List<Enrolment__c> regEnr = [
    SELECT Id, Enrolment_Status__c
    FROM Enrolment__c
    WHERE Student__c = :mahesh.Id AND Enrolment_Status__c = 'Registered'
];

if (regEnr.isEmpty()) {
    Course_Offering__c off = [
        SELECT Id FROM Course_Offering__c
        WHERE Max_Capacity__c >= 50
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    insert new Enrolment__c(
        Student__c = mahesh.Id,
        Course_Offering__c = off.Id,
        Enrolment_Status__c = 'Registered',
        Attendance_Percentage__c = 86.50,
        Registration_Date__c = Date.today()
    );
}

Student__c verify = [
    SELECT Id, Name, Student_Name__c, Student_ID__c, Program__r.Name, Department__c,
           Semester__c, Faculty_Advisor__r.Name, Cumulative_GPA__c, Attendance__c,
           Fee_Status__c, Registered_Courses_Count__c, Enrolment_Status__c, Admission_Date__c
    FROM Student__c
    WHERE Id = :mahesh.Id
];

System.debug('=== MAHESH RECORD UPDATED ===');
System.debug('1. Student Name: ' + verify.Student_Name__c);
System.debug('2. Student ID: ' + verify.Student_ID__c);
System.debug('3. Program: ' + verify.Program__r.Name);
System.debug('4. Department: ' + verify.Department__c);
System.debug('5. Semester: ' + verify.Semester__c);
System.debug('6. Faculty Advisor: ' + verify.Faculty_Advisor__r.Name);
System.debug('7. Cumulative GPA: ' + verify.Cumulative_GPA__c);
System.debug('8. Attendance: ' + verify.Attendance__c + '%');
System.debug('9. Fee Status: ' + verify.Fee_Status__c);
System.debug('10. Registered Courses: ' + verify.Registered_Courses_Count__c);
System.debug('11. Enrolment Status: ' + verify.Enrolment_Status__c);
System.debug('12. Admission Date: ' + verify.Admission_Date__c);
