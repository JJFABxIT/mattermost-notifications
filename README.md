# 🛎️ Mattermost Homelab Alerting System

A fully self-hosted, bot-driven alerting setup that unifies infrastructure notifications from:

* 🖥️ Proxmox VE
* 💾 Proxmox Backup Server (PBS)
* 📡 Uptime Kuma
* 🪙 XMR mining node
* 🧰 Custom VM health scripts

All routed to **Mattermost channels** using Markdown-formatted webhook messages and unique bot users per role.

---

## ⚙️ Features

* ✅ Self-hosted, no cloud or third-party services
* 🤖 Bot-based alert separation (Proxmox, PBS, Uptime, Mining, VM)
* 🧾 Markdown-formatted Mattermost messages
* 🧠 Human-readable context: job type, server name, error, and timestamps
* 🛠️ Extensible to any system with `curl` support

---

## 📸 Example Alerts

> PBS Tape Job Failure

```
📦 PBS Alert from pbs 
Title: Tape Backup datastore 'T3111_2TB' failed  
Severity: **error**  
Time: 1751359836 (Unix)  
Job Type: tape-backup  
Datastore: T3111_2TB  
Tape Pool: PBS-LTO 
Tape Drive: LTO-Drive
Tape Backup failed: alloc writable media in pool failed: no usable media found  
```

> Uptime Kuma Bot

```
🟢 Service: pve01.local  
Status: UP  
Time: 2025-07-01 10:36:00  
```

---

## 📂 Structure

```
├── /examples
|   ├──/scripts
│   |   ├── xmrPayAlert.py         # XMR payout alert script
│   |   └── vmHealthChecks.sh      # Disk space + resource alert
|   ├── /templates
│   |   ├── pbsTemplate.json       # Sample Mattermost webhook JSON
│   |   └── proxmoxTemplate.json   # Uptime Kuma webhook template
├── /docs
│   └── setupGuide.md              # Full installation walkthrough
└── README.md
```

---

## 🧑‍🔧 Requirements

* Proxmox VE 8.x+
* Proxmox Backup Server 3.3+
* Mattermost with incoming webhooks enabled
* Basic shell/cron access on VMs

Optional:

* [Uptime Kuma](https://github.com/louislam/uptime-kuma)
* Custom scripts for health checks, disk space, etc.

---

## 🚀 Quick Start

### Step 1: Create Webhook in Mattermost

1. Go to your Mattermost channel (e.g., `#server-notifications`)
2. Click the **⋯ menu > Integrations > Incoming Webhooks**
3. Click **Add Incoming Webhook**
4. Name it something like `PBS Alerts`, assign it a **bot user**, and save
5. Copy the **Webhook URL** (you’ll use this later)

🔒 Tip: Create one bot per category (e.g. `kumabot` for UptimeKuma, `proxmoxbot` for VE) to separate sources cleanly. You can also create dedicated users and severely limit there functionality to a single channel as Bots can be set to have full access. 

### Step 2: PBS Integration

In the GUI, head down to `Configuration` and `Notifications`. Click the `Add` drop down and select `Webhook`. Pick a name for the Notification, enable and ensure the `Method:` is set to `POST`. Add your webhook you created in Mattermopst for PBS here. 
Under `Headers:` add a new header. The key should be `Content-Type` and set the value to `application/json`

Add the below template to the `Body:` section:

```bash
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

1. In the GUI, head down to `Configuration` and `Notifications`. Click the `Add` drop down and select `Webhook`. Pick a name for the Notification, enable and ensure the `Method:` is set to `POST`. Add your webhook you created in Mattermopst for PBS here. 
Under `Headers:` add a new header. The key should be `Content-Type` and set the value to `application/json`

2. Paste this JSON in the Mattermost Webhook Body:

```json
{
  "text": ":floppy_disk: **PBS Alert from PBS**\nTitle: {{ title }}\nSeverity: **{{ severity }}**\nTime: {{ timestamp }}\nJob Type: {{ fields.type }}\nDatastore: {{ fields.store }}\nTape Pool: {{ fields.tape-pool }}\nTape Drive: {{ fields.tape-drive }}\n\n{{ message }}"
}
```

---

## 💬 Contributing

Pull requests welcome! This project is meant to help others self-host their own NOC-like alerting stack without relying on external tools.

---

## 📜 License

MIT — do what you like. Attribution welcome but not required.

---

## 🙌 Credits

Made with ❤️ by Jake, powered by shell scripts, Proxmox, PBS, and way too much caffeine.
