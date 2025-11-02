# SharePoint Attendance Tracker - Azure Logic App Setup Script
# This script sets up the SharePoint connection and deploys the Logic App

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$true)]
    [string]$LogicAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$SharePointSiteUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SharePoint Attendance Tracker Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Azure PowerShell module is installed
Write-Host "Checking Azure PowerShell module..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Host "Azure PowerShell module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
}

# Import required modules
Import-Module Az.Accounts
Import-Module Az.Resources
Import-Module Az.LogicApp

# Connect to Azure
Write-Host "Connecting to Azure..." -ForegroundColor Yellow
try {
    $context = Get-AzContext
    if (-not $context) {
        Connect-AzAccount
    }
    Write-Host "Connected to Azure subscription: $($context.Subscription.Name)" -ForegroundColor Green
} catch {
    Write-Host "Error connecting to Azure: $_" -ForegroundColor Red
    exit 1
}

# Set subscription if provided
if ($SubscriptionId) {
    Write-Host "Setting subscription context to: $SubscriptionId" -ForegroundColor Yellow
    Set-AzContext -SubscriptionId $SubscriptionId
}

# Create or verify resource group
Write-Host ""
Write-Host "Checking resource group: $ResourceGroupName" -ForegroundColor Yellow
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    Write-Host "Creating resource group: $ResourceGroupName in $Location" -ForegroundColor Yellow
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
    Write-Host "Resource group created successfully" -ForegroundColor Green
} else {
    Write-Host "Resource group already exists" -ForegroundColor Green
}

# Create SharePoint API Connection
Write-Host ""
Write-Host "Creating SharePoint API Connection..." -ForegroundColor Yellow
$connectionName = "$LogicAppName-sharepoint-connection"

$connectionProperties = @{
    api = @{
        id = "/subscriptions/$((Get-AzContext).Subscription.Id)/providers/Microsoft.Web/locations/$Location/managedApis/sharepointonline"
    }
    displayName = "SharePoint Connection for Attendance Tracker"
    parameterValues = @{}
}

try {
    # Check if connection already exists
    $existingConnection = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.Web/connections" -ResourceName $connectionName -ErrorAction SilentlyContinue
    
    if (-not $existingConnection) {
        New-AzResource -ResourceGroupName $ResourceGroupName `
            -ResourceType "Microsoft.Web/connections" `
            -ResourceName $connectionName `
            -Location $Location `
            -Properties $connectionProperties `
            -Force
        
        Write-Host "SharePoint connection created: $connectionName" -ForegroundColor Green
        Write-Host "IMPORTANT: You need to authorize this connection in the Azure Portal" -ForegroundColor Yellow
        Write-Host "Go to: Resource Groups > $ResourceGroupName > $connectionName > Edit API connection > Authorize" -ForegroundColor Yellow
    } else {
        Write-Host "SharePoint connection already exists: $connectionName" -ForegroundColor Green
    }
} catch {
    Write-Host "Error creating SharePoint connection: $_" -ForegroundColor Red
    Write-Host "You may need to create the connection manually in the Azure Portal" -ForegroundColor Yellow
}

# Read workflow definition
Write-Host ""
Write-Host "Reading Logic App workflow definition..." -ForegroundColor Yellow
$workflowPath = Join-Path $PSScriptRoot "..\logic-app\workflow.json"
if (-not (Test-Path $workflowPath)) {
    Write-Host "Error: Workflow file not found at $workflowPath" -ForegroundColor Red
    exit 1
}

$workflowDefinition = Get-Content $workflowPath -Raw | ConvertFrom-Json

# Update workflow parameters with SharePoint site URL
Write-Host "Configuring workflow parameters..." -ForegroundColor Yellow
if ($workflowDefinition.parameters -and $workflowDefinition.parameters.sharePointSiteUrl) {
    $workflowDefinition.parameters.sharePointSiteUrl.defaultValue = $SharePointSiteUrl
} else {
    Write-Host "Warning: Could not update SharePoint site URL in workflow definition" -ForegroundColor Yellow
}

# Get connection ID for the workflow
$connectionId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/connections/$connectionName"

# Create parameters for Logic App
$logicAppParameters = @{
    '$connections' = @{
        value = @{
            sharepointonline = @{
                connectionId = $connectionId
                connectionName = $connectionName
                id = "/subscriptions/$((Get-AzContext).Subscription.Id)/providers/Microsoft.Web/locations/$Location/managedApis/sharepointonline"
            }
        }
    }
    sharePointSiteUrl = @{
        value = $SharePointSiteUrl
    }
}

# Create or update Logic App
Write-Host ""
Write-Host "Deploying Logic App: $LogicAppName" -ForegroundColor Yellow

try {
    # Convert workflow definition back to JSON
    $workflowJson = $workflowDefinition | ConvertTo-Json -Depth 100
    
    # Create a temporary file for the workflow
    $tempWorkflowPath = [System.IO.Path]::GetTempFileName()
    $workflowJson | Out-File $tempWorkflowPath -Encoding UTF8
    
    # Deploy Logic App
    $logicApp = Set-AzLogicApp -ResourceGroupName $ResourceGroupName `
        -Name $LogicAppName `
        -Location $Location `
        -DefinitionFilePath $tempWorkflowPath `
        -Parameters $logicAppParameters `
        -State Enabled
    
    # Clean up temp file
    Remove-Item $tempWorkflowPath -Force
    
    Write-Host "Logic App deployed successfully!" -ForegroundColor Green
    Write-Host "Logic App Name: $LogicAppName" -ForegroundColor Cyan
    Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
    Write-Host "Location: $Location" -ForegroundColor Cyan
} catch {
    Write-Host "Error deploying Logic App: $_" -ForegroundColor Red
    exit 1
}

# Display next steps
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Authorize the SharePoint connection in Azure Portal:" -ForegroundColor White
Write-Host "   - Navigate to Resource Groups > $ResourceGroupName > $connectionName" -ForegroundColor Gray
Write-Host "   - Click 'Edit API connection'" -ForegroundColor Gray
Write-Host "   - Click 'Authorize' and sign in with SharePoint credentials" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Create the SharePoint lists using the schema in sharepoint/lists/schemas.json" -ForegroundColor White
Write-Host ""
Write-Host "3. Add employees to the EmployeeMaster list" -ForegroundColor White
Write-Host ""
Write-Host "4. The Logic App will run daily at midnight UTC to generate attendance records" -ForegroundColor White
Write-Host ""
Write-Host "5. Monitor the Logic App runs in Azure Portal:" -ForegroundColor White
Write-Host "   - Resource Groups > $ResourceGroupName > $LogicAppName > Runs history" -ForegroundColor Gray
Write-Host ""

# Output connection information
$output = @{
    ResourceGroupName = $ResourceGroupName
    LogicAppName = $LogicAppName
    ConnectionName = $connectionName
    SharePointSiteUrl = $SharePointSiteUrl
    Location = $Location
}

return $output
