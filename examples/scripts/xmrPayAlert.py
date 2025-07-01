import requests
import time


WALLET = ""
MATTERMOST_WEBHOOK_URL = "https://mattermost.example.com/hooks/abcd1234"
POOL_STATS_URL = "https://supportxmr.com/api/miner/{WALLET}/stats"
THRESHOLD = 0.1  # XMR payout threshold



def check_pending():
    r = requests.get(POOL_STATS_URL, timeout=10)
    data = r.json()
    amt_due = data.get("amtDue", 0) / 1e12

    if amt_due >= THRESHOLD:
        msg = {
            "username": "MoneroMiner",
            "text": f"💸 You're about to get paid!\nPending balance is at **{amt_due:.6f} XMR**.\nMining is working beautifully 🎉"
        }
        requests.post(MATTERMOST_WEBHOOK_URL, json=msg)

if __name__ == "__main__":
    check_pending()