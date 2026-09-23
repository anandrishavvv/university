// Script to populate EVERY student record in the org with all 12 fields
List<Student__c> allStudents = [
    SELECT Id, Name, Student_Name__c, Student_ID__c, Program__c, Semester__c,
           Faculty_Advisor__c, Cumulative_GPA__c, Attendance__c, Fee_Status__c,
           Admission_Date__c, Enrolment_Status__c, Email__c, Phone__c
    FROM Student__c
];

User advisor = [SELECT Id, Name FROM User WHERE IsActive = true AND UserType = 'Standard' ORDER BY CreatedDate ASC LIMIT 1];
Program__c defaultProg = [SELECT Id, Name, Department__c FROM Program__c LIMIT 1];

// Picklists
List<String> semesters = new List<String>{'Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5', 'Semester 6'};
List<String> feeStatuses = new List<String>{'Paid', 'Paid', 'Pending', 'Paid'};

Integer i = 0;
for (Student__c s : allStudents) {
    if (s.Program__c == null) {
        s.Program__c = defaultProg.Id;
    }
    if (String.isBlank(s.Semester__c)) {
        s.Semester__c = semesters[Math.mod(i, semesters.size())];
    }
    if (s.Faculty_Advisor__c == null) {
        s.Faculty_Advisor__c = advisor.Id;
    }
    if (s.Cumulative_GPA__c == null || s.Cumulative_GPA__c == 0.0) {
        s.Cumulative_GPA__c = 3.50 + Math.mod(i * 7, 45) / 100.0; // 3.50 to 3.95
    }
    if (s.Attendance__c == null || s.Attendance__c == 0.0) {
        s.Attendance__c = 82.00 + Math.mod(i * 3, 16); // 82% to 97%
    }
    if (String.isBlank(s.Fee_Status__c)) {
        s.Fee_Status__c = 'Paid';
    }
    s.Academic_Standing__c = 'Good Standing';
    if (s.Admission_Date__c == null) {
        s.Admission_Date__c = Date.newInstance(2024, 8, 1).addMonths(-1 * Math.mod(i * 6, 24));
    }
    if (String.isBlank(s.Enrolment_Status__c) || s.Enrolment_Status__c == 'Offer Accepted') {
        s.Enrolment_Status__c = 'Active';
    }
    if (String.isBlank(s.Email__c)) {
        String cleanName = s.Student_Name__c != null ? s.Student_Name__c.toLowerCase().replace(' ', '.') : 'student' + i;
        s.Email__c = cleanName + '@university.edu';
    }
    i++;
}

update allStudents;
System.debug('UPDATED ALL ' + allStudents.size() + ' STUDENTS SUCCESSFULLY.');

// Ensure ample capacity offerings exist
String suffix = String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0, 4);
Course_Offering__c off1 = new Course_Offering__c(
    Program__c = defaultProg.Id,
    Course_Code__c = 'UNIV-' + suffix + 'A',
    Course_Name__c = 'Core Computing Concepts',
    Credits__c = 4,
    Term__c = 'Spring 2026',
    Max_Capacity__c = 500,
    Is_Open_For_Registration__c = true
);
Course_Offering__c off2 = new Course_Offering__c(
    Program__c = defaultProg.Id,
    Course_Code__c = 'UNIV-' + suffix + 'B',
    Course_Name__c = 'Data Structures and Algorithms',
    Credits__c = 4,
    Term__c = 'Spring 2026',
    Max_Capacity__c = 500,
    Is_Open_For_Registration__c = true
);
insert new List<Course_Offering__c>{ off1, off2 };

// Find students with 0 registered enrolments and add enrolments
Map<Id, Integer> studentRegisteredMap = new Map<Id, Integer>();
for (AggregateResult ar : [
    SELECT Student__c stuId, COUNT(Id) cnt
    FROM Enrolment__c
    WHERE Enrolment_Status__c = 'Registered'
    GROUP BY Student__c
]) {
    studentRegisteredMap.put((Id)ar.get('stuId'), (Integer)ar.get('cnt'));
}

List<Enrolment__c> newEnrolments = new List<Enrolment__c>();
for (Student__c s : allStudents) {
    Integer count = studentRegisteredMap.containsKey(s.Id) ? studentRegisteredMap.get(s.Id) : 0;
    if (count == 0) {
        newEnrolments.add(new Enrolment__c(
            Student__c = s.Id,
            Course_Offering__c = off1.Id,
            Enrolment_Status__c = 'Registered',
            Attendance_Percentage__c = s.Attendance__c,
            Registration_Date__c = Date.today()
        ));
        newEnrolments.add(new Enrolment__c(
            Student__c = s.Id,
            Course_Offering__c = off2.Id,
            Enrolment_Status__c = 'Registered',
            Attendance_Percentage__c = s.Attendance__c,
            Registration_Date__c = Date.today()
        ));
    }
}

if (!newEnrolments.isEmpty()) {
    Database.SaveResult[] results = Database.insert(newEnrolments, false);
    Integer successCount = 0;
    for (Database.SaveResult sr : results) {
        if (sr.isSuccess()) successCount++;
    }
    System.debug('INSERTED ' + successCount + ' ENROLMENTS.');
}

// Final verification of all students
List<Student__c> finalCheck = [
    SELECT Id, Student_Name__c, Student_ID__c, Semester__c, Faculty_Advisor__r.Name,
           Cumulative_GPA__c, Attendance__c, Fee_Status__c, Admission_Date__c,
           Registered_Courses_Count__c, Program__r.Name, Department__c
    FROM Student__c
    ORDER BY Student_ID__c ASC
];

System.debug('=== VERIFYING ALL STUDENTS IN ORG ===');
for (Student__c s : finalCheck) {
    System.debug('STUDENT [' + s.Student_ID__c + ']: ' + s.Student_Name__c + 
                 ' | GPA: ' + s.Cumulative_GPA__c + 
                 ' | Att: ' + s.Attendance__c + '%' + 
                 ' | Fee: ' + s.Fee_Status__c + 
                 ' | Sem: ' + s.Semester__c + 
                 ' | Adv: ' + s.Faculty_Advisor__r.Name + 
                 ' | AdmDate: ' + s.Admission_Date__c + 
                 ' | RegCourses: ' + s.Registered_Courses_Count__c);
}
