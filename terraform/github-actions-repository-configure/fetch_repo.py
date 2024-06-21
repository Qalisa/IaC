import requests
import json

def fetch_repos_with_topic(token, owner, topic):
    url = f"https://api.github.com/search/repositories?q=topic:{topic}+user:{owner}"
    headers = {"Authorization": f"token {token}"}
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return [repo['name'] for repo in response.json()['items']]

if __name__ == "__main__":
    import sys
    import os
    import subprocess
    
    # Fetching required variables
    token = os.getenv("GITHUB_TOKEN")
    owner = os.getenv("GITHUB_OWNER")
    topic = os.getenv("GITHUB_TOPIC")
    
    repos = fetch_repos_with_topic(token, owner, topic)
    
    result = {"repositories": repos}
    print(json.dumps(result))
