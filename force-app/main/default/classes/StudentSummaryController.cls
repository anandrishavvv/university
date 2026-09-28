/**
 * @description Controller for Student Summary Card LWC.
 * Dynamically queries student academic summary, active course registrations, attendance, and fee status.
 * Resilient to schema evolution: safely handles custom fields whether they are created yet or not.
 */
public with sharing class StudentSummaryController {

    public class CourseWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String courseName { get; set; }
        @AuraEnabled public String courseCode { get; set; }
        @AuraEnabled public Decimal credits { get; set; }
        @AuraEnabled public String term { get; set; }
        @AuraEnabled public String instructorName { get; set; }
        @AuraEnabled public Decimal attendancePercentage { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String grade { get; set; }
        @AuraEnabled public Date registrationDate { get; set; }
    }

    public class FeeInvoiceWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String invoiceNumber { get; set; }
        @AuraEnabled public Decimal grossAmount { get; set; }
        @AuraEnabled public Decimal netAmountDue { get; set; }
        @AuraEnabled public Date dueDate { get; set; }
        @AuraEnabled public Date paymentDate { get; set; }
        @AuraEnabled public String paymentStatus { get; set; }
        @AuraEnabled public String term { get; set; }
    }

    public class StudentSummaryDTO {
        @AuraEnabled public String studentId { get; set; }
        @AuraEnabled public String studentRecordNumber { get; set; }
        @AuraEnabled public String studentCode { get; set; }
        @AuraEnabled public String studentName { get; set; }
        @AuraEnabled public String programName { get; set; }
        @AuraEnabled public String programId { get; set; }
        @AuraEnabled public String programCode { get; set; }
        @AuraEnabled public String department { get; set; }
        @AuraEnabled public String semester { get; set; }
        @AuraEnabled public String facultyAdvisorName { get; set; }
        @AuraEnabled public String facultyAdvisorId { get; set; }
        @AuraEnabled public Decimal gpa { get; set; }
        @AuraEnabled public Decimal attendance { get; set; }
        @AuraEnabled public String feeStatus { get; set; }
        @AuraEnabled public Integer registeredCourseCount { get; set; }
        @AuraEnabled public Decimal totalRegisteredCredits { get; set; }
        @AuraEnabled public String enrolmentStatus { get; set; }
        @AuraEnabled public Date admissionDate { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String academicStanding { get; set; }
        @AuraEnabled public Date expectedGraduationDate { get; set; }
        @AuraEnabled public String gender { get; set; }
        @AuraEnabled public List<CourseWrapper> registeredCourses { get; set; }
        @AuraEnabled public List<FeeInvoiceWrapper> feeInvoices { get; set; }
        @AuraEnabled public Decimal totalFeeOutstanding { get; set; }
    }

    /**
     * @description Fetches all academic data for a single student by record ID.
     */
    @AuraEnabled(cacheable=true)
    public static StudentSummaryDTO getStudentSummary(Id studentId) {
        if (studentId == null) {
            throw new AuraHandledException('Student ID cannot be null.');
        }

        // Dynamically inspect available fields on Student__c
        Map<String, SObjectField> fieldMap = SObjectType.Student__c.fields.getMap();
        List<String> selectFields = new List<String>{
            'Id', 'Name', 'Student_Name__c', 'Student_ID__c', 'Cumulative_GPA__c',
            'Enrolment_Status__c', 'Academic_Standing__c', 'Email__c', 'Phone__c',
            'Expected_Graduation_Date__c', 'Faculty_Advisor__c', 'Faculty_Advisor__r.Name',
            'Program__c', 'Program__r.Name', 'Program__r.Program_Name__c',
            'Program__r.Program_Code__c', 'Program__r.Department__c'
        };

        // Conditionally append fields if they exist in this org
        if (fieldMap.containsKey('admission_date__c')) {
            selectFields.add('Admission_Date__c');
        }
        if (fieldMap.containsKey('semester__c')) {
            selectFields.add('Semester__c');
        }
        if (fieldMap.containsKey('department__c')) {
            selectFields.add('Department__c');
        }
        if (fieldMap.containsKey('attendance__c')) {
            selectFields.add('Attendance__c');
        }
        if (fieldMap.containsKey('fee_status__c')) {
            selectFields.add('Fee_Status__c');
        }
        if (fieldMap.containsKey('registered_courses_count__c')) {
            selectFields.add('Registered_Courses_Count__c');
        }
        if (fieldMap.containsKey('gender__c')) {
            selectFields.add('Gender__c');
        }

        // Subquery for enrolments and fee invoices
        String enrolmentSubquery = '(SELECT Id, Name, Enrolment_Status__c, Attendance_Percentage__c, ' +
            'Grade__c, Grade_Points__c, Registration_Date__c, ' +
            'Course_Offering__c, Course_Offering__r.Name, ' +
            'Course_Offering__r.Course_Code__c, Course_Offering__r.Course_Name__c, ' +
            'Course_Offering__r.Credits__c, Course_Offering__r.Term__c, ' +
            'Course_Offering__r.Instructor__r.Name ' +
            'FROM Enrolments__r ' +
            'ORDER BY Registration_Date__c DESC NULLS LAST, CreatedDate DESC)';

        String feeSubquery = '(SELECT Id, Name, Invoice_Number__c, Gross_Amount__c, ' +
            'Net_Amount_Due__c, Payment_Status__c, Due_Date__c, ' +
            'Payment_Date__c, Term__c ' +
            'FROM Fee_Invoices__r ' +
            'ORDER BY Due_Date__c DESC NULLS LAST, CreatedDate DESC)';

        String queryString = 'SELECT ' + String.join(selectFields, ', ') + ', ' +
            enrolmentSubquery + ', ' + feeSubquery + ' ' +
            'FROM Student__c ' +
            'WHERE Id = :studentId ' +
            'LIMIT 1';

        Map<String, Object> bindVars = new Map<String, Object>{ 'studentId' => studentId };
        List<Student__c> students = Database.queryWithBinds(queryString, bindVars, AccessLevel.USER_MODE);

        if (students.isEmpty()) {
            throw new AuraHandledException('Student record not found for ID: ' + studentId);
        }

        Student__c student = students[0];
        StudentSummaryDTO dto = new StudentSummaryDTO();

        // 1. Core Student Details
        dto.studentId = student.Id;
        dto.studentRecordNumber = student.Name;
        dto.studentCode = String.isNotBlank(student.Student_ID__c) ? student.Student_ID__c : student.Name;
        dto.studentName = String.isNotBlank(student.Student_Name__c) ? student.Student_Name__c : student.Name;
        dto.email = student.Email__c;
        dto.phone = student.Phone__c;
        dto.enrolmentStatus = String.isNotBlank(student.Enrolment_Status__c) ? student.Enrolment_Status__c : 'Active';
        dto.academicStanding = String.isNotBlank(student.Academic_Standing__c) ? student.Academic_Standing__c : 'Good Standing';
        dto.expectedGraduationDate = student.Expected_Graduation_Date__c;

        // Gender (safe dynamic extraction)
        if (fieldMap.containsKey('gender__c') && student.get('Gender__c') != null) {
            dto.gender = String.valueOf(student.get('Gender__c'));
        }

        // Admission Date (safe dynamic extraction)
        if (fieldMap.containsKey('admission_date__c') && student.get('Admission_Date__c') != null) {
            dto.admissionDate = (Date) student.get('Admission_Date__c');
        }

        // 2. Program & Department Details
        if (student.Program__c != null) {
            dto.programId = student.Program__c;
            dto.programName = String.isNotBlank(student.Program__r.Program_Name__c)
                ? student.Program__r.Program_Name__c
                : student.Program__r.Name;
            dto.programCode = student.Program__r.Program_Code__c;
        }

        // Department
        if (fieldMap.containsKey('department__c') && student.get('Department__c') != null) {
            dto.department = String.valueOf(student.get('Department__c'));
        } else if (student.Program__c != null && String.isNotBlank(student.Program__r.Department__c)) {
            dto.department = student.Program__r.Department__c;
        } else {
            dto.department = 'General Academic';
        }

        // Semester
        if (fieldMap.containsKey('semester__c') && student.get('Semester__c') != null) {
            dto.semester = String.valueOf(student.get('Semester__c'));
        } else {
            dto.semester = 'Semester 1';
        }

        // 3. Faculty Advisor
        if (student.Faculty_Advisor__c != null) {
            dto.facultyAdvisorId = student.Faculty_Advisor__c;
            dto.facultyAdvisorName = student.Faculty_Advisor__r.Name;
        } else {
            dto.facultyAdvisorName = 'Not Assigned';
        }

        // 4. GPA
        dto.gpa = student.Cumulative_GPA__c != null ? student.Cumulative_GPA__c : 0.00;

        // 5. Enrolled Courses
        dto.registeredCourses = new List<CourseWrapper>();
        Decimal sumAttendance = 0.0;
        Integer attendanceCount = 0;
        Decimal totalCredits = 0.0;
        Integer activeRegisteredCount = 0;

        List<Enrolment__c> enrolments = (List<Enrolment__c>) student.getSObjects('Enrolments__r');
        if (enrolments != null) {
            for (Enrolment__c enr : enrolments) {
                CourseWrapper cw = new CourseWrapper();
                cw.id = enr.Id;
                cw.status = enr.Enrolment_Status__c;
                cw.attendancePercentage = enr.Attendance_Percentage__c;
                cw.grade = enr.Grade__c;
                cw.registrationDate = enr.Registration_Date__c;

                if (enr.Course_Offering__c != null) {
                    cw.courseName = String.isNotBlank(enr.Course_Offering__r.Course_Name__c)
                        ? enr.Course_Offering__r.Course_Name__c
                        : enr.Course_Offering__r.Name;
                    cw.courseCode = enr.Course_Offering__r.Course_Code__c;
                    cw.credits = enr.Course_Offering__r.Credits__c != null ? enr.Course_Offering__r.Credits__c : 0.0;
                    cw.term = enr.Course_Offering__r.Term__c;
                    cw.instructorName = enr.Course_Offering__r.Instructor__r.Name;
                }

                dto.registeredCourses.add(cw);

                if (enr.Enrolment_Status__c == 'Registered' || enr.Enrolment_Status__c == 'Active') {
                    activeRegisteredCount++;
                    if (cw.credits != null) {
                        totalCredits += cw.credits;
                    }
                }

                if (enr.Attendance_Percentage__c != null) {
                    sumAttendance += enr.Attendance_Percentage__c;
                    attendanceCount++;
                }
            }
        }

        // Registered course count
        if (fieldMap.containsKey('registered_courses_count__c') && student.get('Registered_Courses_Count__c') != null) {
            dto.registeredCourseCount = ((Decimal) student.get('Registered_Courses_Count__c')).intValue();
        } else {
            dto.registeredCourseCount = activeRegisteredCount;
        }
        dto.totalRegisteredCredits = totalCredits;

        // Attendance: Use direct Attendance__c if present, else calculate average from enrolments
        if (fieldMap.containsKey('attendance__c') && student.get('Attendance__c') != null) {
            dto.attendance = (Decimal) student.get('Attendance__c');
        } else if (attendanceCount > 0) {
            dto.attendance = (sumAttendance / attendanceCount).setScale(2, System.RoundingMode.HALF_UP);
        } else {
            dto.attendance = 0.0;
        }

        // 6. Fee Invoices & Overall Fee Status
        dto.feeInvoices = new List<FeeInvoiceWrapper>();
        Decimal outstandingAmount = 0.0;
        Boolean hasOverdue = false;
        Boolean hasPending = false;
        Boolean hasPartiallyPaid = false;
        Boolean hasInvoices = false;

        List<Fee_Invoice__c> feeInvoices = (List<Fee_Invoice__c>) student.getSObjects('Fee_Invoices__r');
        if (feeInvoices != null) {
            for (Fee_Invoice__c fee : feeInvoices) {
                hasInvoices = true;
                FeeInvoiceWrapper fw = new FeeInvoiceWrapper();
                fw.id = fee.Id;
                fw.invoiceNumber = String.isNotBlank(fee.Invoice_Number__c) ? fee.Invoice_Number__c : fee.Name;
                fw.grossAmount = fee.Gross_Amount__c;
                fw.netAmountDue = fee.Net_Amount_Due__c != null ? fee.Net_Amount_Due__c : 0.0;
                fw.dueDate = fee.Due_Date__c;
                fw.paymentDate = fee.Payment_Date__c;
                fw.paymentStatus = fee.Payment_Status__c;
                fw.term = fee.Term__c;
                dto.feeInvoices.add(fw);

                if (fee.Payment_Status__c == 'Overdue') {
                    hasOverdue = true;
                    outstandingAmount += (fee.Net_Amount_Due__c != null ? fee.Net_Amount_Due__c : 0.0);
                } else if (fee.Payment_Status__c == 'Pending') {
                    hasPending = true;
                    outstandingAmount += (fee.Net_Amount_Due__c != null ? fee.Net_Amount_Due__c : 0.0);
                } else if (fee.Payment_Status__c == 'Partially Paid') {
                    hasPartiallyPaid = true;
                    outstandingAmount += (fee.Net_Amount_Due__c != null ? fee.Net_Amount_Due__c : 0.0);
                }
            }
        }
        dto.totalFeeOutstanding = outstandingAmount;

        // Fee Status: Prioritize direct field if set, else deduce from invoices
        if (fieldMap.containsKey('fee_status__c') && student.get('Fee_Status__c') != null) {
            dto.feeStatus = String.valueOf(student.get('Fee_Status__c'));
        } else if (hasOverdue) {
            dto.feeStatus = 'Overdue';
        } else if (hasPartiallyPaid) {
            dto.feeStatus = 'Partially Paid';
        } else if (hasPending) {
            dto.feeStatus = 'Pending';
        } else if (hasInvoices) {
            dto.feeStatus = 'Paid';
        } else {
            dto.feeStatus = 'Paid';
        }

        return dto;
    }
}