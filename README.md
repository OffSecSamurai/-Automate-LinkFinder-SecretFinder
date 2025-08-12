A powerful bash script that automates JavaScript reconnaissance. It takes a list of JS URLs and runs LinkFinder and SecretFinder to discover endpoints, paths, and sensitive data like API keys.

Core Features:

Dual-Tool Analysis: Automates the discovery of both paths and secrets from JS files.

Comprehensive Reporting: Creates a master report for findings, a separate error log, and a final statistics summary.

Scan Resumption: Automatically saves progress and can resume an interrupted scan, saving time on large target lists.

Evasive & Reliable: Uses randomized user-agents and delays to avoid basic blocking and ensures stable execution.

Organized Output: Groups all findings by their source URL for clear, actionable results.

Quick Start:

Populate all_js_files.txt with one JS URL per line.

Verify the tool paths at the top of the script are correct for your system.

Make it executable: chmod +x ./LF_SF.sh

Run it: ./LF_SF.sh
