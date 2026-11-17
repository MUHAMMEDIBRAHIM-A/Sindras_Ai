import json
import urllib.request
import urllib.error

def test():
    url = "http://127.0.0.1:8000/query"
    payload = json.dumps({"query": "Top 5 products by sales last month?", "user_role": "finance"}).encode("utf-8")
    headers = {"Content-Type": "application/json"}

    req = urllib.request.Request(url, data=payload, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req) as response:
            status_code = response.getcode()
            res_body = json.loads(response.read().decode("utf-8"))
            print("Status Code:", status_code)
            print("Response JSON:", res_body)
    except urllib.error.URLError as e:
        print("Server not running or connection error:", e)

if __name__ == "__main__":
    test()
