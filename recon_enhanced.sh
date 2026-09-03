#!/bin/bash

# =============================================================================
# PHASE 1: RECONNAISSANCE - Enhanced Edition
# Target: halls.uonbi.ac.ke
# Login Page: https://halls.uonbi.ac.ke/user/login
# =============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Target Configuration
DOMAIN="halls.uonbi.ac.ke"
LOGIN_PATH="/user/login"
FULL_LOGIN_URL="https://${DOMAIN}${LOGIN_PATH}"
BASE_URL="https://${DOMAIN}"

# Output Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="recon_${DOMAIN}_${TIMESTAMP}"

# Create output directory
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/screenshots"
mkdir -p "$OUTPUT_DIR/headers"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          PHASE 1: ADVANCED RECONNAISSANCE                      ║"
echo "║          Target: $DOMAIN                                      ║"
echo "║          Login: $FULL_LOGIN_URL                              ║"
echo "║          Started: $(date)                                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# =============================================================================
# FUNCTION: Check if tool exists with installation guidance
# =============================================================================
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}[-] $1 is not installed.${NC}"
        echo -e "${YELLOW}[!] Install with:${NC}"
        case $1 in
            nmap) echo "    sudo apt-get install nmap" ;;
            whatweb) echo "    sudo apt-get install whatweb" ;;
            theHarvester) echo "    sudo apt-get install theharvester" ;;
            curl) echo "    sudo apt-get install curl" ;;
            openssl) echo "    sudo apt-get install openssl" ;;
            jq) echo "    sudo apt-get install jq" ;;
            wget) echo "    sudo apt-get install wget" ;;
            *) echo "    Please install $1 manually" ;;
        esac
        return 1
    fi
    return 0
}

# =============================================================================
# 1. INITIAL WEBSITE ANALYSIS
# =============================================================================
echo -e "\n${YELLOW}[1/7] Initial Website Analysis${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if website is accessible
echo -e "${GREEN}[+] Checking website availability...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL")
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FULL_LOGIN_URL")

echo -e "    Homepage Status: $HTTP_CODE"
echo -e "    Login Page Status: $HTTPS_CODE"

if [ "$HTTP_CODE" != "200" ] && [ "$HTTPS_CODE" != "200" ]; then
    echo -e "${RED}[!] Website appears to be down or unreachable${NC}"
    echo -e "${YELLOW}[!] Continuing with limited scanning...${NC}"
fi

# Capture homepage for analysis
echo -e "${GREEN}[+] Capturing homepage source...${NC}"
curl -s -L "$BASE_URL" > "$OUTPUT_DIR/homepage_source.html"
echo -e "${GREEN}[+] Homepage saved to: $OUTPUT_DIR/homepage_source.html${NC}"

# Capture login page specifically
echo -e "${GREEN}[+] Capturing login page source...${NC}"
curl -s -L "$FULL_LOGIN_URL" > "$OUTPUT_DIR/login_page_source.html"
echo -e "${GREEN}[+] Login page saved to: $OUTPUT_DIR/login_page_source.html${NC}"

# =============================================================================
# 2. NMAP SCAN (Full port and service detection)
# =============================================================================
echo -e "\n${YELLOW}[2/7] Comprehensive Nmap Scan${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check_tool nmap
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[+] Starting Nmap scan (this may take a few minutes)...${NC}"
    
    # Quick scan first
    echo -e "${CYAN}[*] Quick port scan...${NC}"
    nmap -T4 -F "$DOMAIN" > "$OUTPUT_DIR/nmap_quick.txt" 2>&1
    
    # Full scan with service detection
    echo -e "${CYAN}[*] Full service scan...${NC}"
    nmap -sV -sC -O -p- --min-rate=1000 -T4 "$DOMAIN" -oA "$OUTPUT_DIR/nmap_full" > "$OUTPUT_DIR/nmap_output.txt" 2>&1
    
    # Vulnerability scripts for common services
    echo -e "${CYAN}[*] Running vulnerability scripts...${NC}"
    nmap --script vuln -p 80,443,22,3306 "$DOMAIN" > "$OUTPUT_DIR/nmap_vuln.txt" 2>&1
    
    # Extract and display open ports
    echo -e "${GREEN}[+] Open ports discovered:${NC}"
    grep "open" "$OUTPUT_DIR/nmap_full.nmap" | grep -v "Discovered" | while read line; do
        echo -e "    ${MAGENTA}→${NC} $line"
    done
    
    # Save summary of services
    echo -e "${GREEN}[+] Service summary:${NC}"
    grep -E "(open|filtered)" "$OUTPUT_DIR/nmap_full.nmap" | grep -E "http|https|ssh|mysql" | while read line; do
        echo -e "    ${CYAN}•${NC} $line"
    done
    
    echo -e "${GREEN}[+] Full scan results saved to: $OUTPUT_DIR/nmap_full.nmap${NC}"
else
    echo -e "${RED}[-] Skipping Nmap scan${NC}"
fi

# =============================================================================
# 3. TECHNOLOGY STACK IDENTIFICATION
# =============================================================================
echo -e "\n${YELLOW}[3/7] Technology Stack Identification${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# HTTP Headers Analysis
echo -e "${GREEN}[+] Capturing HTTP headers...${NC}"
curl -s -I "$BASE_URL" > "$OUTPUT_DIR/headers_homepage.txt"
curl -s -I "$FULL_LOGIN_URL" > "$OUTPUT_DIR/headers_login.txt"

echo -e "${GREEN}[+] HTTP Headers (Login Page):${NC}"
cat "$OUTPUT_DIR/headers_login.txt" | while read line; do
    echo -e "    ${CYAN}→${NC} $line"
done

# Extract Server Information
echo -e "\n${GREEN}[+] Server Information:${NC}"
SERVER=$(grep -i "Server:" "$OUTPUT_DIR/headers_login.txt" | awk '{print $2}')
echo -e "    Server: ${MAGENTA}${SERVER:-Unknown}${NC}"

# Check for Drupal indicators
echo -e "${GREEN}[+] Checking for CMS indicators...${NC}"

# Look for Drupal specific patterns in source
echo -e "${CYAN}[*] Scanning for Drupal signatures...${NC}"
grep -i "drupal" "$OUTPUT_DIR/homepage_source.html" > "$OUTPUT_DIR/drupal_signatures.txt"
grep -i "Drupal" "$OUTPUT_DIR/login_page_source.html" >> "$OUTPUT_DIR/drupal_signatures.txt"

if [ -s "$OUTPUT_DIR/drupal_signatures.txt" ]; then
    echo -e "    ${GREEN}✓${NC} Drupal CMS detected!"
    echo -e "    ${CYAN}Drupal signatures found:${NC}"
    head -5 "$OUTPUT_DIR/drupal_signatures.txt" | while read line; do
        echo -e "        → $line"
    done
    DRUPAL_DETECTED=true
else
    echo -e "    ${YELLOW}!${NC} No clear Drupal signatures found in source"
    DRUPAL_DETECTED=false
fi

# Use whatweb for detailed fingerprinting
if command -v whatweb &> /dev/null; then
    echo -e "${GREEN}[+] Running whatweb fingerprinting...${NC}"
    whatweb -a 3 "$BASE_URL" | tee "$OUTPUT_DIR/whatweb_homepage.txt"
    whatweb -a 3 "$FULL_LOGIN_URL" | tee "$OUTPUT_DIR/whatweb_login.txt"
    
    echo -e "${GREEN}[+] Technology Summary:${NC}"
    cat "$OUTPUT_DIR/whatweb_homepage.txt" | grep -E "(WordPress|Drupal|Joomla|PHP|Node\.js|Ruby|Python|Apache|Nginx|MySQL|PostgreSQL|MongoDB)" | while read line; do
        echo -e "    ${CYAN}•${NC} $line"
    done
elif command -v wappalyzer &> /dev/null; then
    echo -e "${GREEN}[+] Running wappalyzer...${NC}"
    wappalyzer "$BASE_URL" > "$OUTPUT_DIR/wappalyzer_homepage.txt"
    wappalyzer "$FULL_LOGIN_URL" > "$OUTPUT_DIR/wappalyzer_login.txt"
    
    echo -e "${GREEN}[+] Technology Summary:${NC}"
    cat "$OUTPUT_DIR/wappalyzer_homepage.txt" | grep -E "(WordPress|Drupal|Joomla|PHP|Node\.js)" | while read line; do
        echo -e "    ${CYAN}•${NC} $line"
    done
else
    echo -e "${RED}[-] Neither whatweb nor wappalyzer found.${NC}"
    echo -e "${YELLOW}[!] Manual inspection needed for technology stack${NC}"
fi

# =============================================================================
# 4. SUBDOMAIN DISCOVERY
# =============================================================================
echo -e "\n${YELLOW}[4/7] Subdomain Discovery${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Comprehensive subdomain list for educational institutions
SUBDOMAINS=(
    "www" "web" "mail" "email" "smtp" "pop" "pop3" "imap"
    "ftp" "sftp" "ssh" "remote" "vpn" "secure"
    "admin" "administrator" "manager" "portal" "dashboard"
    "cpanel" "whm" "webmail" "webdisk" "autodiscover"
    "mysql" "mssql" "postgres" "mongodb" "redis"
    "dev" "development" "test" "staging" "sandbox" "beta" "demo"
    "api" "rest" "graphql" "api2" "api3"
    "cdn" "static" "media" "assets" "resources"
    "blog" "news" "events" "calendar" "forum" "wiki" "docs"
    "support" "help" "service" "services" "helpdesk"
    "download" "uploads" "files" "content"
    "video" "audio" "stream" "live"
    "students" "staff" "faculty" "alumni" "parents"
    "admissions" "registration" "enrollment" "application"
    "halls" "hostel" "dorm" "residence" "accommodation"
    "library" "learning" "courses" "classes" "online"
    "portal" "gateway" "hub" "central" "main"
    "server" "host" "hosting" "cloud" "backup"
    "monitor" "monitoring" "status" "health" "stats"
    "security" "firewall" "proxy" "cache" "loadbalancer"
)

echo -e "${GREEN}[+] Checking $(( ${#SUBDOMAINS[@]} )) potential subdomains...${NC}"
echo -e "${YELLOW}[!] This may take a few minutes...${NC}"

> "$OUTPUT_DIR/subdomains_found.txt"
> "$OUTPUT_DIR/subdomains_detailed.txt"

for sub in "${SUBDOMAINS[@]}"; do
    subdomain="$sub.$DOMAIN"
    # Check with host command
    host "$subdomain" 2>/dev/null | grep "has address" | while read line; do
        ip=$(echo "$line" | awk '{print $4}')
        echo "$subdomain -> $ip" >> "$OUTPUT_DIR/subdomains_detailed.txt"
        echo -e "    ${GREEN}✓${NC} $subdomain -> $ip"
    done
    
    # Check with curl for HTTP/HTTPS
    curl -s -o /dev/null -w "%{http_code}" "http://$subdomain" 2>/dev/null | grep -q "200\|301\|302\|403"
    if [ $? -eq 0 ]; then
        echo "HTTP: $subdomain" >> "$OUTPUT_DIR/subdomains_found.txt"
    fi
    
    curl -s -o /dev/null -w "%{http_code}" "https://$subdomain" 2>/dev/null | grep -q "200\|301\|302\|403"
    if [ $? -eq 0 ]; then
        echo "HTTPS: $subdomain" >> "$OUTPUT_DIR/subdomains_found.txt"
    fi
done

echo -e "\n${GREEN}[+] Subdomain Discovery Results:${NC}"
if [ -s "$OUTPUT_DIR/subdomains_detailed.txt" ]; then
    echo -e "    ${CYAN}Active subdomains found:${NC}"
    cat "$OUTPUT_DIR/subdomains_detailed.txt" | while read line; do
        echo -e "        → $line"
    done
else
    echo -e "    ${YELLOW}No subdomains found via DNS resolution${NC}"
fi

if [ -s "$OUTPUT_DIR/subdomains_found.txt" ]; then
    echo -e "    ${CYAN}Subdomains with HTTP/HTTPS:${NC}"
    cat "$OUTPUT_DIR/subdomains_found.txt" | while read line; do
        echo -e "        → $line"
    done
fi

echo -e "${GREEN}[+] Subdomain results saved to: $OUTPUT_DIR/subdomains_*${NC}"

# =============================================================================
# 5. EMAIL HARVESTING
# =============================================================================
echo -e "\n${YELLOW}[5/7] Email Harvesting${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Method 1: Using theHarvester
if command -v theHarvester &> /dev/null; then
    echo -e "${GREEN}[+] Running theHarvester (this may take several minutes)...${NC}"
    
    for source in google bing baidu yahoo linkedin; do
        echo -e "${CYAN}[*] Searching $source...${NC}"
        theHarvester -d "$DOMAIN" -b "$source" -f "$OUTPUT_DIR/theharvester_${source}" 2>/dev/null
    done
    
    echo -e "${GREEN}[+] theHarvester Results:${NC}"
    cat "$OUTPUT_DIR"/theharvester_* 2>/dev/null | grep -E "[a-zA-Z0-9._%+-]+@$DOMAIN" | sort -u | while read email; do
        echo -e "    ${GREEN}📧${NC} $email"
    done | tee "$OUTPUT_DIR/emails_found.txt"
    
    if [ -s "$OUTPUT_DIR/emails_found.txt" ]; then
        EMAIL_COUNT=$(wc -l < "$OUTPUT_DIR/emails_found.txt")
        echo -e "    ${GREEN}Total emails found: $EMAIL_COUNT${NC}"
    else
        echo -e "    ${YELLOW}No emails found via search engines${NC}"
    fi
else
    echo -e "${RED}[-] theHarvester not installed${NC}"
fi

# Method 2: Scrape from website
echo -e "${GREEN}[+] Scraping website for email patterns...${NC}"
grep -E -o "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" "$OUTPUT_DIR/homepage_source.html" "$OUTPUT_DIR/login_page_source.html" 2>/dev/null | sort -u > "$OUTPUT_DIR/emails_scraped.txt"

echo -e "${GREEN}[+] Emails found in website source:${NC}"
cat "$OUTPUT_DIR/emails_scraped.txt" 2>/dev/null | while read email; do
    if [[ "$email" == *"$DOMAIN"* ]] || [[ "$email" == *"uonbi.ac.ke"* ]]; then
        echo -e "    ${GREEN}📧${NC} $email"
    else
        echo -e "    ${YELLOW}📧${NC} $email (external)"
    fi
done

# =============================================================================
# 6. LOGIN PAGE SPECIFIC ANALYSIS
# =============================================================================
echo -e "\n${YELLOW}[6/7] Login Page Security Analysis${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${GREEN}[+] Analyzing login page: $FULL_LOGIN_URL${NC}"

# Check login form fields
echo -e "${CYAN}[*] Extracting login form fields...${NC}"
grep -E "(input|form)" "$OUTPUT_DIR/login_page_source.html" | grep -E "(name|id|type)" > "$OUTPUT_DIR/login_form_fields.txt"

echo -e "${GREEN}[+] Login form analysis:${NC}"
echo -e "    ${CYAN}Username field:${NC}"
grep -E "(name|id).*user|username|email" "$OUTPUT_DIR/login_form_fields.txt" | head -3 | while read line; do
    echo -e "        → $line"
done

echo -e "    ${CYAN}Password field:${NC}"
grep -E "(name|id).*pass|pwd|password" "$OUTPUT_DIR/login_form_fields.txt" | head -3 | while read line; do
    echo -e "        → $line"
done

# Check for CSRF tokens
echo -e "${CYAN}[*] Checking for CSRF protection...${NC}"
CSRF_TOKEN=$(grep -E "csrf|token|_token" "$OUTPUT_DIR/login_page_source.html" | head -5)
if [ -n "$CSRF_TOKEN" ]; then
    echo -e "    ${GREEN}✓${NC} CSRF token detected"
    echo -e "        → $(echo "$CSRF_TOKEN" | head -1 | cut -c1-100)"
else
    echo -e "    ${YELLOW}!${NC} No CSRF token found (potential vulnerability)"
fi

# Check for remember me functionality
REMEMBER_ME=$(grep -E "remember|keep.*me|persistent" "$OUTPUT_DIR/login_page_source.html")
if [ -n "$REMEMBER_ME" ]; then
    echo -e "    ${CYAN}→${NC} 'Remember me' feature detected"
fi

# Check for SSL/TLS implementation
echo -e "${CYAN}[*] Checking SSL/TLS configuration...${NC}"
if command -v openssl &> /dev/null; then
    echo -e "Q" | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -text > "$OUTPUT_DIR/ssl_certificate.txt" 2>/dev/null
    
    if [ -s "$OUTPUT_DIR/ssl_certificate.txt" ]; then
        echo -e "    ${GREEN}✓${NC} SSL Certificate Details:"
        echo -e "        Issuer: $(grep "Issuer:" "$OUTPUT_DIR/ssl_certificate.txt" | head -1 | cut -d'=' -f2-)"
        echo -e "        Subject: $(grep "Subject:" "$OUTPUT_DIR/ssl_certificate.txt" | grep -v "Issuer" | head -1 | cut -d'=' -f2-)"
        echo -e "        Not Before: $(grep "Not Before" "$OUTPUT_DIR/ssl_certificate.txt" | head -1 | cut -d':' -f2-)"
        echo -e "        Not After: $(grep "Not After" "$OUTPUT_DIR/ssl_certificate.txt" | head -1 | cut -d':' -f2-)"
        echo -e "    ${GREEN}[+] Certificate saved to: $OUTPUT_DIR/ssl_certificate.txt${NC}"
    else
        echo -e "    ${RED}✗${NC} No SSL certificate found or connection failed"
    fi
fi

# Check for security headers
echo -e "${CYAN}[*] Checking security headers...${NC}"
SECURITY_HEADERS=("X-Frame-Options" "X-XSS-Protection" "X-Content-Type-Options" "Content-Security-Policy" "Strict-Transport-Security")
for header in "${SECURITY_HEADERS[@]}"; do
    if grep -i "$header" "$OUTPUT_DIR/headers_login.txt" &>/dev/null; then
        value=$(grep -i "$header" "$OUTPUT_DIR/headers_login.txt" | head -1)
        echo -e "    ${GREEN}✓${NC} $header present"
        echo -e "        → $value"
    else
        echo -e "    ${RED}✗${NC} $header missing"
    fi
done

# =============================================================================
# 7. DIRECTORIES AND FILES ENUMERATION (Basic)
# =============================================================================
echo -e "\n${YELLOW}[7/7] Basic File & Directory Enumeration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Common Drupal and web files
COMMON_PATHS=(
    "robots.txt" "sitemap.xml" ".htaccess" ".htpasswd" "web.config"
    "README.md" "LICENSE" "CHANGELOG.md" "composer.json" "composer.lock"
    "package.json" "package-lock.json" "yarn.lock" "Gemfile" "Gemfile.lock"
    "php.ini" ".env" ".env.example" "config.php" "settings.php"
    "wp-config.php" "wp-config-sample.php" "wp-login.php" "wp-admin/"
    "user/login" "user/register" "user/password" "admin/" "administrator/"
    "cpanel/" "webmail/" "phpmyadmin/" "pma/" "adminer/" "myadmin/"
    "xmlrpc.php" "sites/default/settings.php" "modules/" "themes/"
    "cron.php" "install.php" "update.php" "upgrade.php"
)

echo -e "${GREEN}[+] Checking for common files and directories...${NC}"
> "$OUTPUT_DIR/common_paths_results.txt"

for path in "${COMMON_PATHS[@]}"; do
    url="$BASE_URL/$path"
    status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ] || [ "$status" = "403" ]; then
        echo "✓ $path -> $status" >> "$OUTPUT_DIR/common_paths_results.txt"
        echo -e "    ${GREEN}✓${NC} $path -> Status: $status"
    elif [ "$status" = "404" ]; then
        # Don't display 404s to keep output clean
        :
    else
        echo "? $path -> $status" >> "$OUTPUT_DIR/common_paths_results.txt"
    fi
done

if [ -s "$OUTPUT_DIR/common_paths_results.txt" ]; then
    echo -e "${GREEN}[+] Interesting findings:${NC}"
    grep -E "robots\.txt|sitemap|\.env|settings\.php|wp-config|phpmyadmin" "$OUTPUT_DIR/common_paths_results.txt" | while read line; do
        echo -e "    ${YELLOW}⚠${NC} $line"
    done
else
    echo -e "    ${YELLOW}No interesting files found${NC}"
fi

# =============================================================================
# SUMMARY AND REPORT GENERATION
# =============================================================================
echo -e "\n${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          RECONNAISSANCE COMPLETE                               ║"
echo "║          Target: $DOMAIN                                      ║"
echo "║          Completed: $(date)                                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Generate comprehensive report
echo -e "${GREEN}[+] RECONNAISSANCE REPORT${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${CYAN}1. Target Information:${NC}"
echo -e "   Domain: $DOMAIN"
echo -e "   Login URL: $FULL_LOGIN_URL"
echo -e "   Output Directory: $OUTPUT_DIR"

echo -e "\n${CYAN}2. Service Discovery:${NC}"
if [ -f "$OUTPUT_DIR/nmap_quick.txt" ]; then
    OPEN_PORTS=$(grep "open" "$OUTPUT_DIR/nmap_quick.txt" | wc -l)
    echo -e "   Open Ports Found: $OPEN_PORTS"
    echo -e "   Details: $OUTPUT_DIR/nmap_full.nmap"
fi

echo -e "\n${CYAN}3. Technology Stack:${NC}"
if [ "$DRUPAL_DETECTED" = true ]; then
    echo -e "   CMS: ${GREEN}Drupal${NC} (likely)"
else
    echo -e "   CMS: ${YELLOW}Unknown${NC}"
fi
if [ -n "$SERVER" ]; then
    echo -e "   Web Server: $SERVER"
fi

echo -e "\n${CYAN}4. Subdomains Found:${NC}"
if [ -s "$OUTPUT_DIR/subdomains_detailed.txt" ]; then
    SUBDOMAIN_COUNT=$(wc -l < "$OUTPUT_DIR/subdomains_detailed.txt")
    echo -e "   Count: $SUBDOMAIN_COUNT"
    echo -e "   Details: $OUTPUT_DIR/subdomains_detailed.txt"
else
    echo -e "   ${YELLOW}None found${NC}"
fi

echo -e "\n${CYAN}5. Email Harvesting:${NC}"
if [ -s "$OUTPUT_DIR/emails_found.txt" ]; then
    EMAIL_COUNT=$(wc -l < "$OUTPUT_DIR/emails_found.txt")
    echo -e "   Emails Found: $EMAIL_COUNT"
    echo -e "   Details: $OUTPUT_DIR/emails_found.txt"
elif [ -s "$OUTPUT_DIR/emails_scraped.txt" ]; then
    EMAIL_COUNT=$(wc -l < "$OUTPUT_DIR/emails_scraped.txt")
    echo -e "   Emails Scraped: $EMAIL_COUNT"
    echo -e "   Details: $OUTPUT_DIR/emails_scraped.txt"
else
    echo -e "   ${YELLOW}None found${NC}"
fi

echo -e "\n${CYAN}6. Security Headers:${NC}"
if [ -f "$OUTPUT_DIR/headers_login.txt" ]; then
    MISSING_HEADERS=0
    for header in "${SECURITY_HEADERS[@]}"; do
        if ! grep -i "$header" "$OUTPUT_DIR/headers_login.txt" &>/dev/null; then
            ((MISSING_HEADERS++))
        fi
    done
    echo -e "   Missing Security Headers: $MISSING_HEADERS of ${#SECURITY_HEADERS[@]}"
    echo -e "   Details: $OUTPUT_DIR/headers_login.txt"
fi

echo -e "\n${CYAN}7. Files Generated:${NC}"
ls -la "$OUTPUT_DIR" | awk '{print "   " $9}' | grep -v "^$" | head -15

# Generate JSON summary
cat > "$OUTPUT_DIR/summary.json" <<EOF
{
    "target": {
        "domain": "$DOMAIN",
        "login_url": "$FULL_LOGIN_URL",
        "timestamp": "$TIMESTAMP"
    },
    "scan_results": {
        "drupal_detected": $DRUPAL_DETECTED,
        "subdomains_found": $( [ -s "$OUTPUT_DIR/subdomains_detailed.txt" ] && echo "$(wc -l < "$OUTPUT_DIR/subdomains_detailed.txt")" || echo 0),
        "emails_found": $( [ -s "$OUTPUT_DIR/emails_found.txt" ] && echo "$(wc -l < "$OUTPUT_DIR/emails_found.txt")" || echo 0),
        "missing_security_headers": $MISSING_HEADERS
    },
    "output_directory": "$OUTPUT_DIR",
    "files": $(ls -1 "$OUTPUT_DIR" | jq -R -s -c 'split("\n")[:-1]')
}
EOF

echo -e "\n${GREEN}[+] JSON summary saved to: $OUTPUT_DIR/summary.json${NC}"

# =============================================================================
# NEXT STEPS FOR PHASE 2
# =============================================================================
echo -e "\n${YELLOW}[!] NEXT STEPS - PHASE 2 (Vulnerability Assessment)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}1. Login Page Testing:${NC}"
echo -e "   Target: $FULL_LOGIN_URL"
echo -e "   Tools: Burp Suite, OWASP ZAP, Hydra (brute-force)"
echo -e "   Check: SQL injection, XSS, CSRF, weak credentials"

echo -e "\n${CYAN}2. Drupal Specific Testing:${NC}"
if [ "$DRUPAL_DETECTED" = true ]; then
    echo -e "   Tools: Droopescan, Drupal Security Scanner"
    echo -e "   Check: Drupal version, known vulnerabilities, modules"
else
    echo -e "   ${YELLOW}Confirm CMS first with further fingerprinting${NC}"
fi

echo -e "\n${CYAN}3. Open Ports & Services:${NC}"
echo -e "   Review: $OUTPUT_DIR/nmap_full.nmap"
echo -e "   Check: Default credentials, known CVEs"

echo -e "\n${CYAN}4. Subdomains & Emails:${NC}"
echo -e "   Enumerate: Any interesting subdomains found"
echo -e "   Use: Gathered emails for social engineering (if authorized)"

echo -e "\n${CYAN}5. Security Headers:${NC}"
echo -e "   Review: Missing security headers in $OUTPUT_DIR/headers_login.txt"
echo -e "   Fix: Implement proper security headers"

echo -e "\n${GREEN}[+] Reconnaissance Phase 1 Complete!${NC}"
echo -e "${GREEN}[+] All results saved in: $OUTPUT_DIR${NC}"
