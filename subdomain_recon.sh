#!/bin/bash

# =============================================================================
# COMPREHENSIVE SUBDOMAIN RECONNAISSANCE
# Target: uonbi.ac.ke (All admin-level subdomains)
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Define all discovered subdomains
SUBDOMAINS=(
    "halls.uonbi.ac.ke"      # Main - Recon complete
    "swa.uonbi.ac.ke"        # Student Welfare - Admin
    "hamis.uonbi.ac.ke"      # Hostel Management - Admin
    "www.uonbi.ac.ke"        # Main University
    "portal.uonbi.ac.ke"     # Portal - Potential Admin
    "staff.uonbi.ac.ke"      # Staff Portal
    "student.uonbi.ac.ke"    # Student Portal
    "admin.uonbi.ac.ke"      # Admin Panel
)

# Output directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="subdomain_recon_${TIMESTAMP}"
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          SUBDOMAIN RECONNAISSANCE                             ║"
echo "║          Target: uonbi.ac.ke                                  ║"
echo "║          Started: $(date)                                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to check subdomain
check_subdomain() {
    local subdomain=$1
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[*] Checking: $subdomain${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Create subdomain directory
    SUB_DIR="$OUTPUT_DIR/${subdomain}"
    mkdir -p "$SUB_DIR"
    
    # DNS Resolution
    echo -e "${GREEN}[+] DNS Resolution:${NC}"
    host "$subdomain" 2>/dev/null | tee "$SUB_DIR/dns.txt"
    echo ""
    
    # Ping test
    echo -e "${GREEN}[+] Ping Test:${NC}"
    ping -c 2 "$subdomain" 2>/dev/null | tee "$SUB_DIR/ping.txt"
    echo ""
    
    # HTTP/HTTPS Check
    echo -e "${GREEN}[+] HTTP/HTTPS Status:${NC}"
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$subdomain" 2>/dev/null)
    HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$subdomain" 2>/dev/null)
    echo "    HTTP:  $HTTP_STATUS"
    echo "    HTTPS: $HTTPS_STATUS"
    
    # Capture headers
    echo -e "${GREEN}[+] HTTP Headers:${NC}"
    curl -s -I -k "https://$subdomain" 2>/dev/null | tee "$SUB_DIR/headers.txt"
    echo ""
    
    # Check for common admin paths
    echo -e "${GREEN}[+] Checking Common Admin Paths:${NC}"
    ADMIN_PATHS=("admin" "login" "dashboard" "manage" "administrator" "cpanel" "webmail")
    for path in "${ADMIN_PATHS[@]}"; do
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$subdomain/$path" 2>/dev/null)
        if [ "$STATUS" != "404" ] && [ "$STATUS" != "000" ]; then
            echo -e "    ${GREEN}✓${NC} /$path -> Status: $STATUS"
        fi
    done
    
    # Technology fingerprinting
    echo -e "${GREEN}[+] Technology Stack:${NC}"
    whatweb "https://$subdomain" 2>/dev/null | tee "$SUB_DIR/whatweb.txt"
    
    # Capture homepage
    echo -e "${GREEN}[+] Capturing Homepage:${NC}"
    curl -s -L -k "https://$subdomain" > "$SUB_DIR/homepage.html"
    echo "    Saved to: $SUB_DIR/homepage.html"
    
    # Extract emails
    echo -e "${GREEN}[+] Extracting Emails:${NC}"
    grep -E -o "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" "$SUB_DIR/homepage.html" 2>/dev/null | sort -u | tee "$SUB_DIR/emails.txt"
    
    # Check SSL Certificate
    echo -e "${GREEN}[+] SSL Certificate Info:${NC}"
    echo -e "Q" | openssl s_client -connect "$subdomain:443" -servername "$subdomain" 2>/dev/null | openssl x509 -noout -text 2>/dev/null | tee "$SUB_DIR/ssl.txt"
    
    # Check for security headers
    echo -e "${GREEN}[+] Security Headers:${NC}"
    for header in "X-Frame-Options" "X-XSS-Protection" "X-Content-Type-Options" "Content-Security-Policy" "Strict-Transport-Security"; do
        if grep -i "$header" "$SUB_DIR/headers.txt" &>/dev/null; then
            echo -e "    ${GREEN}✓${NC} $header present"
        else
            echo -e "    ${RED}✗${NC} $header missing"
        fi
    done
    
    # Quick nmap scan
    echo -e "${GREEN}[+] Port Scan (Top 100):${NC}"
    sudo nmap -T4 -F "$subdomain" 2>/dev/null | tee "$SUB_DIR/nmap.txt"
    
    echo -e "${GREEN}[+] Results saved to: $SUB_DIR${NC}"
}

# Check each subdomain
for sub in "${SUBDOMAINS[@]}"; do
    check_subdomain "$sub"
done

# Generate summary
echo -e "\n${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          SUBDOMAIN RECONNAISSANCE COMPLETE                     ║"
echo "║          Completed: $(date)                                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Summary report
SUMMARY="$OUTPUT_DIR/SUMMARY.txt"
{
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║          SUBDOMAIN RECONNAISSANCE SUMMARY                     ║"
    echo "║          Target: uonbi.ac.ke                                  ║"
    echo "║          Generated: $(date)                                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    for sub in "${SUBDOMAINS[@]}"; do
        SUB_DIR="$OUTPUT_DIR/${sub}"
        if [ -f "$SUB_DIR/headers.txt" ]; then
            HTTPS_STATUS=$(grep "HTTP/" "$SUB_DIR/headers.txt" | head -1 | awk '{print $2}')
            echo "=== $sub ==="
            echo "  HTTPS Status: $HTTPS_STATUS"
            echo "  Server: $(grep -i "Server:" "$SUB_DIR/headers.txt" | head -1)"
            echo "  CMS: $(grep -i "Generator" "$SUB_DIR/headers.txt" | head -1)"
            echo "  Emails Found: $(cat "$SUB_DIR/emails.txt" 2>/dev/null | wc -l)"
            echo ""
        else
            echo "=== $sub ==="
            echo "  Status: Unreachable"
            echo ""
        fi
    done
} > "$SUMMARY"

echo -e "${GREEN}[+] Summary saved to: $SUMMARY${NC}"
echo -e "${GREEN}[+] All results saved in: $OUTPUT_DIR${NC}"

# Display quick summary
echo -e "\n${CYAN}Quick Summary:${NC}"
cat "$SUMMARY"
