"""Read this repository's CI using the existing Git credential; never print it."""
import argparse
import io
import json
import subprocess
import urllib.request
import zipfile

BASE = "https://api.github.com/repos/hahanooben123-spec/Fantasy-friend-"

def request(path):
    result = subprocess.run(["git", "credential", "fill"], input="protocol=https\nhost=github.com\n\n", text=True, capture_output=True, check=True)
    credential = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
    req = urllib.request.Request(BASE + path, headers={"Authorization": "Bearer " + credential["password"], "Accept": "application/vnd.github+json"})
    with urllib.request.urlopen(req, timeout=60) as response:
        return response.read()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["status", "logs"])
    parser.add_argument("--run", type=int)
    args = parser.parse_args()
    if args.action == "status":
        data = json.loads(request("/actions/runs?per_page=3"))
        print(json.dumps([{k: run.get(k) for k in ["id", "head_sha", "status", "conclusion", "html_url"]} for run in data["workflow_runs"]], indent=2))
    else:
        if not args.run:
            parser.error("--run is required for logs")
        archive = zipfile.ZipFile(io.BytesIO(request(f"/actions/runs/{args.run}/logs")))
        lines = []
        needles = ["error:", "failed", "executed", "test case", "** build", "** test"]
        for name in archive.namelist():
            if "/" in name:
                continue
            for line in archive.read(name).decode("utf-8", errors="replace").splitlines():
                if any(needle in line.lower() for needle in needles):
                    lines.append(line)
        print("\n".join(lines[-150:]))

if __name__ == "__main__":
    main()
