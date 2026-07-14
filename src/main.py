import os
import time
import functions_framework
from google.cloud import billing_v1
from google.cloud import monitoring_v3

@functions_framework.http
def main(request):
    # 1. Fetch Environment Variables set by Terraform
    project_id = os.environ.get("PROJECT_ID")
    billing_account_id = os.environ.get("BILLING_ACCOUNT_ID")
    
    if not project_id or not billing_account_id:
        return "Missing configuration variables.", 500

    # Format the billing account path required by the GCP client library
    billing_account_name = f"billingAccounts/{billing_account_id}"

    try:
        # 2. Authenticate and query the GCP Billing API
        billing_client = billing_v1.CloudBillingClient()
        
        # Note: In a personal account with standard billing permissions,
        # we can retrieve standard billing account metadata.
        billing_info = billing_client.get_billing_account(name=billing_account_name)
        
        # FOR TESTING & PORTFOLIO LOGGING: 
        # Since exact real-time programmatic cost queries require bigquery billing export,
        # we will generate a baseline dummy cost metric for demonstration purposes if BQ isn't active,
        # or calculate it via custom queries. For now, we simulate a mock daily spend to populate Grafana safely.
        current_spend = 0.02  # Hardcoded $0.02 base to guarantee Grafana displays chart data for free tier

        # 3. Create a Time Series Metric for Cloud Monitoring
        metric_client = monitoring_v3.MetricServiceClient()
        project_name = f"projects/{project_id}"

        series = monitoring_v3.TimeSeries()
        series.metric.type = "://googleapis.com"
        series.resource.type = "global"

        # Define the data point
        point = monitoring_v3.Point()
        point.value.double_value = current_spend
        
        # Assign timestamp
        now = time.time()
        seconds = int(now)
        nanoseconds = int((now - seconds) * 10**9)
        point.interval.end_time.seconds = seconds
        point.interval.end_time.nanoseconds = nanoseconds

        series.points = [point]

        # 4. Push metric data to Google Cloud Monitoring
        metric_client.create_time_series(name=project_name, time_series=[series])
        print(f"Successfully exported custom cost metric: ${current_spend} to Cloud Monitoring.")
        
        return f"Metric successfully pushed: ${current_spend}", 200

    except Exception as e:
        print(f"Error executing cost monitor: {str(e)}")
        return f"Internal Error: {str(e)}", 500
