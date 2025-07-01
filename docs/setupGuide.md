## 🛠️ Mattermost Alerting Setup Guide

This guide walks you through setting up bot-powered alerts from Proxmox VE, PBS, Uptime Kuma, and any custom script into a single Mattermost channel.

---

### ✅ Prerequisites

* 🧠 Basic Linux command-line knowledge
* 🔧 Access to:

  * Proxmox VE host
  * Proxmox Backup Server (PBS)
  * Mattermost server with **Incoming Webhooks** enabled
* 📡 (Optional) Uptime Kuma or other custom monitoring scripts

---

### 🪝 Step 1: Create Webhook in Mattermost

1. Go to your Mattermost channel (e.g., `#server-notifications`)
2. Click the **⋯ menu > Integrations > Incoming Webhooks**
3. Click **Add Incoming Webhook**
4. Name it something like `PBS Alerts`, assign it a **bot user**, and save
5. Copy the **Webhook URL** (you’ll use this later)

🔒 Tip: Create one bot per category (e.g. `kumabot` for UptimeKuma, `proxmoxbot` for VE) to separate sources cleanly. You can also create dedicated users and severely limit there functionality to a single channel as Bots can be set to have full access. 

---

### 📦 Step 2: Configure PBS Alerts

### PBS 

1. In the GUI, head down to `Configuration` and `Notifications`. Click the `Add` drop down and select `Webhook`. Pick a name for the Notification, enable and ensure the `Method:` is set to `POST`. Add your webhook you created in Mattermopst for PBS here. 
Under `Headers:` add a new header. The key should be `Content-Type` and set the value to `application/json`

2. Add the below template to the `Body:` section:

```json
{
  "text": ":floppy_disk: **PBS Alert** from {{ host }}
\n ### Title: {{ title }}
\nSeverity: **{{ severity }}**
\nTime: {{ timestamp }}
\nJob Type: {{ fields.type }}
\nJob: {{ fields.job-id }}
\n{{ message }}"
}
```
---

### 🧮 Step 3: Add Proxmox VE Integration (Optional)

1. Go to **Datacenter > Notifications**
2. Add a new endpoint of type **Webhook**
3. Paste your Mattermost Webhook URL
4. Use this test body template:

```json
{
  "text": ":gear: **Proxmox Alert from {{ nodename }}**\n### {{ title }}\nSeverity: **{{ severity }}**\nTime: {{ timestamp }} unix seconds\nJob Type: {{ fields.type }}\n\n{{ message }}"
}
```

5. Save and trigger a test to verify.

---

### 🛰️ Step 4: Add Uptime Kuma or Custom Scripts

In any shell script, you can send a Mattermost message using `curl`:

```bash
#!/bin/bash

WEBHOOK_URL="https://your-mattermost-url/hooks/xxxxxxxxxx"
HOSTNAME=$(hostname)

curl -X POST -H 'Content-Type: application/json' -d "{
  \"text\": \":satellite: *Uptime Alert from ${HOSTNAME}*\\nStatus: UP\\nTime: $(date)\" 
}" "$WEBHOOK_URL"
```

Add to `cron`, `monit`, or Uptime Kuma’s webhook field.
You can use my template script found under /templates. Just make sure to add your own Mattermost webhook! This script will check disk usage, Root login attempts and uses Fail2Ban to check for banned IP's.

### Bash Alert Script (for VMs)

For Vm integrations, I wrote a small bash script that checks if the filesystem is set to `read-only`, it checks the `/` disk usage against a pre determined threshold value and also checks for failed SSH logins. I recommend installing Fail2Ban so you can also check for any active bans. The script then adds these errors to an error list ready for the Mattermost notifcation.

#### Snippet
```bash
#!/bin/bash
if [ ${#ERRORS[@]} -ne 0 ]; then
    PAYLOAD=$(printf "*%s* reported system health issues:\n%s" "$HOSTNAME" "$(printf '• %s\n' "${ERRORS[@]}")")

    curl -s -X POST -H 'Content-Type: application/json' \
        -d "{\"text\": \"${PAYLOAD}\"}" "$HOOK_URL"
fi
```

> Place this script on any VM and make it executable with `chmod +x`. Trigger it from `cron`, health checks, or log watchers.

I use cron jobs which run every hour, if no warning messages are logged then no messgae is sent. The log clears once the script has run so i dont have stacks of alerts throughout the day.

Full script [here](../examples/scripts/vmHealthChecks.sh)

---

### Step 5: Test It!

Try:

* Triggering a PBS backup job
* Running a Proxmox alert
* Sending a shell script via `curl`

You should see formatted alerts appearing in your Mattermost channel.

---

### Done!

You’ve now unified your homelab alerts with:

* 📬 Clear, markdown-formatted messages
* 👤 Per-service bot identities
* 🔒 100% self-hosted stack

---

## 💬 Contributing

Pull requests welcome! This project is meant to help others self-host their own NOC-like alerting stack without relying on external tools.

---

## 📜 License

MIT — do what you like. Attribution welcome but not required.

---

## 🙌 Credits

Made with ❤️ by Jake, powered by shell scripts, Proxmox, PBS, and way too much caffeine.
