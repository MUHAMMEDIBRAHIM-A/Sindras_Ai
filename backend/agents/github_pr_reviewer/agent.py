import os
import sys
from dotenv import load_dotenv
from google import genai
from google.genai import types
from prompt import build_system_prompt
from tools.github_tools import fetch_pr_details_and_diff, post_pr_review_summary

load_dotenv()


def run_pr_review_agent(repo_owner: str, repo_name: str, pr_number: int):
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("Error: GEMINI_API_KEY not found in .env")
        sys.exit(1)

    client = genai.Client(api_key=api_key)

    user_prompt = (
        f"Review Pull Request #{pr_number} in repository '{repo_owner}/{repo_name}'. "
        "Fetch the diff, evaluate it thoroughly against our coding standards, and post the review on GitHub."
    )

    print(f"Starting standalone review for {repo_owner}/{repo_name} PR #{pr_number}...")

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=user_prompt,
        config=types.GenerateContentConfig(
            system_instruction=build_system_prompt(),
            tools=[fetch_pr_details_and_diff, post_pr_review_summary],
            temperature=0.1,
        ),
    )

    print("\n--- Final Agent Report ---")
    print(response.text)


if __name__ == "__main__":
    owner = input("GitHub Repo Owner (e.g., octocat): ").strip()
    repo = input("GitHub Repo Name (e.g., hello-world): ").strip()
    pr_num = int(input("Pull Request Number (e.g., 12): ").strip())

    run_pr_review_agent(owner, repo, pr_num)
