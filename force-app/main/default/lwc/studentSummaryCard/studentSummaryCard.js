import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getStudentSummary from '@salesforce/apex/StudentSummaryController.getStudentSummary';
import RGPV_ASSETS from '@salesforce/resourceUrl/RGPVAssets';

export default class StudentSummaryCard extends LightningElement {
    @api recordId;
    @api displayMode = 'Full'; // 'Full', 'Compact', 'Details'

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

    get rgpvHeaderBannerUrl() {
        return `${RGPV_ASSETS}/campus/rgpv-campus-banner.png`;
    }

    get rgpvWatermarkBgUrl() {
        return `${RGPV_ASSETS}/logo/rgpv-logo.png`;
    }

    get studentAvatarUrl() {
        const gender = (this.studentData?.gender || '').toLowerCase();
        if (gender === 'female') {
            return `${RGPV_ASSETS}/avatar/student-avatar-female-circle.png`;
        }
        if (gender === 'male') {
            return `${RGPV_ASSETS}/avatar/student-avatar-male-circle.png`;
        }
        // Fallback heuristic for typical female names
        const name = (this.studentName || '').toLowerCase();
        if (name.includes('ananya') || name.includes('priya') || name.includes('neha') || name.includes('pooja') || name.includes('shreya') || name.includes('aditi')) {
            return `${RGPV_ASSETS}/avatar/student-avatar-female-circle.png`;
        }
        return `${RGPV_ASSETS}/avatar/student-avatar-male-circle.png`;
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

    get gpaBarClass() {
        return 'metric-fill fill-orange';
    }

    get formattedAttendance() {
        const att = this.studentData?.attendance;
        return att != null ? Number(att).toFixed(1) : '0.0';
    }

    get isAttendanceShortage() {
        const att = this.studentData?.attendance;
        return att != null && Number(att) < 75;
    }

    get attendanceCardClass() {
        return this.isAttendanceShortage ? 'metric-card metric-amber' : 'metric-card metric-green';
    }

    get attendanceIconClass() {
        return this.isAttendanceShortage ? 'metric-icon icon-amber' : 'metric-icon icon-green';
    }

    get attendanceTrackClass() {
        return this.isAttendanceShortage ? 'metric-track track-amber' : 'metric-track track-green';
    }

    get attendanceBarClass() {
        return this.isAttendanceShortage ? 'metric-fill fill-amber' : 'metric-fill fill-green';
    }

    get feeStatus() {
        return this.studentData?.feeStatus || 'Paid';
    }

    get isFeeOverdue() {
        return (this.feeStatus || '').toLowerCase() === 'overdue';
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

    get feePillClass() {
        const status = (this.feeStatus || '').toLowerCase();
        if (status === 'paid') return 'fee-pill pill-paid';
        if (status === 'overdue') return 'fee-pill pill-overdue';
        return 'fee-pill pill-pending';
    }

    get feeSubtext() {
        const status = (this.feeStatus || '').toLowerCase();
        if (status === 'overdue') return '1 Pending';
        if (status === 'paid') return 'All Paid';
        return 'Pending';
    }

    get registeredCourseCount() {
        return this.studentData?.registeredCourseCount != null
            ? this.studentData.registeredCourseCount
            : (this.studentData?.registeredCourses?.length || 0);
    }

    get totalCreditsBadge() {
        const credits = this.studentData?.totalRegisteredCredits;
        if (credits != null && credits > 0) {
            return `${Number(credits).toFixed(0)} Credits`;
        }
        return 'Active';
    }

    get courseBarClass() {
        return 'metric-fill fill-blue';
    }

    get primaryCourseDisplay() {
        const courses = this.studentData?.registeredCourses;
        if (!courses || courses.length === 0) {
            return null;
        }
        const first = courses[0];
        const code = first.courseCode || '';
        const name = first.courseName || '';
        let label = '';
        if (code && name) {
            label = `${code} · ${name}`;
        } else {
            label = name || code || 'Enrolled Course';
        }
        if (courses.length > 1) {
            label += ` (+${courses.length - 1} more)`;
        }
        return label;
    }

    get primaryCourseTooltip() {
        const courses = this.studentData?.registeredCourses;
        if (!courses || courses.length === 0) return '';
        return courses
            .map(c => `${c.courseCode || ''} ${c.courseName || ''} (${c.credits || 0} Credits)`)
            .join('\n');
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

    get formattedAdmissionDate() {
        const dateVal = this.studentData?.admissionDate;
        if (!dateVal) return 'Not Set';
        const d = new Date(dateVal);
        return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
    }
}