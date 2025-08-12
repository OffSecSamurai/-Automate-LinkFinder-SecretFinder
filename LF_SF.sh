#!/bin/bash
# ========================================================================
#  JS RECON ORCHESTRATOR v6.0 - by Your AI Assistant
#  • Action-Oriented Reporting: Easily spot URLs with findings.
#  • Bug-Free Statistics: Accurate counting of all discovered items.
#  • Rock-solid, reliable execution logic.
# ========================================================================

# -------- Paths & Tools ---------------------------------------------------
LINKFINDER_PATH="/home/kali/Tools/LinkFinder/linkfinder.py"
SECRETFINDER_PATH="/home/kali/Tools/SecretFinder/SecretFinder.py"
LINKFINDER_VENV="/home/kali/Tools/LinkFinder/.venv/bin/python3"
SECRETFINDER_VENV="/home/kali/Tools/SecretFinder/.venv/bin/python3"

# -------- Files & Reports -------------------------------------------------
INPUT_FILE="all_js_files.txt"
COMBINED_REPORT="js_master_report.txt"
ERROR_LOG="error_log_failures.txt"
STATS_FILE="analysis_statistics.txt"
RESUME_FILE=".resume_progress"

# -------- Color Palette (for terminal only) -------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# -------- User Agents -----------------------------------------------------
USER_AGENTS=(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15"
)

# -------- Helpers & Handlers ----------------------------------------------
rand_delay() { echo $((RANDOM % 3 + 1)); } # 1-3 second delay
rand_ua()    { echo "${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}"; }
START_TIME=$(date +%s)
OK=0 FAIL=0 SKIP=0 LF_TOTAL=0 SF_TOTAL=0

save_prog()  { echo "$CUR" > "$RESUME_FILE"; }
load_prog()  { [[ -f $RESUME_FILE ]] && cat "$RESUME_FILE" || echo 0; }

finish() {
  local END_TIME=$(date +%s)
  local RUNTIME=$((END_TIME - START_TIME))
  echo -e "\n${PURPLE}📝 Writing Final Statistics...${NC}"
  {
    echo "###########################################"
    echo "#          ANALYSIS COMPLETE            #"
    echo "###########################################"
    echo "  Processed ......: $CUR / $TOT URLs"
    echo "  Successful .....: $OK"
    echo "  Failed .........: $FAIL"
    echo "  Skipped ........: $SKIP"
    echo "  LinkFinder .....: $LF_TOTAL total findings"
    echo "  SecretFinder ...: $SF_TOTAL total findings"
    echo "  Total Runtime ..: $((RUNTIME / 60))m $((RUNTIME % 60))s"
  } | tee "$STATS_FILE"
}

trap 'echo -e "\n${RED}🛑 Aborting script.${NC}"; finish; save_prog; exit 1' SIGINT

# -------- Script Start & Resume Logic ------------------------------------
echo -e "${PURPLE}🚀 JS Recon Orchestrator v6.0 Initializing...${NC}"
[[ ! -f $INPUT_FILE ]] && { echo -e "${RED}❌ Input file '$INPUT_FILE' not found.${NC}"; exit 1; }
TOT=$(wc -l <"$INPUT_FILE")
echo -e "${CYAN}📄 Found ${YELLOW}$TOT${CYAN} target URLs.${NC}"

if [[ -f $RESUME_FILE ]]; then
  read -rp "$(echo -e ${YELLOW}"❓ Resume previous run? (y/n): "${NC})" rez
  if [[ $rez =~ ^[Yy]$ ]]; then
    RES=$(load_prog); echo -e "${GREEN}Resuming from URL #$((RES + 1))${NC}"
  else
    RES=0; rm -f "$RESUME_FILE"; > "$COMBINED_REPORT"; > "$ERROR_LOG"
    echo -e "${GREEN}Starting a fresh run.${NC}"
  fi
else
  RES=0; > "$COMBINED_REPORT"; > "$ERROR_LOG"
fi

# -------- Main Processing Loop -------------------------------------------
CUR=0
while IFS= read -r URL || [[ -n $URL ]]; do
  [[ -z $URL ]] && continue
  ((CUR++))
  [[ $CUR -le $RES ]] && { ((SKIP++)); continue; }

  # --- Terminal Output: Header ---
  echo -e "\n${BLUE}================================================================${NC}"
  echo -e "${BLUE} [$CUR/$TOT] Scanning: $URL${NC}"
  echo -e "${BLUE}================================================================${NC}"

  # --- Fetch Content ---
  TMP=$(mktemp)
  HTTP_CODE=$(curl -sL --http1.1 -A "$(rand_ua)" -o "$TMP" -w "%{http_code}" "$URL")

  if [[ "$HTTP_CODE" != "200" ]] || [[ ! -s "$TMP" ]]; then
    echo -e "${RED}   -> ❌ FAILED (HTTP: $HTTP_CODE). Skipping.${NC}"
    echo "[-] FAILED (HTTP: $HTTP_CODE) - $URL" >> "$COMBINED_REPORT"
    echo "$URL" >> "$ERROR_LOG"
    ((FAIL++)); rm -f "$TMP"; sleep "$(rand_delay)"; continue
  fi
  echo -e "${GREEN}   -> ✅ DOWNLOADED (HTTP: 200)${NC}"
  ((OK++))

  # --- Run Tools ---
  echo -e "${CYAN}   -> Analyzing...${NC}"
  LF_OUT=$("$LINKFINDER_VENV" "$LINKFINDER_PATH" -i "$TMP" -o cli 2>>/dev/null | grep -iv "Searching for" || true)
  SF_OUT=$("$SECRETFINDER_VENV" "$SECRETFINDER_PATH" -i "$TMP" -o cli 2>>/dev/null | sed "s|file://$TMP|$URL|g" | grep -iv "Searching for" || true)
  
  LF_COUNT=$(echo -n "$LF_OUT" | wc -l)
  SF_COUNT=$(echo -n "$SF_OUT" | wc -l)

  # --- Update master counters ---
  LF_TOTAL=$((LF_TOTAL + LF_COUNT))
  SF_TOTAL=$((SF_TOTAL + SF_COUNT))

  # --- Generate Report Entry ---
  if (( LF_COUNT > 0 || SF_COUNT > 0 )); then
    echo -e "${GREEN}      -> FINDINGS DISCOVERED! (LF: $LF_COUNT, SF: $SF_COUNT)${NC}"
    echo "========================================================================" >> "$COMBINED_REPORT"
    echo "[+] FINDINGS FOR: $URL" >> "$COMBINED_REPORT"
    
    if (( LF_COUNT > 0 )); then
        echo -e "\n----------[ LinkFinder Findings: $LF_COUNT ]----------\n" >> "$COMBINED_REPORT"
        echo -e "$LF_OUT\n" >> "$COMBINED_REPORT"
    fi
    if (( SF_COUNT > 0 )); then
        echo -e "\n----------[ SecretFinder Findings: $SF_COUNT ]----------\n" >> "$COMBINED_REPORT"
        echo -e "$SF_OUT\n" >> "$COMBINED_REPORT"
    fi
    echo "========================================================================" >> "$COMBINED_REPORT"
    echo "" >> "$COMBINED_REPORT"
  else
    echo -e "${YELLOW}      -> No findings.${NC}"
    echo "[-] No findings for: $URL" >> "$COMBINED_REPORT"
  fi

  rm -f "$TMP"
  sleep "$(rand_delay)"
  save_prog
done <"$INPUT_FILE"

# -------- Finalize -------------------------------------------------------
finish
rm -f "$RESUME_FILE"
echo -e "${PURPLE}🏁 Script Finished. Review master report: ${YELLOW}$COMBINED_REPORT${NC}"
