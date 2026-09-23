import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getStudentSummary from '@salesforce/apex/StudentSummaryController.getStudentSummary';

export default class StudentSummaryCard extends LightningElement {
    @api recordId;

    studentData;
    errorMessage;
    isLoading = true;
    wiredStudentResult;

    @wire(getStudentSummary, { studentId: '$recordId' })
    wiredSummary(result) {
        this.wiredStudentResult = result;
        const { data, error } = result;

        if (data) {
            this.studentData = data;
            this.errorMessage = undefined;
            this.isLoading = false;
        } else if (error) {
            this.errorMessage = error?.body?.message || 'Error loading student summary.';
            this.studentData = undefined;
            this.isLoading = false;
        }
    }

    async handleRefresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredStudentResult);
        } catch (e) {
            this.errorMessage = e?.body?.message || 'Failed to refresh student details.';
        } finally {
            this.isLoading = false;
        }
    }

    // 1. Student Name
    get studentName() {
        return this.studentData?.studentName || 'Student Name';
    }

    // 2. Student ID (UHID style)
    get studentCode() {
        return this.studentData?.studentCode || 'N/A';
    }

    // 3. Enrolment Status
    get enrolmentStatus() {
        return this.studentData?.enrolmentStatus || 'Active';
    }

    get statusPillClass() {
        const status = (this.enrolmentStatus || '').toLowerCase();
        if (status === 'active' || status === 'enrolled') {
            return 'status-pill pill-active';
        } else if (status === 'offer accepted' || status === 'on leave') {
            return 'status-pill pill-pending';
        } else if (status === 'graduated') {
            return 'status-pill pill-graduated';
        } else if (status === 'withdrawn') {
            return 'status-pill pill-withdrawn';
        }
        return 'status-pill pill-default';
    }

    get statusDotClass() {
        const status = (this.enrolmentStatus || '').toLowerCase();
        if (status === 'active' || status === 'enrolled') {
            return 'status-dot dot-green';
        } else if (status === 'offer accepted' || status === 'on leave') {
            return 'status-dot dot-amber';
        } else if (status === 'graduated') {
            return 'status-dot dot-blue';
        } else if (status === 'withdrawn') {
            return 'status-dot dot-red';
        }
        return 'status-dot dot-gray';
    }

    // 4. Cumulative GPA
    get formattedGpa() {
        const val = this.studentData?.gpa;
        return val != null ? Number(val).toFixed(2) : '0.00';
    }

    // 5. Attendance
    get formattedAttendance() {
        const att = this.studentData?.attendance;
        return att != null ? Number(att).toFixed(1) : '0.0';
    }

    // 6. Fee Status
    get feeStatus() {
        return this.studentData?.feeStatus || 'Paid';
    }

    get feeTileClass() {
        const status = (this.feeStatus || '').toLowerCase();
        if (status === 'paid') return 'metric-tile tile-emerald';
        if (status === 'pending' || status === 'partially paid') return 'metric-tile tile-amber';
        if (status === 'overdue') return 'metric-tile tile-rose';
        return 'metric-tile tile-blue';
    }

    get feeSquircleClass() {
        const status = (this.feeStatus || '').toLowerCase();
        if (status === 'paid') return 'tile-icon-squircle squircle-emerald';
        if (status === 'pending' || status === 'partially paid') return 'tile-icon-squircle squircle-amber';
        if (status === 'overdue') return 'tile-icon-squircle squircle-rose';
        return 'tile-icon-squircle squircle-blue';
    }

    get feeValTextClass() {
        const status = (this.feeStatus || '').toLowerCase();
        if (status === 'paid') return 'tile-primary-val text-emerald';
        if (status === 'pending' || status === 'partially paid') return 'tile-primary-val text-amber';
        if (status === 'overdue') return 'tile-primary-val text-rose';
        return 'tile-primary-val';
    }

    get feeBarClass() {
        const status = (this.feeStatus || '').toLowerCase();
        if (status === 'paid') return 'bottom-accent-bar bar-emerald';
        if (status === 'pending' || status === 'partially paid') return 'bottom-accent-bar bar-amber';
        if (status === 'overdue') return 'bottom-accent-bar bar-rose';
        return 'bottom-accent-bar bar-blue';
    }

    // 7. Registered Courses Count
    get registeredCourseCount() {
        return this.studentData?.registeredCourseCount != null
            ? this.studentData.registeredCourseCount
            : (this.studentData?.registeredCourses?.length || 0);
    }

    // 8. Program
    get programName() {
        return this.studentData?.programName || 'Not Assigned';
    }

    get programId() {
        return this.studentData?.programId;
    }

    get programUrl() {
        return this.programId ? `/${this.programId}` : '#';
    }

    // 9. Department
    get department() {
        return this.studentData?.department || 'General Academic';
    }

    // 10. Semester
    get semester() {
        return this.studentData?.semester || 'Semester 1';
    }

    // 11. Faculty Advisor
    get facultyAdvisorName() {
        return this.studentData?.facultyAdvisorName || 'Not Assigned';
    }

    get facultyAdvisorId() {
        return this.studentData?.facultyAdvisorId;
    }

    get facultyAdvisorUrl() {
        return this.facultyAdvisorId ? `/${this.facultyAdvisorId}` : '#';
    }

    // 12. Admission Date
    get admissionDate() {
        return this.studentData?.admissionDate;
    }
}