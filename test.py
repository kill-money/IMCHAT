import http.client
import json

conn = http.client.HTTPSConnection("api.302.ai")
payload = json.dumps({
   "model": "claude-3-7-sonnet-20250219",
   "messages": [
      {
         "role": "user",
         "content": "Hello!"
      }
   ]
})
headers = {
   'Accept': 'application/json',
   'Authorization': 'Bearer sk-ikt6bihMlypWEFrCjkgOMlI5cdgubwlneLoS2oYvhKUUHz0s',
   'Content-Type': 'application/json'
}
conn.request("POST", "/v1/chat/completions", payload, headers)
res = conn.getresponse()
data = res.read()
print(data.decode("utf-8"))