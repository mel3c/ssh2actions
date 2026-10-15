# SSH to GitHub Actions

This GitHub Action offers you connect to GitHub Actions VM via SSH for interactive debugging

## Features

- Support Ubuntu and macOS
- Provides two optional SSH connection methods, tmate and ngrok
- Support self-hosted tmate server
- Proceed to the next step to stay connected
- Send SSH connection info to Telegram

## Usage

### Connect to Github Actions VM via SSH by using [tmate](https://tmate.io)

```yaml
- name: Start SSH via tmate
  uses: mel3c/ssh2actions@main
  # Send connection info to Telegram (optional)
  # You can find related documents here: https://core.telegram.org/bots
  env:
    TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
    TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
```

### Use a self-hosted tmate server

By default, sessions are relayed through the public tmate.io server. Set the following environment variables to use your own tmate server instead:

```yaml
- name: SSH connection to Actions
  if: (github.event.inputs.ssh == 'true')
  uses: mel3c/ssh2actions@main
  env:
    # tmate server address (required to enable self-hosted mode)
    TMATE_SERVER_HOST: ${{ secrets.TMATE_SERVER_HOST }}
    TMATE_SERVER_PORT: ${{ secrets.TMATE_SERVER_PORT }}

    # Server host key fingerprints (at least one is recommended
    # to pin the server identity)
    TMATE_SERVER_RSA_FP: ${{ secrets.TMATE_SERVER_RSA_FP }}
    TMATE_SERVER_ED25519_FP: ${{ secrets.TMATE_SERVER_ED25519_FP }}

    # Send connection info to Telegram (optional)
    TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
    TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
```

> Tip: Run `touch /tmp/continue` in the SSH session to let the workflow continue to the next step.

### Connect to Github Actions VM via SSH by using [ngrok](https://ngrok.com)

```yaml
- name: Start SSH via ngrok
  uses: mel3c/ssh2actions@main
  with:
    mode: ngrok
  env:
    # After sign up on the https://ngrok.com
    # You can find this token here: https://dashboard.ngrok.com/auth/your-authtoken
    NGROK_TOKEN: ${{ secrets.NGROK_TOKEN }}
    
    # ngrok server region [us, eu, au, ap, sa, jp, in] (optional, default: us)
    # You can find this server region here: https://ngrok.com/docs#global-locations
    NGROK_REGION: us

    # This password you will use when authorizing via SSH
    SSH_PASSWORD: ${{ secrets.SSH_PASSWORD }}

    # Send connection info to Telegram (optional)
    # You can find related documents here: https://core.telegram.org/bots
    TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
    TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
```

## Lisence

[MIT](https://github.com/P3TERX/ssh2actions/blob/main/LICENSE) © P3TERX
