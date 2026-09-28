import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getStudentSummary from '@salesforce/apex/StudentSummaryController.getStudentSummary';
import RGPV_ASSETS from '@salesforce/resourceUrl/RGPVAssets';

export default class StudentSummaryCard extends LightningElement {
    @api recordId;

    studentData;
    errorMessage;
    isLoading = true;
    wiredStudentResult;

    get rgpvLogoUrl() {
        return `${RGPV_ASSETS}/logo/rgpv-logo.png`;
    }

    get rgpvCampusUrl() {
        return `${RGPV_ASSETS}/campus/rgpv-campus.jpg`;
    }

    get studentAvatarUrl() {
        return `${RGPV_ASSETS}/avatar/student-avatar.png`;
    }

    get rgpvAcadWatermarkUrl() {
        return `${RGPV_ASSETS}/watermarks/acad-watermark.png`;
    }

    get rgpvInstWatermarkUrl() {
        return `${RGPV_ASSETS}/watermarks/inst-watermark.png`;
    }

    get gpaBarClass() {
        return 'metric-fill fill-orange';
    }

    get attendanceBarClass() {
        return 'metric-fill fill-green';
    }

    get courseBarClass() {
        return 'metric-fill fill-blue';
    }

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

    get studentName() {
        return this.studentData?.studentName || 'Student Name';
    }

    get studentCode() {
        return this.studentData?.studentCode || 'N/A';
    }

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

    get formattedGpa() {
        const val = this.studentData?.gpa;
        return val != null ? Number(val).toFixed(2) : '0.00';
    }

    get formattedAttendance() {
        const att = this.studentData?.attendance;
        return att != null ? Number(att).toFixed(1) : '0.0';
    }

    get feeStatus() {
        return this.studentData?.feeStatus || 'Paid';
    }

    get feeTileClass() {
        const status = (this.feeStatus || '').toLowerCase();

        if (status === 'paid') return 'metric-card fee-green';
        if (status === 'pending' || status === 'partially paid') return 'metric-card fee-orange';
        if (status === 'overdue') return 'metric-card fee-red';

        return 'metric-card fee-blue';
    }

    get feeSquircleClass() {
        const status = (this.feeStatus || '').toLowerCase();

        if (status === 'paid') return 'metric-icon icon-green';
        if (status === 'pending' || status === 'partially paid') return 'metric-icon icon-orange';
        if (status === 'overdue') return 'metric-icon icon-red';

        return 'metric-icon icon-blue';
    }

    get feeValTextClass() {
        const status = (this.feeStatus || '').toLowerCase();

        if (status === 'paid') return 'metric-value value-green';
        if (status === 'pending' || status === 'partially paid') return 'metric-value value-orange';
        if (status === 'overdue') return 'metric-value value-red';

        return 'metric-value';
    }

    get registeredCourseCount() {
        return this.studentData?.registeredCourseCount != null
            ? this.studentData.registeredCourseCount
            : (this.studentData?.registeredCourses?.length || 0);
    }

    get programName() {
        return this.studentData?.programName || 'Not Assigned';
    }

    get programId() {
        return this.studentData?.programId;
    }

    get programUrl() {
        return this.programId ? `/${this.programId}` : '#';
    }

    get department() {
        return this.studentData?.department || 'General Academic';
    }

    get semester() {
        return this.studentData?.semester || 'Semester 1';
    }

    get facultyAdvisorName() {
        return this.studentData?.facultyAdvisorName || 'Not Assigned';
    }

    get facultyAdvisorId() {
        return this.studentData?.facultyAdvisorId;
    }

    get facultyAdvisorUrl() {
        return this.facultyAdvisorId ? `/${this.facultyAdvisorId}` : '#';
    }

    get admissionDate() {
        return this.studentData?.admissionDate;
    }
}