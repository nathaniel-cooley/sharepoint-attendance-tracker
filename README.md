# SharePoint Attendance Tracker

An automated attendance tracking system built on SharePoint Online with Azure Logic Apps integration. This solution handles multi-office employee attendance tracking, including temporary and permanent office transfers.

## Overview

The SharePoint Attendance Tracker automates the daily generation of attendance records for employees across multiple office locations. It integrates with Azure Logic Apps to handle complex workflows including office transfers, daily attendance generation, and automated status updates.

## Key Features

- **Automated Daily Attendance Generation**: Logic App runs daily at midnight UTC to create attendance records
- **Multi-Office Support**: Track employees across multiple office locations (Office A, B, C, D, and Remote)
- **Office Transfer Management**: Handle both temporary and permanent office assignments
- **Employee Master Data**: Centralized employee information with primary office assignments
- **Status Tracking**: Comprehensive attendance status options (Present, Absent, On Leave, Work From Home)
- **Automated Workflows**: Auto-update transfer statuses and expired transfers
- **Error Handling**: Built-in retry mechanisms and error logging
- **Audit Trail**: Track who recorded attendance and when

## System Architecture

### SharePoint Lists

1. **EmployeeMaster**: Stores employee details and primary office assignments
   - EmployeeID, EmployeeName, PrimaryOffice, CurrentStatus
   - Department, EmailAddress

2. **DailyAttendance**: Daily attendance records (auto-generated)
   - Date, EmployeeID, EmployeeName
   - AssignedOffice, ActualOffice
   - AttendanceStatus, RecordedBy, RecordedDateTime
   - Notes

3. **OfficeTransfers**: Tracks temporary and permanent office assignments
   - EmployeeID, EmployeeName
   - FromOffice, ToOffice
   - StartDate, EndDate
   - TransferType, TransferStatus
   - ApprovedBy, ApprovalDate, Reason

### Azure Logic App Workflows

#### Main Workflow (workflow.json)
Runs daily at midnight UTC to generate attendance records with transfer-aware office assignments:

1. **Initialize Variables**: Set up date and error tracking
2. **Retrieve Active Employees**: Get all employees with "Active" status
3. **Check Active Transfers**: Find current office transfers
4. **Determine Assigned Office**: Apply transfers or use primary office
5. **Create Attendance Records**: Generate daily records for all active employees
6. **Handle Errors**: Log and report any failures
7. **Update Expired Transfers**: Automatically complete past-due transfers

#### Export-Reset Workflow (export-reset-workflow.json)
Runs daily at 11 PM UTC for analytics integration and daily reset:

1. **Export to Parquet**: Export day's attendance data to Parquet file for Databricks
2. **Reset List**: Delete all attendance records from SharePoint
3. **Create Fresh Records**: Generate new records for next day with primary office assignments
4. **Enable Manager Workflow**: Allows managers to assign offices, secondary offices to mark attendance

## Quick Start

### Prerequisites

- Azure subscription with Logic Apps access
- SharePoint Online site (Office 365)
- Site Collection Administrator or Owner permissions
- Azure PowerShell module (or use Azure Cloud Shell)

### Installation

1. **Clone this repository**:
   ```bash
   git clone https://github.com/nathaniel-cooley/sharepoint-attendance-tracker.git
   cd sharepoint-attendance-tracker
   ```

2. **Create SharePoint Lists**:
   - Follow the schema in `sharepoint/lists/schemas.json`
   - Create three lists: EmployeeMaster, DailyAttendance, OfficeTransfers
   - Configure columns as specified

3. **Deploy Azure Logic App**:
   ```powershell
   cd scripts
   .\setup-connection.ps1 `
       -ResourceGroupName "rg-attendance-tracker" `
       -Location "eastus" `
       -LogicAppName "la-attendance-tracker" `
       -SharePointSiteUrl "https://yourtenant.sharepoint.com/sites/AttendanceTracking"
   ```

4. **Authorize SharePoint Connection**:
   - Navigate to Azure Portal
   - Find the API connection resource
   - Click "Edit API connection"
   - Click "Authorize" and sign in

5. **Populate Employee Data**:
   - Add employees to EmployeeMaster list
   - Set CurrentStatus to "Active" for active employees

6. **Test the System**:
   - Manually trigger the Logic App
   - Verify attendance records are created
   - Check for any errors in run history

For detailed setup instructions, see [Setup Guide](docs/setup-guide.md).

### Optional: Deploy Export-Reset Workflow

For analytics integration (Databricks) with daily reset cycle:

1. **Create SharePoint Document Library**:
   - Name: `AttendanceExports`
   - For storing daily Parquet exports

2. **Deploy Export-Reset Logic App**:
   ```powershell
   cd scripts
   .\setup-export-reset-workflow.ps1 `
       -ResourceGroupName "rg-attendance-tracker" `
       -Location "eastus" `
       -LogicAppName "la-attendance-export-reset" `
       -SharePointSiteUrl "https://yourtenant.sharepoint.com/sites/AttendanceTracking" `
       -ExportFolderPath "/AttendanceExports"
   ```

3. **Authorize Connection** (same as main workflow)

For detailed instructions, see [Export-Reset Guide](docs/export-reset-guide.md).

## Documentation

- **[Setup Guide](docs/setup-guide.md)**: Comprehensive installation and configuration instructions
- **[User Guide](docs/user-guide.md)**: Daily operations, managing employees, transfers, and reporting
- **[Export-Reset Guide](docs/export-reset-guide.md)**: Analytics integration with daily export and reset cycle

## Project Structure

```
sharepoint-attendance-tracker/
├── logic-app/
│   ├── workflow.json                    # Main workflow (transfer-aware)
│   └── export-reset-workflow.json       # Export/reset workflow (analytics)
├── sharepoint/
│   └── lists/
│       └── schemas.json                 # SharePoint list schemas
├── scripts/
│   ├── setup-connection.ps1             # Deploy main workflow
│   └── setup-export-reset-workflow.ps1  # Deploy export-reset workflow
├── docs/
│   ├── setup-guide.md                   # Installation guide
│   ├── user-guide.md                    # User documentation
│   └── export-reset-guide.md            # Export-reset workflow guide
├── .gitignore
└── README.md
```

## Workflow Details

### Daily Attendance Generation Flow

```mermaid
graph TD
    A[Trigger: Daily at Midnight UTC] --> B[Get Active Employees]
    B --> C[Get Active Transfers]
    C --> D[For Each Employee]
    D --> E{Has Active Transfer?}
    E -->|Yes| F[Assign Transfer Office]
    E -->|No| G[Assign Primary Office]
    F --> H[Create Attendance Record]
    G --> H
    H --> I{Success?}
    I -->|Yes| J[Next Employee]
    I -->|No| K[Log Error]
    K --> J
    J --> L{More Employees?}
    L -->|Yes| D
    L -->|No| M[Update Expired Transfers]
    M --> N[Send Notification]
```

### Office Transfer Logic

- **Active Transfer Check**: Looks for transfers with status "Active" where:
  - StartDate ≤ Current Date
  - EndDate ≥ Current Date OR EndDate is null
- **Assignment Priority**: Active transfers override primary office assignment
- **Automatic Completion**: Transfers past their EndDate are marked as "Completed"

## Workflow Comparison

### Choose the Right Workflow for Your Needs

| Feature | Main Workflow | Export-Reset Workflow |
|---------|--------------|----------------------|
| **Purpose** | Automatic transfer handling | Analytics integration with daily reset |
| **Schedule** | Midnight (00:00 UTC) | Night (23:00 UTC) |
| **Creates Records** | With transfer-aware assignments | With primary office only |
| **Data Retention** | Keeps all historical records | Exports then deletes daily |
| **Office Assignment** | Automatic based on transfers | Manual by managers |
| **Best For** | Automated attendance tracking | Databricks/analytics pipelines |
| **Export Format** | N/A | Parquet files |
| **Reset Capability** | No | Yes - daily cleanup |

**Use Main Workflow when:**
- You want automatic office assignment based on transfers
- You need historical data in SharePoint
- Transfers are managed through the OfficeTransfers list

**Use Export-Reset Workflow when:**
- You need daily data export for analytics (Databricks)
- Managers manually assign offices each day
- You want a clean slate daily with primary office assignments
- You need Parquet files for data lake/warehouse

**Use Both Workflows when:**
- You want both automatic and manual workflows
- Run them at different times (e.g., main at 00:00, export-reset at 23:00)
- Use separate SharePoint lists or sites

## Configuration

### Schedule Customization

Edit the `Daily_Schedule` trigger in `logic-app/workflow.json`:

```json
"recurrence": {
  "frequency": "Day",
  "interval": 1,
  "schedule": {
    "hours": ["0"],
    "minutes": [0]
  },
  "timeZone": "UTC"
}
```

### Office Names

Update office choices in both:
- SharePoint list column settings
- Logic App workflow definition

### Concurrency Settings

Adjust parallel processing in workflow:
```json
"runtimeConfiguration": {
  "concurrency": {
    "repetitions": 20
  }
}
```

## Monitoring and Maintenance

### Azure Portal Monitoring

- **Run History**: View all Logic App executions
- **Run Details**: See step-by-step execution for debugging
- **Metrics**: Monitor performance and errors
- **Diagnostic Logs**: Enable for detailed troubleshooting

### SharePoint List Maintenance

- **Regular Cleanup**: Archive old attendance records (monthly/quarterly)
- **Employee Updates**: Keep EmployeeMaster current
- **Transfer Auditing**: Review completed transfers periodically

## Troubleshooting

| Issue | Possible Cause | Solution |
|-------|----------------|----------|
| No attendance records | Inactive employees | Verify CurrentStatus = "Active" |
| Wrong office assignment | Transfer not active | Check TransferStatus and dates |
| Duplicate records | Multiple runs | Check Logic App schedule |
| Connection errors | Authorization expired | Re-authorize SharePoint connection |

See [User Guide](docs/user-guide.md#troubleshooting) for more details.

## Security Considerations

- **Access Control**: Use least-privilege principle for service accounts
- **Data Protection**: Implement retention policies for attendance data
- **Audit Trail**: System tracks all record modifications
- **Secure Connections**: API connections use OAuth 2.0 authentication

## Limitations

- Maximum 5,000 items per SharePoint list view (use pagination for larger datasets)
- Logic App timeout: 30 days for workflow runs
- SharePoint API throttling limits apply
- Concurrency limited to 50 parallel actions per workflow

## Future Enhancements

Potential improvements for future versions:
- Email notifications for managers
- Power BI dashboard integration
- Mobile app for attendance marking
- Integration with HR systems
- Automatic leave management
- Biometric integration support
- Advanced reporting and analytics

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

For issues or questions:
- **Technical Issues**: Review Azure Logic App run history
- **Setup Help**: See [Setup Guide](docs/setup-guide.md)
- **Usage Help**: See [User Guide](docs/user-guide.md)
- **Bugs**: Open an issue on GitHub

## License

This project is provided as-is for educational and demonstration purposes.

## Acknowledgments

Built with:
- Azure Logic Apps
- SharePoint Online
- PowerShell
- Azure Resource Manager

---

**Note**: This is a template solution. Customize office names, workflows, and business logic to match your organization's requirements.
