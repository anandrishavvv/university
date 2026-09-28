for (Student__c s : [SELECT Id, Student_Name__c, Gender__c FROM Student__c LIMIT 4]) {
    StudentSummaryController.StudentSummaryDTO dto = StudentSummaryController.getStudentSummary(s.Id);
    System.debug('STUDENT_TEST: Name=' + dto.studentName + ', Gender=' + dto.gender + ', GPA=' + dto.gpa + ', Courses=' + dto.registeredCourseCount);
}
