List<Student__c> students = [SELECT Id, Student_Name__c, Gender__c FROM Student__c];
for (Student__c s : students) {
    String n = (s.Student_Name__c != null) ? s.Student_Name__c.toLowerCase() : '';
    if (n.contains('ananya') || n.contains('priya') || n.contains('neha') || n.contains('pooja') || n.contains('shreya')) {
        s.Gender__c = 'Female';
    } else {
        s.Gender__c = 'Male';
    }
}
update students;
System.debug('Updated ' + students.size() + ' student genders.');
