@isTest
private class StudentSummaryControllerTest {

    @testSetup
    static void setupTestData() {
        Program__c prog = new Program__c(
            Program_Name__c = 'Bachelor of Science in Computer Science',
            Program_Code__c = 'BS-CS',
            Department__c = 'Engineering',
            Duration_Years__c = 4,
            Tuition_Fee_Per_Semester__c = 5000,
            Is_Active__c = true
        );
        insert prog;

        // Populate base fields present in all orgs
        Student__c stu = new Student__c(
            Student_Name__c = 'Alex Morgan',
            Program__c = prog.Id,
            Cumulative_GPA__c = 3.85,
            Enrolment_Status__c = 'Active',
            Academic_Standing__c = 'Good Standing',
            Email__c = 'alex.morgan@university.edu',
            Phone__c = '+1-555-0199'
        );

        // Dynamically assign optional custom fields if present in this org
        Map<String, SObjectField> fieldMap = SObjectType.Student__c.fields.getMap();
        if (fieldMap.containsKey('admission_date__c')) {
            stu.put('Admission_Date__c', Date.newInstance(2024, 8, 15));
        }
        if (fieldMap.containsKey('semester__c')) {
            stu.put('Semester__c', 'Semester 4');
        }
        if (fieldMap.containsKey('fee_status__c')) {
            stu.put('Fee_Status__c', 'Pending');
        }
        if (fieldMap.containsKey('attendance__c')) {
            stu.put('Attendance__c', 87.50);
        }
        insert stu;

        Course_Offering__c course1 = new Course_Offering__c(
            Program__c = prog.Id,
            Course_Code__c = 'CS-201',
            Course_Name__c = 'Data Structures & Algorithms',
            Credits__c = 4,
            Term__c = 'Fall 2026',
            Max_Capacity__c = 50,
            Is_Open_For_Registration__c = true
        );
        Course_Offering__c course2 = new Course_Offering__c(
            Program__c = prog.Id,
            Course_Code__c = 'CS-202',
            Course_Name__c = 'Database Systems',
            Credits__c = 3,
            Term__c = 'Fall 2026',
            Max_Capacity__c = 50,
            Is_Open_For_Registration__c = true
        );
        insert new List<Course_Offering__c>{ course1, course2 };

        Enrolment__c enr1 = new Enrolment__c(
            Student__c = stu.Id,
            Course_Offering__c = course1.Id,
            Enrolment_Status__c = 'Registered',
            Attendance_Percentage__c = 92.5,
            Registration_Date__c = Date.today()
        );
        Enrolment__c enr2 = new Enrolment__c(
            Student__c = stu.Id,
            Course_Offering__c = course2.Id,
            Enrolment_Status__c = 'Registered',
            Attendance_Percentage__c = 88.0,
            Registration_Date__c = Date.today()
        );
        insert new List<Enrolment__c>{ enr1, enr2 };

        // Fee Invoices: Do not write to Net_Amount_Due__c directly as it is a formula field
        try {
            Fee_Invoice__c fee1 = new Fee_Invoice__c(
                Student__c = stu.Id,
                Gross_Amount__c = 5000,
                Due_Date__c = Date.today().addDays(-30),
                Payment_Date__c = Date.today().addDays(-35),
                Payment_Status__c = 'Paid',
                Term__c = 'Fall 2026'
            );
            Fee_Invoice__c fee2 = new Fee_Invoice__c(
                Student__c = stu.Id,
                Gross_Amount__c = 5000,
                Due_Date__c = Date.today().addDays(15),
                Payment_Status__c = 'Pending',
                Term__c = 'Fall 2026'
            );
            insert new List<Fee_Invoice__c>{ fee1, fee2 };
        } catch (Exception ex) {
            System.debug('Fee invoice creation skipped in test: ' + ex.getMessage());
        }
    }

    @isTest
    static void testGetStudentSummarySuccess() {
        Student__c stu = [SELECT Id FROM Student__c WHERE Student_Name__c = 'Alex Morgan' LIMIT 1];

        Test.startTest();
        StudentSummaryController.StudentSummaryDTO dto = StudentSummaryController.getStudentSummary(stu.Id);
        Test.stopTest();

        System.assertNotEquals(null, dto, 'DTO should not be null');
        System.assertEquals('Alex Morgan', dto.studentName, 'Student name should match');
        System.assertEquals('Bachelor of Science in Computer Science', dto.programName, 'Program should match');
        System.assertEquals('Engineering', dto.department, 'Department should match');
        System.assertEquals(3.85, dto.gpa, 'GPA should match');
        System.assertEquals('Active', dto.enrolmentStatus, 'Enrolment status should match');
        System.assertEquals('Pending', dto.feeStatus, 'Fee status should resolve to Pending');
        System.assertEquals(2, dto.registeredCourseCount, 'Should have 2 registered courses');
        System.assertEquals(7.0, dto.totalRegisteredCredits, 'Total credits should be 4 + 3 = 7');
        System.assertNotEquals(null, dto.registeredCourses, 'Registered courses list should not be empty');
        System.assertEquals(2, dto.registeredCourses.size(), 'Should contain 2 course wrappers');
        System.assert(dto.attendance > 0, 'Attendance should be calculated from enrolments');
    }

    @isTest
    static void testStudentDirectOverridesIfFieldsExist() {
        Student__c stu = [SELECT Id FROM Student__c WHERE Student_Name__c = 'Alex Morgan' LIMIT 1];
        Map<String, SObjectField> fieldMap = SObjectType.Student__c.fields.getMap();
        Boolean updated = false;

        if (fieldMap.containsKey('attendance__c')) {
            stu.put('Attendance__c', 95.00);
            updated = true;
        }
        if (fieldMap.containsKey('fee_status__c')) {
            stu.put('Fee_Status__c', 'Paid');
            updated = true;
        }

        if (updated) {
            update stu;
        }

        Test.startTest();
        StudentSummaryController.StudentSummaryDTO dto = StudentSummaryController.getStudentSummary(stu.Id);
        Test.stopTest();

        System.assertNotEquals(null, dto, 'DTO should be returned');
        if (fieldMap.containsKey('attendance__c')) {
            System.assertEquals(95.00, dto.attendance, 'Direct Attendance__c field should take precedence');
        }
    }

    @isTest
    static void testNullStudentId() {
        Test.startTest();
        try {
            StudentSummaryController.getStudentSummary(null);
            System.assert(false, 'Should throw an AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Exception message should exist');
        }
        Test.stopTest();
    }
}
