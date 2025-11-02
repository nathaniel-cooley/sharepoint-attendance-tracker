# SharePoint Attendance Tracker - User Guide

## Overview
The SharePoint Attendance Tracker is an automated system that generates daily attendance records for employees based on their assigned offices. It handles both permanent and temporary office assignments.

## Table of Contents
1. [System Components](#system-components)
2. [Daily Operations](#daily-operations)
3. [Managing Employee Records](#managing-employee-records)
4. [Office Transfers](#office-transfers)
5. [Recording Attendance](#recording-attendance)
6. [Reports and Analytics](#reports-and-analytics)
7. [Common Scenarios](#common-scenarios)
8. [Troubleshooting](#troubleshooting)

## System Components

### EmployeeMaster List
Maintains the master record of all employees including:
- Employee ID (unique identifier)
- Employee Name
- Primary Office location
- Current employment status
- Department and contact information

### DailyAttendance List
Auto-generated daily with one record per active employee containing:
- Date of attendance
- Employee details (ID and Name)
- Assigned Office (where they should be)
- Actual Office (where they actually are - to be filled)
- Attendance Status
- Recording details (who recorded and when)

### OfficeTransfers List
Tracks temporary and permanent office assignments:
- Employee identification
- Source and destination offices
- Transfer dates (start and end)
- Transfer type and status
- Approval information

## Daily Operations

### Automated Daily Process
The system automatically runs every day at midnight (UTC) and:
1. Identifies all active employees from EmployeeMaster
2. Checks for active office transfers
3. Determines the assigned office for each employee
4. Creates a new attendance record in DailyAttendance
5. Sets initial status as "Pending"

### Morning Routine for Managers/HR
1. **Navigate to DailyAttendance List**:
   - Go to your SharePoint site
   - Click "Site Contents"
   - Open "DailyAttendance" list

2. **View Today's Records**:
   - Filter by Date = Today
   - Review all pending records

3. **Update Attendance**:
   - For each employee, update:
     - Actual Office (where they are)
     - Attendance Status (Present, Absent, On Leave, etc.)
   - The system automatically records who made the update and when

## Managing Employee Records

### Adding a New Employee

1. **Navigate to EmployeeMaster List**
2. **Click "New"** to create a new item
3. **Fill in required information**:
   - EmployeeID: Enter unique identifier (e.g., EMP001)
   - EmployeeName: Full name of employee
   - PrimaryOffice: Select from dropdown (Office A, B, C, D, or Remote)
   - CurrentStatus: Set to "Active"
   - Department: (Optional) Employee's department
   - EmailAddress: (Optional) Contact email

4. **Save the item**
5. **Verify**: The employee will be included in the next day's attendance generation

### Updating Employee Information

1. **Find the employee** in EmployeeMaster list
2. **Click on the item** or use "Edit" from the context menu
3. **Update required fields**:
   - Change PrimaryOffice if permanently relocated
   - Update CurrentStatus if employment status changes
   - Modify other details as needed
4. **Save changes**

### Deactivating an Employee

When an employee leaves or goes on extended leave:
1. Open their record in EmployeeMaster
2. Change **CurrentStatus** to:
   - "Inactive" for terminated employees
   - "On Leave" for extended absence
3. Save the record
4. The employee will no longer receive daily attendance records

### Reactivating an Employee

1. Open the employee record
2. Change **CurrentStatus** back to "Active"
3. Save the record
4. They will be included in the next day's attendance generation

## Office Transfers

### Creating a Temporary Transfer

Use this when an employee needs to work from a different office temporarily:

1. **Navigate to OfficeTransfers List**
2. **Click "New"**
3. **Fill in the details**:
   - EmployeeID: Enter or select the employee ID
   - EmployeeName: Enter the employee name
   - FromOffice: Current/primary office
   - ToOffice: Temporary office location
   - StartDate: First day at new location
   - EndDate: Last day at new location
   - TransferType: Select "Temporary"
   - TransferStatus: Set to "Pending"
   - Reason: Enter reason for transfer

4. **Save the item**

5. **Approval Process**:
   - Approver reviews and updates:
     - TransferStatus: Change to "Approved"
     - ApprovedBy: System captures approver
     - ApprovalDate: System captures date
   
6. **Activation**:
   - On the StartDate, manually change TransferStatus to "Active"
   - Or wait for the automated process to activate it

7. **Automatic Completion**:
   - The Logic App automatically changes status to "Completed" when EndDate passes

### Creating a Permanent Transfer

For permanent office relocations:

1. **Option A: Update EmployeeMaster** (Recommended):
   - Open employee record
   - Change PrimaryOffice to new location
   - Save

2. **Option B: Use OfficeTransfers**:
   - Follow temporary transfer steps
   - Set TransferType to "Permanent"
   - Leave EndDate blank
   - After activation, update EmployeeMaster with new PrimaryOffice

### Managing Active Transfers

**View Active Transfers**:
- Filter OfficeTransfers list by TransferStatus = "Active"
- Review StartDate and EndDate

**Cancel a Transfer**:
1. Open the transfer record
2. Change TransferStatus to "Cancelled"
3. Add note in Reason field
4. Save

**Extend a Transfer**:
1. Open the transfer record
2. Update the EndDate to new date
3. Add note in Reason field
4. Save

## Recording Attendance

### Standard Attendance Recording

**For Present Employees**:
1. Open DailyAttendance list
2. Filter to today's date
3. For each present employee:
   - ActualOffice: Confirm or update office location
   - AttendanceStatus: Select "Present"
   - Notes: Add any relevant comments
4. Save

**For Absent Employees**:
1. Locate employee record
2. Set AttendanceStatus to "Absent"
3. ActualOffice: Select "Not Present"
4. Notes: Add reason if known
5. Save

**For Work From Home**:
1. Set AttendanceStatus to "Work From Home"
2. ActualOffice: Select "Remote"
3. Save

**For On Leave**:
1. Set AttendanceStatus to "On Leave"
2. ActualOffice: Select "Not Present"
3. Notes: Add leave type if needed
4. Save

### Bulk Updates

For updating multiple records:
1. Use SharePoint's Quick Edit view
2. Click "Quick Edit" in the toolbar
3. Update multiple cells like a spreadsheet
4. Click "Stop" when done - changes auto-save

### Late Arrivals or Early Departures

Use the Notes field to record:
- "Arrived at 10:00 AM"
- "Left at 3:00 PM - personal appointment"
- "Half day - morning only"

## Reports and Analytics

### Daily Attendance Report

**Creating a Daily View**:
1. In DailyAttendance list, click "All Items" dropdown
2. Select "Create view"
3. Filter: Date = [Today]
4. Group by: AssignedOffice
5. Save as "Today's Attendance"

**Useful Columns to Display**:
- EmployeeID
- EmployeeName
- AssignedOffice
- ActualOffice
- AttendanceStatus
- RecordedBy
- RecordedDateTime

### Weekly/Monthly Reports

**Using Filters**:
- Date >= [Start of Week]
- Date <= [End of Week]
- Group by EmployeeName or Department

**Using Export to Excel**:
1. Set desired filters
2. Click "Export to Excel" in toolbar
3. Open in Excel for further analysis
4. Create pivot tables for summaries

### Office Utilization Report

**View by Office**:
1. Filter DailyAttendance for date range
2. Group by ActualOffice
3. Count employees per office
4. Export for capacity planning

### Employee Attendance History

**Individual Employee**:
1. Filter by EmployeeID
2. Sort by Date descending
3. Review attendance patterns
4. Export for performance reviews

### Transfer History

**View Transfer Records**:
1. Filter OfficeTransfers by EmployeeID
2. Show all transfer statuses
3. Track movement patterns

## Common Scenarios

### Scenario 1: Employee Working from Different Office for a Day

**One-time occurrence**:
- Don't create a transfer
- Just update ActualOffice in DailyAttendance for that day

### Scenario 2: Employee on Week-Long Training

**Option A**: Create temporary transfer
- Set start and end dates
- ToOffice: Training location

**Option B**: Update daily attendance manually
- Each day, set AttendanceStatus to "On Leave" or create custom status

### Scenario 3: Employee Permanently Moving Offices

1. Create permanent transfer in OfficeTransfers (optional for tracking)
2. Update PrimaryOffice in EmployeeMaster
3. Starting next day, assignments will reflect new office

### Scenario 4: Handling Public Holidays

**Option A**: Don't record attendance (leave as Pending)

**Option B**: Mark all as "On Leave"
- Use Quick Edit for bulk update
- Set AttendanceStatus = "On Leave"
- Notes = "Public Holiday"

### Scenario 5: New Office Location Added

1. **Update SharePoint Lists**:
   - Edit column settings for office choice fields
   - Add new office to choice list in:
     - EmployeeMaster: PrimaryOffice
     - DailyAttendance: AssignedOffice, ActualOffice
     - OfficeTransfers: FromOffice, ToOffice

2. **Update Logic App** (if needed):
   - Requires administrator access
   - Update workflow.json
   - Redeploy Logic App

## Troubleshooting

### No Attendance Record Generated

**Check**:
1. Is employee status "Active" in EmployeeMaster?
2. Did the Logic App run successfully today?
3. Are there any errors in Logic App run history?

**Solution**:
- Verify employee status
- Check Azure Portal for Logic App errors
- Manually create record if needed

### Wrong Office Assignment

**Immediate Fix**:
- Manually update AssignedOffice in today's record

**Permanent Fix**:
1. Check EmployeeMaster for correct PrimaryOffice
2. Check OfficeTransfers for conflicting active transfers
3. Update as needed

### Duplicate Records

**Cause**: Logic App may have run multiple times

**Fix**:
1. Identify duplicates (same EmployeeID and Date)
2. Delete extra records
3. Keep the most accurate one

**Prevention**:
- Contact administrator to review Logic App schedule
- Ensure trigger runs only once daily

### Transfer Not Reflecting

**Check**:
1. Is TransferStatus set to "Active"?
2. Is StartDate today or earlier?
3. Is EndDate today or later (or blank)?

**Fix**:
- Update transfer status to "Active"
- Verify dates
- Wait for next day's automated run or manually update today's record

### Permission Errors

**Symptom**: Cannot edit records or see lists

**Solution**:
- Contact site administrator
- Request appropriate permissions:
  - HR/Managers: Edit access to all lists
  - Employees: Read access to view their own records

## Best Practices

### For Managers
1. Review and update attendance daily
2. Address discrepancies promptly
3. Keep notes detailed for auditing
4. Regularly review office utilization
5. Plan office transfers in advance

### For HR
1. Keep EmployeeMaster up to date
2. Monitor transfer requests
3. Generate regular reports
4. Archive old records periodically
5. Train new users on the system

### For System Administrators
1. Monitor Logic App run history weekly
2. Review error logs
3. Maintain documentation
4. Test changes in development first
5. Back up configurations before updates

## Support

### Getting Help
- **Technical Issues**: Contact IT/System Administrator
- **Process Questions**: Contact HR Department
- **Access Issues**: Contact SharePoint Site Administrator

### Reporting Bugs or Issues
Include:
- What you were trying to do
- What happened instead
- Screenshot if applicable
- Date and time of issue
- Your username

## Appendix

### Status Definitions

**AttendanceStatus Values**:
- **Pending**: Not yet recorded (auto-generated)
- **Present**: Employee is at assigned office
- **Absent**: Employee not present, unplanned
- **On Leave**: Planned absence (vacation, sick leave)
- **Work From Home**: Working remotely

**CurrentStatus Values**:
- **Active**: Currently employed, receives daily records
- **Inactive**: Terminated or separated
- **On Leave**: Extended leave (maternity, sabbatical)
- **Transferred**: Permanently moved to different location

**TransferStatus Values**:
- **Pending**: Awaiting approval
- **Approved**: Approved but not yet started
- **Active**: Currently in effect
- **Completed**: Transfer period ended
- **Rejected**: Not approved
- **Cancelled**: Cancelled before or during transfer

### Keyboard Shortcuts

In SharePoint Lists:
- **Ctrl + Home**: Go to first item
- **Ctrl + End**: Go to last item
- **F2**: Edit selected item
- **Escape**: Cancel edit
- **Enter**: Save item (in Quick Edit)

### Quick Reference

| Task | List | Action |
|------|------|--------|
| Add Employee | EmployeeMaster | New → Fill details → Save |
| Record Attendance | DailyAttendance | Filter today → Update status |
| Create Transfer | OfficeTransfers | New → Fill details → Approve |
| Deactivate Employee | EmployeeMaster | Edit → Status = Inactive |
| View Report | DailyAttendance | Filter dates → Export Excel |
