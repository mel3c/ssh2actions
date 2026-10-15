#!/usr/bin/env bash
#
# Copyright (c) 2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/ssh2actions
# File name：tmate2actions.sh
# Description: Connect to Github Actions VM via SSH by using tmate
# Version: 2.1
#

set -e
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
INFO="[${Green_font_prefix}INFO${Font_color_suffix}]"
ERROR="[${Red_font_prefix}ERROR${Font_color_suffix}]"
TMATE_SOCK="/tmp/tmate.sock"
TELEGRAM_LOG="/tmp/telegram.log"
CONTINUE_FILE="/tmp/continue"

# Install tmate on macOS or Ubuntu
echo -e "${INFO} Setting up tmate ..."
if [[ -n "$(uname | grep Linux)" ]]; then
    if [[ -x "$(command -v apt-get)" ]]; then
        sudo apt-get -qq update
        sudo apt-get -qq install -y tmate
    else
        curl -fsSL https://raw.githubusercontent.com/tmate-io/tmate/master/scripts/install.sh | bash
    fi
elif [[ -x "$(command -v brew)" ]]; then
    brew install tmate
else
    echo -e "${ERROR} This system is not supported!"
    exit 1
fi

# Generate ssh key if needed
[[ -e ~/.ssh/id_rsa ]] || ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -N ""

# Use self-hosted tmate server (optional)
# Set TMATE_SERVER_HOST to use your own tmate server instead of the public tmate.io server
if [[ -n "${TMATE_SERVER_HOST}" ]]; then
    echo -e "${INFO} Using self-hosted tmate server: ${TMATE_SERVER_HOST}:${TMATE_SERVER_PORT:-2200} ..."
    {
        echo "set -g tmate-server-host \"${TMATE_SERVER_HOST}\""
        [[ -n "${TMATE_SERVER_PORT}" ]] && echo "set -g tmate-server-port \"${TMATE_SERVER_PORT}\""
        [[ -n "${TMATE_SERVER_RSA_FP}" ]] && echo "set -g tmate-server-rsa-fingerprint \"${TMATE_SERVER_RSA_FP}\""
        [[ -n "${TMATE_SERVER_ED25519_FP}" ]] && echo "set -g tmate-server-ed25519-fingerprint \"${TMATE_SERVER_ED25519_FP}\""
    } > ~/.tmate.conf
fi

# Run deamonized tmate
echo -e "${INFO} Running tmate..."
tmate -S ${TMATE_SOCK} new-session -d
tmate -S ${TMATE_SOCK} wait tmate-ready

# Print connection info
TMATE_SSH=$(tmate -S ${TMATE_SOCK} display -p '#{tmate_ssh}')
TMATE_WEB=$(tmate -S ${TMATE_SOCK} display -p '#{tmate_web}')
MSG="
*GitHub Actions - tmate session info:*

⚡ *CLI:*
\`${TMATE_SSH}\`

🔗 *URL:*
${TMATE_WEB}

🔔 *TIPS:*
Run '\`touch ${CONTINUE_FILE}\`' to continue to the next step.

📦 *Repo:*
\`${GITHUB_REPOSITORY}\`

🏃 *Run:*
[Run ${GITHUB_RUN_ID}](https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID})
"

if [[ -n "${TELEGRAM_BOT_TOKEN}" && -n "${TELEGRAM_CHAT_ID}" ]]; then
    echo -e "${INFO} Sending message to Telegram..."
    curl -sSX POST "${TELEGRAM_API_URL:-https://api.telegram.org}/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=Markdown" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${MSG}" >${TELEGRAM_LOG}
    TELEGRAM_STATUS=$(cat ${TELEGRAM_LOG} | jq -r .ok)
    if [[ ${TELEGRAM_STATUS} != true ]]; then
        echo -e "${ERROR} Telegram message sending failed: $(cat ${TELEGRAM_LOG})"
    else
        echo -e "${INFO} Telegram message sent successfully!"
    fi
fi

while ((${PRT_COUNT:=1} <= ${PRT_TOTAL:=10})); do
    SECONDS_LEFT=${PRT_INTERVAL_SEC:=10}
    while ((${PRT_COUNT} > 1)) && ((${SECONDS_LEFT} > 0)); do
        echo -e "${INFO} (${PRT_COUNT}/${PRT_TOTAL}) Please wait ${SECONDS_LEFT}s ..."
        sleep 1
        SECONDS_LEFT=$((${SECONDS_LEFT} - 1))
    done
    echo "-----------------------------------------------------------------------------------"
    echo "To connect to this session copy and paste the following into a terminal or browser:"
    echo -e "CLI: ${Green_font_prefix}${TMATE_SSH}${Font_color_suffix}"
    echo -e "URL: ${Green_font_prefix}${TMATE_WEB}${Font_color_suffix}"
    echo -e "TIPS: Run 'touch ${CONTINUE_FILE}' to continue to the next step."
    echo "-----------------------------------------------------------------------------------"
    PRT_COUNT=$((${PRT_COUNT} + 1))
done

while [[ -S ${TMATE_SOCK} ]]; do
    sleep 1
    if [[ -e ${CONTINUE_FILE} ]]; then
        echo -e "${INFO} Continue to the next step."
        exit 0
    fi
done

# ref: https://github.com/csexton/debugger-action/blob/master/script.sh
