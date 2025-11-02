# Export and Reset Workflow - User Guide

## Overview
The Export-Reset workflow complements the main attendance tracking system by providing a daily cycle that:
1. Exports the day's attendance data to a Parquet file for analytics (Databricks)
2. Resets the attendance list
3. Creates fresh records for the next day with employees assigned to primary offices

## Workflow Schedule

**Default Trigger Time**: 11:00 PM UTC (23:00)

This allows time for:
- Managers to assign employee offices during the day
- Secondary offices to mark actual attendance
- Data to be collected before export
- Export, reset, and preparation for the next day

## Workflow Sequence

### Step 1: Export Current Day's Data (23:00 UTC)

1. **Retrieve Today's Records**
   - Fetches all attendance records for the current date
   - Ordered by EmployeeID for consistent output

2. **Convert to Parquet Format**
   - Structures data with proper schema for Databricks
   - Includes all fields: Date, EmployeeID, EmployeeName, AssignedOffice, ActualOffice, AttendanceStatus, RecordedBy, RecordedDateTime, Notes

3. **Export to SharePoint**
   - Creates a file: `attendance_YYYYMMDD_HHMMSS.parquet`
   - Saves to SharePoint document library (default: `/AttendanceExports`)
   - Example filename: `attendance_20231115_230000.parquet`

### Step 2: Reset Attendance List

1. **Delete All Records**
   - Removes all items from DailyAttendance list
   - Processes deletions concurrently (20 at a time)
   - Ensures clean slate for next day

2. **Wait Period**
   - 10-second pause to ensure all deletions complete
   - Prevents conflicts with record creation

### Step 3: Create Fresh Records for Next Day

1. **Retrieve Active Employees**
   - Gets all employees with CurrentStatus = "Active"
   - Uses EmployeeMaster as the source

2. **Create New Records**
   - Generates one record per active employee
   - Date set to tomorrow (current date + 1 day)
   - AssignedOffice set to PrimaryOffice (from EmployeeMaster)
   - AttendanceStatus set to "Pending"
   - Processes creations concurrently (20 at a time)

## Parquet File Schema

The exported Parquet file contains the following schema:

```
{
  "Date": "date",              // Date of attendance (YYYY-MM-DD)
  "EmployeeID": "string",      // Employee identifier
  "EmployeeName": "string",    // Employee full name
  "AssignedOffice": "string",  // Office where employee was assigned
  "ActualOffice": "string",    // Office where employee actually attended (nullable)
  "AttendanceStatus": "string", // Status (Pending, Present, Absent, etc.)
  "RecordedBy": "string",      // User who recorded the attendance (nullable)
  "RecordedDateTime": "timestamp", // When attendance was recorded (nullable)
  "Notes": "string"            // Additional notes (nullable)
}
```

## Configuration Parameters

### SharePoint Site Configuration
```json
{
  "sharePointSiteUrl": "https://yourtenant.sharepoint.com/sites/AttendanceTracking",
  "employeeMasterListName": "EmployeeMaster",
  "dailyAttendanceListName": "DailyAttendance",
  "exportDocumentLibrary": "AttendanceExports",
  "exportFolderPath": "/AttendanceExports"
}
```

### Key Parameters to Configure

- **exportDocumentLibrary**: Name of the SharePoint document library for exports
- **exportFolderPath**: Folder path within the document library (e.g., `/AttendanceExports` or `/AttendanceExports/2023`)

## Daily Workflow Timeline

| Time (UTC) | Action | Description |
|------------|--------|-------------|
| 00:00 | - | Fresh records available for the new day |
| 09:00-17:00 | **Manager Actions** | Assign employees to offices |
| 09:00-18:00 | **Office Actions** | Mark actual attendance |
| 23:00 | **Export** | Export today's data to Parquet |
| 23:01 | **Reset** | Delete all attendance records |
| 23:02 | **Create** | Generate fresh records for tomorrow |

## Setup Instructions

### 1. Create SharePoint Document Library

1. Navigate to your SharePoint site
2. Create a new Document Library:
   - Name: `AttendanceExports`
   - Description: "Daily attendance exports for analytics"
3. (Optional) Create subfolders for organization (e.g., by year or month)

### 2. Deploy the Logic App

Using PowerShell:
```powershell
cd scripts
.\setup-export-reset-workflow.ps1 `
    -ResourceGroupName "rg-attendance-tracker" `
    -Location "eastus" `
    -LogicAppName "la-attendance-export-reset" `
    -SharePointSiteUrl "https://yourtenant.sharepoint.com/sites/AttendanceTracking" `
    -ExportFolderPath "/AttendanceExports"
```

### 3. Authorize SharePoint Connection

1. Go to Azure Portal
2. Navigate to the API connection
3. Click "Edit API connection"
4. Click "Authorize" and sign in
5. Save the connection

### 4. Adjust Schedule (Optional)

To change the export time:
1. Open the Logic App in Azure Portal
2. Click "Logic app designer"
3. Edit the "Daily_Export_Schedule" trigger
4. Change the hour (0-23 in UTC)
5. Save the Logic App

## Databricks Integration

### Reading Parquet Files

```python
# Mount SharePoint document library (if not already mounted)
# Or use direct path with authentication

# Read single file
df = spark.read.parquet("path/to/AttendanceExports/attendance_20231115_230000.parquet")

# Read all files in directory
df = spark.read.parquet("path/to/AttendanceExports/*.parquet")

# With schema enforcement
from pyspark.sql.types import *

schema = StructType([
    StructField("Date", DateType(), False),
    StructField("EmployeeID", StringType(), False),
    StructField("EmployeeName", StringType(), False),
    StructField("AssignedOffice", StringType(), False),
    StructField("ActualOffice", StringType(), True),
    StructField("AttendanceStatus", StringType(), False),
    StructField("RecordedBy", StringType(), True),
    StructField("RecordedDateTime", TimestampType(), True),
    StructField("Notes", StringType(), True)
])

df = spark.read.schema(schema).parquet("path/to/AttendanceExports/*.parquet")
```

### Sample Analytics Queries

```python
# Daily attendance summary
daily_summary = df.groupBy("Date", "AssignedOffice") \
    .agg(
        count("*").alias("TotalEmployees"),
        sum(when(col("AttendanceStatus") == "Present", 1).otherwise(0)).alias("Present"),
        sum(when(col("AttendanceStatus") == "Absent", 1).otherwise(0)).alias("Absent")
    )

# Office utilization
office_util = df.filter(col("AttendanceStatus") == "Present") \
    .groupBy("Date", "ActualOffice") \
    .agg(count("*").alias("EmployeeCount"))

# Employee attendance history
employee_history = df.filter(col("EmployeeID") == "EMP001") \
    .select("Date", "AssignedOffice", "ActualOffice", "AttendanceStatus") \
    .orderBy("Date")
```

## Monitoring and Logs

### Check Workflow Status

1. **Azure Portal**:
   - Navigate to the Logic App
   - View "Runs history"
   - Click on a run to see details

2. **Output Summary**:
   Each run provides a summary:
   ```json
   {
     "ExportDate": "2023-11-15",
     "ExportTimestamp": "20231115_230000",
     "RecordsExported": 150,
     "RecordsDeleted": 150,
     "RecordsCreated": 150,
     "NextDayDate": "2023-11-16",
     "CompletedAt": "2023-11-15T23:02:30Z"
   }
   ```

### Common Issues

#### Export Files Not Created
- **Cause**: No records for today
- **Solution**: Check that employees were marked with today's date

#### Deletion Fails
- **Cause**: Permissions or concurrent access
- **Solution**: Verify SharePoint connection, check site permissions

#### Duplicate Records After Reset
- **Cause**: Workflow ran multiple times
- **Solution**: Delete duplicates manually, check trigger schedule

## Workflow Comparison

### Main Workflow (workflow.json)
- **Purpose**: Generate daily records based on transfers
- **Schedule**: Midnight (00:00 UTC)
- **Creates**: Records with transfer-aware office assignments
- **Best For**: Automatic transfer handling

### Export-Reset Workflow (export-reset-workflow.json)
- **Purpose**: Export data, reset list, create fresh records
- **Schedule**: Night (23:00 UTC)
- **Creates**: Records with primary office only
- **Best For**: Daily analytics cycle, manual office assignments

## Best Practices

### 1. Backup Before Reset
The workflow exports before resetting, but consider:
- Retaining exports for compliance periods
- Creating SharePoint retention policies
- Backing up to Azure Blob Storage

### 2. Schedule Coordination
- Ensure managers complete assignments before 23:00 UTC
- Set reminder emails at 22:00 UTC
- Block list edits during reset window (23:00-23:05 UTC)

### 3. Monitor Export Files
- Check file sizes for anomalies
- Validate record counts match expectations
- Set up alerts for failed exports

### 4. Databricks Pipeline
- Schedule Databricks jobs after 23:05 UTC
- Use incremental loading based on filename
- Validate data quality after import

### 5. Error Handling
- Set up email notifications for failures
- Monitor Azure Logic App metrics
- Keep export files for debugging

## Customization

### Change Export Format to CSV

Replace the "Create_Parquet_File_Content" action with:
```json
{
  "type": "Compose",
  "inputs": "@join(
    concat(
      array('Date,EmployeeID,EmployeeName,AssignedOffice,ActualOffice,AttendanceStatus'),
      split(
        replace(
          replace(string(body('Get_Todays_Attendance_Records')?['value']), '[{', ''),
          '}]', ''
        ),
        '},{'
      )
    ),
    '\n'
  )"
}
```

### Add Email Notification

Add after "Log_Reset_Completion":
```json
{
  "Send_Completion_Email": {
    "type": "ApiConnection",
    "inputs": {
      "host": {
        "connection": {
          "name": "@parameters('$connections')['office365']['connectionId']"
        }
      },
      "method": "post",
      "path": "/v2/Mail",
      "body": {
        "To": "admin@company.com",
        "Subject": "Daily Attendance Export Complete - @{variables('ExportDate')}",
        "Body": "Export and reset completed successfully.\n\nRecords Exported: @{length(body('Get_Todays_Attendance_Records')?['value'])}\nRecords Created for Tomorrow: @{length(body('Get_Active_Employees_For_Reset')?['value'])}"
      }
    }
  }
}
```

## Troubleshooting

### No Records Created for Next Day
- Verify employees have CurrentStatus = "Active"
- Check EmployeeMaster list has employees
- Review Logic App run details for errors

### Export File Empty
- Ensure records exist with today's date
- Check OData filter in workflow
- Verify date format matches SharePoint

### Reset Takes Too Long
- Reduce concurrency if timeouts occur
- Consider batching for very large lists (1000+ employees)
- Check SharePoint throttling limits

## Support

For issues with the export-reset workflow:
1. Check Logic App run history for error details
2. Verify SharePoint permissions
3. Review export folder path configuration
4. Consult Azure Logic Apps documentation
