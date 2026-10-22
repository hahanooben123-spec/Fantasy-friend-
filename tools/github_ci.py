"""Read this repository's CI using the existing Git credential; never print it."""
import argparse
import io
import json
import subprocess
import time
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

BASE = "https://api.github.com/repos/hahanooben123-spec/Fantasy-friend-"

class SafeRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        redirected = super().redirect_request(req, fp, code, msg, headers, newurl)
        if redirected is not None and urllib.parse.urlsplit(req.full_url).hostname != urllib.parse.urlsplit(newurl).hostname:
            redirected.remove_header("Authorization")
        return redirected

def request(path):
    result = subprocess.run(["git", "credential", "fill"], input="protocol=https\nhost=github.com\n\n", text=True, capture_output=True, check=True)
    credential = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
    separator = "&" if "?" in path else "?"
    req = urllib.request.Request(BASE + path + separator + "fresh=" + str(time.time_ns()), headers={"Authorization": "Bearer " + credential["password"], "Accept": "application/vnd.github+json"})
    with urllib.request.build_opener(SafeRedirect()).open(req, timeout=60) as response:
        return response.read()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["status", "logs", "screenshots"])
    parser.add_argument("--run", type=int)
    args = parser.parse_args()
    if args.action == "status":
        data = json.loads(request("/actions/runs?per_page=3"))
        print(json.dumps([{k: run.get(k) for k in ["id", "head_sha", "status", "conclusion", "html_url"]} for run in data["workflow_runs"]], indent=2))
    elif args.action == "screenshots":
        if not args.run:
            parser.error("--run is required for screenshots")
        items = json.loads(request(f"/actions/runs/{args.run}/artifacts"))["artifacts"]
        artifact = next(item for item in items if item["name"] == "ui-previews")
        archive = zipfile.ZipFile(io.BytesIO(request(f"/actions/artifacts/{artifact['id']}/zip")))
        folder = (Path(__file__).resolve().parents[1] / "artifacts" / "screenshots" / str(args.run)).resolve()
        folder.mkdir(parents=True, exist_ok=True)
        for name in archive.namelist():
            if not name.lower().endswith(".png"):
                continue
            target = (folder / Path(name).name).resolve()
            if target.parent != folder:
                raise ValueError("Invalid artifact path")
            target.write_bytes(archive.read(name))
            print(target)
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
