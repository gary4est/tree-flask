#!/bin/bash

# Script to check the status of test-app in AKS
# Usage: ./check_test_app_status.sh

set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print messages with timestamp
log() {
    local level=$1
    local message=$2
    local color=$NC
    
    case $level in
        "INFO") color=$BLUE ;;
        "SUCCESS") color=$GREEN ;;
        "WARNING") color=$YELLOW ;;
        "ERROR") color=$RED ;;
    esac
    
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message${NC}"
}

log "INFO" "Checking status of miq-test-app application..."

# Define namespace and app name
NAMESPACE="miq-test-app"
APP_NAME="miq-test-app"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    log "ERROR" "kubectl is not installed. Please install it first."
    exit 1
fi

# Check if connected to the right cluster
log "INFO" "Current Kubernetes context:"
current_context=$(kubectl config current-context)
echo -e "${BLUE}$current_context${NC}"

# Check HelmRelease status
log "INFO" "Checking HelmRelease status..."
echo -e "\n${BLUE}=== HelmRelease Status ===${NC}"
helm_release=$(kubectl get helmrelease "$APP_NAME" -n "$NAMESPACE" -o wide 2>/dev/null)
if [ $? -eq 0 ]; then
    # Get the Ready status
    ready_status=$(echo "$helm_release" | awk 'NR>1 {print $3}')
    status_message=$(echo "$helm_release" | awk 'NR>1 {$1=$2=$3=""; print $0}' | xargs)
    
    # Print with header row
    echo -e "$(echo "$helm_release" | awk 'NR==1 {print $0}')"
    
    # Print with colored status
    if [[ "$ready_status" == "True" ]]; then
        echo -e "$(echo "$helm_release" | awk -v green="${GREEN}" -v nc="${NC}" 'NR>1 {$3=green$3nc; print $0}')"
        log "SUCCESS" "HelmRelease is ready and healthy."
    else
        echo -e "$(echo "$helm_release" | awk -v red="${RED}" -v nc="${NC}" 'NR>1 {$3=red$3nc; print $0}')"
        log "WARNING" "HelmRelease is not ready: $status_message"
    fi
else
    log "ERROR" "HelmRelease $APP_NAME not found in namespace $NAMESPACE"
fi

# Try both with and without label filtering for pods
log "INFO" "Checking pod status..."
echo -e "\n${BLUE}=== Pod Status ===${NC}"
PODS_WITH_LABEL=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name="$APP_NAME" -o name 2>/dev/null | wc -l)
if [ "$PODS_WITH_LABEL" -gt 0 ]; then
    pod_output=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name="$APP_NAME" -o wide)
    
    # Print header
    echo -e "$(echo "$pod_output" | awk 'NR==1 {print $0}')"
    
    # Check and color status column
    echo "$pod_output" | awk -v green="${GREEN}" -v yellow="${YELLOW}" -v red="${RED}" -v nc="${NC}" 'NR>1 {
        if ($3 == "Running") {
            $3 = green $3 nc;
        } else if ($3 == "Pending" || $3 == "ContainerCreating") {
            $3 = yellow $3 nc;
        } else {
            $3 = red $3 nc;
        }
        print $0
    }'
    
    # Count running pods
    RUNNING_PODS=$(echo "$pod_output" | grep -c "Running")
    if [ "$RUNNING_PODS" -gt 0 ]; then
        log "SUCCESS" "Found $RUNNING_PODS running pods for $APP_NAME"
    else
        log "WARNING" "No running pods found for $APP_NAME"
    fi
else
    log "WARNING" "No pods found with label app.kubernetes.io/name=$APP_NAME, showing all pods"
    pod_output=$(kubectl get pods -n "$NAMESPACE" -o wide)
    
    # Print header
    echo -e "$(echo "$pod_output" | awk 'NR==1 {print $0}')"
    
    # Check and color status column
    echo "$pod_output" | awk -v green="${GREEN}" -v yellow="${YELLOW}" -v red="${RED}" -v nc="${NC}" 'NR>1 {
        if ($3 == "Running") {
            $3 = green $3 nc;
        } else if ($3 == "Pending" || $3 == "ContainerCreating") {
            $3 = yellow $3 nc;
        } else {
            $3 = red $3 nc;
        }
        print $0
    }'
    
    # Count running pods
    RUNNING_PODS=$(echo "$pod_output" | grep -c "Running")
    if [ "$RUNNING_PODS" -gt 0 ]; then
        log "SUCCESS" "Found $RUNNING_PODS running pods in namespace $NAMESPACE"
    else
        log "WARNING" "No running pods found in namespace $NAMESPACE"
    fi
fi

# Try both with and without label filtering for deployments
log "INFO" "Checking deployment status..."
echo -e "\n${BLUE}=== Deployment Status ===${NC}"
DEPLOYMENTS_WITH_LABEL=$(kubectl get deployment -n "$NAMESPACE" -l app.kubernetes.io/name="$APP_NAME" -o name 2>/dev/null | wc -l)
if [ "$DEPLOYMENTS_WITH_LABEL" -gt 0 ]; then
    deployment_output=$(kubectl get deployment -n "$NAMESPACE" -l app.kubernetes.io/name="$APP_NAME" -o wide)
    
    # Print header
    echo -e "$(echo "$deployment_output" | awk 'NR==1 {print $0}')"
    
    # Print with colored status based on READY column
    echo "$deployment_output" | awk -v green="${GREEN}" -v red="${RED}" -v nc="${NC}" 'NR>1 {
        split($2, ready, "/");
        if (ready[1] == ready[2]) {
            $2 = green $2 nc;
        } else {
            $2 = red $2 nc;
        }
        print $0
    }'
    
    # Check for deployment readiness
    READY_DEPLOYMENTS=$(echo "$deployment_output" | awk 'NR>1 {split($2, ready, "/"); if (ready[1] == ready[2]) print $0}' | wc -l)
    if [ "$READY_DEPLOYMENTS" -gt 0 ]; then
        log "SUCCESS" "All deployments are ready"
    else
        log "WARNING" "Some deployments are not ready"
    fi
else
    log "WARNING" "No deployments found with label app.kubernetes.io/name=$APP_NAME, showing all deployments"
    deployment_output=$(kubectl get deployment -n "$NAMESPACE" -o wide)
    
    # Print header
    echo -e "$(echo "$deployment_output" | awk 'NR==1 {print $0}')"
    
    # Print with colored status based on READY column
    echo "$deployment_output" | awk -v green="${GREEN}" -v red="${RED}" -v nc="${NC}" 'NR>1 {
        split($2, ready, "/");
        if (ready[1] == ready[2]) {
            $2 = green $2 nc;
        } else {
            $2 = red $2 nc;
        }
        print $0
    }'
    
    # Check for deployment readiness
    READY_DEPLOYMENTS=$(echo "$deployment_output" | awk 'NR>1 {split($2, ready, "/"); if (ready[1] == ready[2]) print $0}' | wc -l)
    if [ "$READY_DEPLOYMENTS" -gt 0 ]; then
        log "SUCCESS" "Found $READY_DEPLOYMENTS ready deployments"
    else
        log "WARNING" "No ready deployments found"
    fi
fi

# Try both with and without label filtering for services
log "INFO" "Checking service status..."
echo -e "\n${BLUE}=== Service Status ===${NC}"
SERVICES_WITH_LABEL=$(kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/name="$APP_NAME" -o name 2>/dev/null | wc -l)
if [ "$SERVICES_WITH_LABEL" -gt 0 ]; then
    service_output=$(kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/name="$APP_NAME" -o wide)
    echo "$service_output"
    log "SUCCESS" "Found services for $APP_NAME"
else
    log "WARNING" "No services found with label app.kubernetes.io/name=$APP_NAME, showing all services"
    kubectl get svc -n "$NAMESPACE" -o wide
fi

# Try both with and without label filtering for ingress
log "INFO" "Checking ingress status..."
echo -e "\n${BLUE}=== Ingress Status ===${NC}"
INGRESS_WITH_LABEL=$(kubectl get ingress -n "$NAMESPACE" -l app.kubernetes.io/name="$APP_NAME" -o name 2>/dev/null | wc -l)
if [ "$INGRESS_WITH_LABEL" -gt 0 ]; then
    kubectl get ingress -n "$NAMESPACE" -l app.kubernetes.io/name="$APP_NAME" -o wide
    log "SUCCESS" "Found ingress for $APP_NAME"
else
    log "WARNING" "No ingress found with label app.kubernetes.io/name=$APP_NAME, showing all ingress"
    kubectl get ingress -n "$NAMESPACE" -o wide
fi

# Check HPA status
log "INFO" "Checking HPA status..."
echo -e "\n${BLUE}=== HPA Status ===${NC}"
hpa_output=$(kubectl get hpa -n "$NAMESPACE" -o wide 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$hpa_output" ]; then
    echo "$hpa_output"
    log "SUCCESS" "Found HPA resources"
else
    log "INFO" "No HPA resources found in namespace $NAMESPACE"
fi

# Check latest events
log "INFO" "Checking latest events..."
echo -e "\n${BLUE}=== Latest Events ===${NC}"
EVENT_COUNT=$(kubectl get events -n "$NAMESPACE" --sort-by=.metadata.creationTimestamp | wc -l)
if [ "$EVENT_COUNT" -gt 1 ]; then
    events_output=$(kubectl get events -n "$NAMESPACE" --sort-by=.metadata.creationTimestamp | tail -10)
    echo "$events_output" | awk -v blue="${BLUE}" -v green="${GREEN}" -v yellow="${YELLOW}" -v red="${RED}" -v nc="${NC}" '{
        if ($3 == "Normal") {
            $3 = green $3 nc;
        } else if ($3 == "Warning") {
            $3 = red $3 nc;
        }
        print $0
    }'
    
    # Check for warning events
    WARNING_EVENTS=$(echo "$events_output" | grep -c "Warning")
    if [ "$WARNING_EVENTS" -gt 0 ]; then
        log "WARNING" "Found $WARNING_EVENTS warning events"
    else
        log "SUCCESS" "No warning events found"
    fi
else
    log "INFO" "No events found in namespace $NAMESPACE"
fi

# Check pod resource requests and limits
log "INFO" "Checking pod resource requests and limits..."
echo -e "\n${BLUE}=== Pod Resource Requests and Limits ===${NC}"
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name="$APP_NAME" -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    resource_info=$(kubectl describe pod "$POD_NAME" -n "$NAMESPACE" | grep -A5 "Limits:" | grep -A5 "Requests:")
    echo -e "${YELLOW}$resource_info${NC}"
    log "SUCCESS" "Resource limits and requests found for pod $POD_NAME"
else
    # Try to find any pod in the namespace if the label selector doesn't work
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
    if [ -n "$POD_NAME" ]; then
        resource_info=$(kubectl describe pod "$POD_NAME" -n "$NAMESPACE" | grep -A5 "Limits:" | grep -A5 "Requests:")
        echo -e "${YELLOW}$resource_info${NC}"
        log "SUCCESS" "Resource limits and requests found for pod $POD_NAME"
    else
        log "WARNING" "No pods found in namespace $NAMESPACE"
    fi
fi

# Check pod logs if available
log "INFO" "Checking latest pod logs..."
echo -e "\n${BLUE}=== Latest Pod Logs ===${NC}"
if [ -n "$POD_NAME" ]; then
    log_output=$(kubectl logs "$POD_NAME" -n "$NAMESPACE" --tail=20)
    echo -e "${YELLOW}$log_output${NC}"
    log "SUCCESS" "Retrieved logs from pod $POD_NAME"
else
    log "WARNING" "No pods found for $APP_NAME"
fi

# Check application health endpoint
log "INFO" "Checking application health from external endpoint..."
echo -e "\n${BLUE}=== Application Health Check (External) ===${NC}"
INGRESS_HOST="test-app.internal.staging.mileiq.dev"
echo "Attempting to check health endpoint at $INGRESS_HOST/health"
if command -v curl &> /dev/null; then
    HEALTH_STATUS=$(curl -sSL --connect-timeout 5 -o /dev/null -w "%{http_code}" "https://$INGRESS_HOST/health" 2>/dev/null || echo "Failed")
    if [ "$HEALTH_STATUS" = "200" ]; then
        echo -e "${GREEN}✅ External health check successful (HTTP $HEALTH_STATUS)${NC}"
        health_content=$(curl -sSL "https://$INGRESS_HOST/health")
        echo -e "${GREEN}$health_content${NC}"
        log "SUCCESS" "External health check passed with HTTP $HEALTH_STATUS"
    else
        echo -e "${RED}❌ External health check failed (HTTP $HEALTH_STATUS)${NC}"
        log "WARNING" "External health check failed with HTTP $HEALTH_STATUS"
    fi
else
    log "WARNING" "curl not found, skipping external health check"
fi

# Check the health through kubectl port-forward instead of exec
log "INFO" "Checking application health directly from pod..."
echo -e "\n${BLUE}=== Pod Health Check (Direct) ===${NC}"
if [ -n "$POD_NAME" ]; then
    log "INFO" "Using port-forward to check pod health..."
    # Start port-forward in the background
    kubectl port-forward "$POD_NAME" -n "$NAMESPACE" 8081:8080 &>/dev/null &
    PORT_FORWARD_PID=$!
    # Give it a second to establish the connection
    sleep 2
    # Check the health endpoint
    if command -v curl &> /dev/null; then
        LOCAL_HEALTH_STATUS=$(curl -sSL --connect-timeout 5 -o /dev/null -w "%{http_code}" "http://localhost:8081/health" 2>/dev/null || echo "Failed")
        if [ "$LOCAL_HEALTH_STATUS" = "200" ]; then
            echo -e "${GREEN}✅ Pod health check successful (HTTP $LOCAL_HEALTH_STATUS)${NC}"
            pod_health_content=$(curl -sSL "http://localhost:8081/health")
            echo -e "${GREEN}$pod_health_content${NC}"
            log "SUCCESS" "Pod health check passed with HTTP $LOCAL_HEALTH_STATUS"
        else
            echo -e "${RED}❌ Pod health check failed (HTTP $LOCAL_HEALTH_STATUS)${NC}"
            log "WARNING" "Pod health check failed with HTTP $LOCAL_HEALTH_STATUS"
        fi
    else
        log "WARNING" "curl not found, skipping pod health check"
    fi
    # Kill the port-forward process
    kill $PORT_FORWARD_PID 2>/dev/null || true
else
    log "WARNING" "No pods available for health check"
fi

# Print troubleshooting suggestions
echo -e "\n${BLUE}=== Troubleshooting Tips ===${NC}"
echo -e "${YELLOW}If resources are missing, check:${NC}"
echo -e "1. That the HelmRelease values are properly configured"
echo -e "2. If resource labels match what the script is searching for"
echo -e "3. If HPA warnings appear, verify CPU/memory requests are set in the deployment"

# Print summary status
echo -e "\n${BLUE}============================================================${NC}"
echo -e "${BLUE}                  Status Summary                           ${NC}"
echo -e "${BLUE}============================================================${NC}"

# Count success and warnings
SUCCESS_COUNT=$(grep -c "SUCCESS" <<< "$(echo "${PIPESTATUS[@]}")")
WARNING_COUNT=$(grep -c "WARNING" <<< "$(echo "${PIPESTATUS[@]}")")
ERROR_COUNT=$(grep -c "ERROR" <<< "$(echo "${PIPESTATUS[@]}")")

if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "${RED}Found $ERROR_COUNT errors that require attention${NC}"
fi

if [ $WARNING_COUNT -gt 0 ]; then
    echo -e "${YELLOW}Found $WARNING_COUNT warnings that may need investigation${NC}"
fi

if [ $ERROR_COUNT -eq 0 ] && [ $WARNING_COUNT -eq 0 ]; then
    echo -e "${GREEN}All checks passed successfully!${NC}"
fi

log "INFO" "Status check completed."
echo -e "${BLUE}============================================================${NC}" 