#!/usr/bin/env python3
"""
Comprehensive Automated Test Runner and Diagnostics Reporter.
Executes all unit, structural, and integration suites with nanosecond timing.
"""

import json
import os
import sys
import time
from as3_vm import StencilVM

GREEN = "\033[92m"
RED = "\033[91m"
BOLD = "\033[1m"
CYAN = "\033[96m"
DIM = "\033[2m"
RESET = "\033[0m"

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(root)

    print(f"\n{BOLD}{CYAN}======================================================================{RESET}")
    print(f"{BOLD}{CYAN}            STENCIL VERIFICATION HARNESS & TEST RUNNER               {RESET}")
    print(f"{BOLD}{CYAN}======================================================================{RESET}\n")

    vm = StencilVM()
    vm.load_as3_codebase("src")
    vm.load_as3_codebase("test")

    t0 = time.perf_counter()
    report = vm.run_tests()
    elapsed = (time.perf_counter() - t0) * 1000

    for suite in report["suites"]:
        suite_name = suite["suite"].split(".")[-1]
        passed = suite["passed"]
        failed = suite["failed"]
        status_color = GREEN if failed == 0 else RED
        status_badge = f"{status_color}PASS{RESET}" if failed == 0 else f"{status_color}FAIL{RESET}"

        print(f"  [{status_badge}] {BOLD}{suite_name:<36}{RESET} {DIM}({passed} passed, {failed} failed){RESET}")
        for t in suite["tests"]:
            mark = f"{GREEN}✓{RESET}" if t["status"] == "PASSED" else f"{RED}✗{RESET}"
            print(f"    {mark} {t['name']}")

    print(f"\n{BOLD}{CYAN}----------------------------------------------------------------------{RESET}")
    print(f"{BOLD}Summary:{RESET} Total: {BOLD}{report['total']}{RESET} | "
          f"{GREEN}Passed: {report['passed']}{RESET} | "
          f"{RED if report['failed'] > 0 else GREEN}Failed: {report['failed']}{RESET} | "
          f"Time: {BOLD}{elapsed:.2f} ms{RESET}")
    print(f"{BOLD}{CYAN}======================================================================{RESET}\n")

    os.makedirs("test-results", exist_ok=True)
    with open("test-results/summary.json", "w") as f:
        json.dump(report, f, indent=2)

    if report["failed"] > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()
