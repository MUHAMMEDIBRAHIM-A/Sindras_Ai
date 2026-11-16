import os
import requests

GITHUB_API_BASE = "https://api.github.com"


def _get_headers() -> dict:
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        raise ValueError("GITHUB_TOKEN is missing in environment variables.")
    return {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }


def fetch_pr_details_and_diff(repo_owner: str, repo_name: str, pr_number: int) -> str:
    """Fetches PR metadata and the unified code diff for all changed files."""
    headers = _get_headers()

    # 1. Fetch PR Title & Description
    pr_url = f"{GITHUB_API_BASE}/repos/{repo_owner}/{repo_name}/pulls/{pr_number}"
    pr_resp = requests.get(pr_url, headers=headers, timeout=15)
    pr_resp.raise_for_status()
    pr_data = pr_resp.json()

    # 2. Fetch Changed Files & Patches (Diffs)
    files_url = f"{pr_url}/files"
    files_resp = requests.get(files_url, headers=headers, timeout=15)
    files_resp.raise_for_status()
    files_data = files_resp.json()

    output = [
        f"PR #{pr_number}: {pr_data.get('title')}",
        f"Author: {pr_data.get('user', {}).get('login')}",
        f"Description:\n{pr_data.get('body') or 'No description provided.'}\n",
        "--- CHANGED FILES & DIFFS ---",
    ]

    for file in files_data:
        filename = file.get("filename")
        status = file.get("status")
        patch = file.get("patch", "[Binary or large file diff omitted]")
        output.append(f"\nFile: {filename} ({status})\n```diff\n{patch}\n```")

    return "\n".join(output)


def post_pr_review_summary(
    repo_owner: str,
    repo_name: str,
    pr_number: int,
    review_body: str,
    event: str = "COMMENT",
) -> str:
    """Posts a formal review summary on the GitHub Pull Request.

    Args:
        repo_owner: GitHub username or organization name.
        repo_name: Repository name.
        pr_number: Pull Request number.
        review_body: Markdown formatted code review feedback.
        event: Must be 'APPROVE', 'REQUEST_CHANGES', or 'COMMENT'.
    """
    valid_events = {"APPROVE", "REQUEST_CHANGES", "COMMENT"}
    if event not in valid_events:
        event = "COMMENT"

    url = f"{GITHUB_API_BASE}/repos/{repo_owner}/{repo_name}/pulls/{pr_number}/reviews"
    payload = {
        "body": review_body,
        "event": event,
    }

    resp = requests.post(url, headers=_get_headers(), json=payload, timeout=15)
    resp.raise_for_status()
    return f"Review posted successfully (Status: {event}). URL: {resp.json().get('html_url')}"
