# SharePoint Attendance Tracker - Setup Guide

## Overview
This guide provides step-by-step instructions for setting up the SharePoint Attendance Tracking system with Azure Logic Apps integration.

## Prerequisites

### Azure Requirements
- Active Azure subscription
- Permissions to create resources in Azure
- Azure PowerShell module installed (or use Azure Cloud Shell)

### SharePoint Requirements
- SharePoint Online site (Office 365)
- Site Collection Administrator or Owner permissions
- SharePoint site URL (e.g., `https://yourtenant.sharepoint.com/sites/AttendanceTracking`)

### Local Development Requirements
- PowerShell 5.1 or later (PowerShell 7+ recommended)
- Azure PowerShell module (`Az` module)
- Text editor for configuration files

## Setup Process

### Step 1: Prepare SharePoint Site

1. **Create a SharePoint site** (if not already exists):
   - Navigate to SharePoint Admin Center
   - Create a new Team Site or Communication Site
   - Name: "Attendance Tracking" (or your preferred name)
   - Note the site URL for later use

2. **Create SharePoint Lists**:
   
   Use the schema definitions in `sharepoint/lists/schemas.json` to create three lists:

   #### EmployeeMaster List
   - Go to Site Contents → New → List
   - Name: `EmployeeMaster`
   - Description: "Master list containing employee details and primary office assignments"
   - Create custom columns as defined in the schema:
     - EmployeeID (Single line of text, Required, Indexed)
     - EmployeeName (Single line of text, Required)
     - PrimaryOffice (Choice: Office A, Office B, Office C, Office D, Remote)
     - CurrentStatus (Choice: Active, Inactive, On Leave, Transferred)
     - Department (Single line of text)
     - EmailAddress (Single line of text)

   #### DailyAttendance List
   - Name: `DailyAttendance`
   - Description: "Daily attendance tracking list (auto-generated daily)"
   - Create custom columns:
     - Date (Date, Required, Indexed)
     - EmployeeID (Single line of text, Required, Indexed)
     - EmployeeName (Single line of text, Required)
     - AssignedOffice (Choice: Office A, Office B, Office C, Office D, Remote)
     - ActualOffice (Choice: Office A, Office B, Office C, Office D, Remote, Not Present)
     - AttendanceStatus (Choice: Pending, Present, Absent, On Leave, Work From Home)
     - RecordedBy (Person or Group)
     - RecordedDateTime (Date and Time)
     - Notes (Multiple lines of text)

   #### OfficeTransfers List
   - Name: `OfficeTransfers`
   - Description: "Tracks temporary and permanent office assignments"
   - Create custom columns:
     - EmployeeID (Single line of text, Required, Indexed)
     - EmployeeName (Single line of text, Required)
     - FromOffice (Choice: Office A, Office B, Office C, Office D, Remote)
     - ToOffice (Choice: Office A, Office B, Office C, Office D, Remote)
     - StartDate (Date, Required, Indexed)
     - EndDate (Date)
     - TransferType (Choice: Temporary, Permanent)
     - TransferStatus (Choice: Pending, Approved, Rejected, Active, Completed, Cancelled)
     - ApprovedBy (Person or Group)
     - ApprovalDate (Date and Time)
     - Reason (Multiple lines of text)

3. **Populate EmployeeMaster List**:
   - Add employee records with:
     - Unique EmployeeID
     - Employee name
     - Primary office assignment
     - Current status (Active for employees who should get daily attendance records)

### Step 2: Deploy Azure Logic App

1. **Open PowerShell** (as Administrator):
   ```powershell
   # Navigate to the scripts directory
   cd path/to/sharepoint-attendance-tracker/scripts
   ```

2. **Run the setup script**:
   ```powershell
   .\setup-connection.ps1 `
       -ResourceGroupName "rg-attendance-tracker" `
       -Location "eastus" `
       -LogicAppName "la-attendance-tracker" `
       -SharePointSiteUrl "https://yourtenant.sharepoint.com/sites/AttendanceTracking"
   ```

   Parameters:
   - `ResourceGroupName`: Name for the Azure resource group (will be created if it doesn't exist)
   - `Location`: Azure region (e.g., eastus, westus, westeurope)
   - `LogicAppName`: Name for the Logic App
   - `SharePointSiteUrl`: Full URL to your SharePoint site
   - `SubscriptionId`: (Optional) Azure subscription ID if you have multiple subscriptions

3. **Follow the script prompts**:
   - Sign in to Azure when prompted
   - Wait for resources to be created
   - Note the output information

### Step 3: Authorize SharePoint Connection

After the script completes, you must authorize the SharePoint connection:

1. **Navigate to Azure Portal** (https://portal.azure.com)

2. **Find the API Connection**:
   - Go to Resource Groups
   - Select your resource group (e.g., `rg-attendance-tracker`)
   - Find the connection resource (e.g., `la-attendance-tracker-sharepoint-connection`)

3. **Authorize the connection**:
   - Click on the connection resource
   - In the left menu, click "Edit API connection"
   - Click the "Authorize" button
   - Sign in with credentials that have access to the SharePoint site
   - Click "Save"

4. **Verify connection status**:
   - The connection status should show as "Connected"
   - If not, review the error message and ensure the credentials have proper permissions

### Step 4: Configure and Test Logic App

1. **Open the Logic App** in Azure Portal:
   - Navigate to your resource group
   - Click on the Logic App resource
   - Click "Logic app designer"

2. **Review the workflow**:
   - Verify all actions are properly connected
   - Check that parameters are correctly set
   - Ensure no warning icons are displayed

3. **Adjust the schedule** (optional):
   - Click on the "Daily_Schedule" trigger
   - Modify the time zone if needed (default is UTC)
   - Change the hour if you want it to run at a different time
   - Save the Logic App

4. **Test the Logic App**:
   - Click "Run Trigger" → "Daily_Schedule"
   - Monitor the run in "Runs history"
   - Check that attendance records are created in the DailyAttendance list
   - Review any errors in the run details

### Step 5: Verify Setup

1. **Check SharePoint Lists**:
   - Navigate to your SharePoint site
   - Open the DailyAttendance list
   - Verify that records were created for today's date
   - Check that EmployeeID and AssignedOffice are populated correctly

2. **Test Office Transfers**:
   - Create a transfer record in OfficeTransfers list:
     - EmployeeID: Select an existing employee
     - FromOffice: Their current primary office
     - ToOffice: A different office
     - StartDate: Today or earlier
     - EndDate: Future date (or leave blank for permanent)
     - TransferStatus: Active
   - Run the Logic App manually
   - Verify the employee's AssignedOffice in DailyAttendance reflects the transfer

3. **Monitor Logic App**:
   - Check run history for successful executions
   - Review any failed runs and address errors
   - Enable diagnostic logging if needed

## Configuration Options

### Changing Office Names
If you need different office names:
1. Update the choice columns in SharePoint lists
2. Update the workflow.json file with new office names
3. Redeploy the Logic App using the setup script

### Adjusting Concurrency
The workflow is configured to process 20 employees concurrently. To change:
1. Edit `logic-app/workflow.json`
2. Find `"concurrency": { "repetitions": 20 }`
3. Adjust the number (1-50 recommended)
4. Redeploy using the setup script

### Adding Email Notifications
To enable email notifications:
1. Add an Office 365 Outlook connection in Azure
2. Replace the "Compose" actions in `Send_Error_Notification` and `Send_Success_Notification` with "Send an email" actions
3. Configure recipient addresses and email content

## Troubleshooting

### Connection Authorization Failed
- Ensure you're signing in with an account that has access to the SharePoint site
- Verify the SharePoint site URL is correct
- Check that the user has at least Edit permissions on all lists

### Logic App Run Fails
- Check the run history for specific error messages
- Verify SharePoint list names match exactly (case-sensitive)
- Ensure all required columns exist in SharePoint lists
- Check that there are active employees in EmployeeMaster

### No Attendance Records Created
- Verify EmployeeMaster list has employees with CurrentStatus = "Active"
- Check Logic App run history for errors
- Ensure SharePoint connection is authorized
- Verify list names in Logic App parameters

### Duplicate Records
- The Logic App doesn't check for existing records by default
- If running multiple times per day, you may get duplicates
- Consider adding a check in the workflow or adjusting the schedule

### Performance Issues
- Reduce concurrency setting if experiencing timeouts
- Consider pagination settings if you have many employees
- Monitor Azure Logic App metrics for throttling

## Maintenance

### Daily Operations
- No daily maintenance required
- Logic App runs automatically at scheduled time
- Monitor run history periodically

### Regular Tasks
- Review and clean up old attendance records (monthly/quarterly)
- Update employee master list as employees join/leave
- Audit office transfer records
- Review error logs and address issues

### Updates and Changes
- Back up workflow definition before making changes
- Test changes in a development environment first
- Use version control for workflow JSON files
- Document customizations

## Security Considerations

### Access Control
- Grant minimum necessary permissions to service accounts
- Use separate accounts for Logic App connections
- Regularly review SharePoint site permissions
- Audit access to sensitive employee data

### Data Protection
- Consider retention policies for attendance data
- Implement data encryption if required
- Follow organizational compliance requirements
- Document data handling procedures

## Support and Resources

### Azure Resources
- [Azure Logic Apps Documentation](https://docs.microsoft.com/azure/logic-apps/)
- [SharePoint Connector Reference](https://docs.microsoft.com/connectors/sharepointonline/)

### SharePoint Resources
- [SharePoint Online Documentation](https://docs.microsoft.com/sharepoint/sharepoint-online)
- [SharePoint List Schemas](https://docs.microsoft.com/sharepoint/dev/schema/list-schema)

### Getting Help
- Check Azure Logic App run history for detailed error messages
- Review SharePoint ULS logs for server-side issues
- Consult Azure support for platform-related problems

## Next Steps

After completing setup:
1. Review the [User Guide](user-guide.md) for daily usage instructions
2. Train managers and HR staff on using the system
3. Establish processes for handling exceptions
4. Set up monitoring and alerting
5. Plan for regular maintenance and updates
