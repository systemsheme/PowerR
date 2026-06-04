#!/usr/bin/env python3
"""
PowerR launcher.

Finds R on your computer, installs the `remotes` helper and the PowerR
package from GitHub if they're missing, then starts the Shiny app and
opens it in your default web browser.

Usage:
    python3 powerr.py                # install if needed, then launch
    python3 powerr.py --upgrade      # reinstall to pick up the latest
    python3 powerr.py --port 4567    # pin a specific port
    python3 powerr.py --no-browser   # don't auto-open a browser tab

Requires Python 3.8+ and an R installation (https://cran.r-project.org/).
No third-party Python packages are needed.
"""

from __future__ import annotations

import argparse
import os
import platform
import shutil
import signal
import socket
import subprocess
import sys
import threading
import time
import webbrowser

REPO = "systemsheme/PowerR"
HOST = "127.0.0.1"
CRAN_MIRROR = "https://cloud.r-project.org"


def find_rscript() -> str:
    """Locate the Rscript executable across platforms."""
    found = shutil.which("Rscript")
    if found:
        return found

    system = platform.system()
    candidates: list[str] = []

    if system == "Darwin":
        candidates += [
            "/Library/Frameworks/R.framework/Resources/bin/Rscript",
            "/usr/local/bin/Rscript",
            "/opt/homebrew/bin/Rscript",
        ]
    elif system == "Windows":
        for base in (r"C:\Program Files\R", r"C:\Program Files (x86)\R"):
            if os.path.isdir(base):
                for v in sorted(os.listdir(base), reverse=True):
                    cand = os.path.join(base, v, "bin", "Rscript.exe")
                    if os.path.exists(cand):
                        candidates.append(cand)
    else:
        candidates += ["/usr/bin/Rscript", "/usr/local/bin/Rscript"]

    for c in candidates:
        if os.path.exists(c):
            return c

    sys.exit(
        "Could not find R on this computer.\n"
        "Install R from https://cran.r-project.org/ and run this script again."
    )


def r_has_package(rscript: str, pkg: str) -> bool:
    result = subprocess.run(
        [rscript, "-e", f'cat(requireNamespace("{pkg}", quietly = TRUE))'],
        capture_output=True,
        text=True,
    )
    return "TRUE" in result.stdout


def install_remotes(rscript: str) -> None:
    print("Installing the 'remotes' helper package...")
    subprocess.check_call([
        rscript, "-e",
        f'install.packages("remotes", repos = "{CRAN_MIRROR}")',
    ])


def install_powerr(rscript: str, upgrade: bool) -> None:
    action = "Reinstalling" if upgrade else "Installing"
    print(f"{action} PowerR from GitHub ({REPO})...")
    print("First-time install takes 2-5 minutes while dependencies download.")
    upgrade_arg = '"always"' if upgrade else '"never"'
    subprocess.check_call([
        rscript, "-e",
        f'options(repos = c(CRAN = "{CRAN_MIRROR}")); '
        f'remotes::install_github("{REPO}", upgrade = {upgrade_arg})',
    ])


def free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, 0))
        return s.getsockname()[1]


def launch_app(rscript: str, port: int) -> subprocess.Popen:
    expr = (
        f'PowerR::run_app(port = {port}, host = "{HOST}", '
        f'launch.browser = FALSE)'
    )
    return subprocess.Popen([rscript, "-e", expr])


def wait_and_open(port: int, timeout: float = 90.0) -> None:
    """Poll the Shiny port; open the browser once it accepts connections."""
    url = f"http://{HOST}:{port}"
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(0.5)
            try:
                s.connect((HOST, port))
            except OSError:
                time.sleep(0.5)
                continue
        print(f"PowerR is ready at {url} — opening your browser.", flush=True)
        webbrowser.open(url)
        return
    print(f"Gave up waiting for the Shiny app on {url} after {timeout:.0f}s.",
          file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Launch PowerR locally in your web browser.",
    )
    parser.add_argument("--port", type=int, default=None,
                        help="Port for the Shiny app (default: pick a free one).")
    parser.add_argument("--upgrade", action="store_true",
                        help="Reinstall PowerR from GitHub to pick up the latest.")
    parser.add_argument("--no-browser", action="store_true",
                        help="Don't auto-open a browser tab.")
    args = parser.parse_args()

    rscript = find_rscript()
    print(f"Using R: {rscript}")

    if not r_has_package(rscript, "remotes"):
        install_remotes(rscript)

    if args.upgrade or not r_has_package(rscript, "PowerR"):
        install_powerr(rscript, upgrade=args.upgrade)

    port = args.port or free_port()
    print(f"Starting PowerR on http://{HOST}:{port} ...")
    print("Press Ctrl+C to stop.")
    proc = launch_app(rscript, port)

    def stop(*_):
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
        sys.exit(0)

    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)

    if not args.no_browser:
        threading.Thread(
            target=wait_and_open, args=(port,), daemon=True,
        ).start()

    try:
        proc.wait()
    finally:
        stop()


if __name__ == "__main__":
    main()
