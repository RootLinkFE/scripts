#!/bin/bash

#------------------------------------------------------------------------------------
#title           :jenkins-notification.sh
#description     :jenkins 构建结束后做消息推送
#author          :giscafer ( http://giscafer.com )
#date            :2019-6-24 10:45:18
# 使用方式：curl http://xxxx.cn/aaa/team/raw/master/cicd/jenkins-notification.sh |bash  -s "3441167a-7xxxxx-4554-982f-92b753s" "console-web" "test" "成功"
#
#------
set -e

function log() {
    echo "$(date):$@"
}

function logStep() {
    echo "$(date):====================================================================================="
    echo "$(date):$@"
    echo "$(date):====================================================================================="
    echo ""
}

function error() {
    local job="$0"      # job name
    local lastline="$1" # line of error occurrence
    local lasterr="$2"  # error code
    log "ERROR in ${job} : line ${lastline} with exit code ${lasterr}"
    # 将来自动发送错误信息
    # SLACK_MSG="FAILURE - appx app version ${VERSION} failed Deployment to ${ENVMSG}"
    # sendSlackNotifications
    exit 1
}

# wechat work webhook robot
function sendNotifications() {
    log $deploytime
    curl  "$webhook_url" \
    -H 'Content-Type: application/json' \
    -X POST --data "$json_data"
}

#----------------------------------------------------------------------------
# Main
#----------------------------------------------------------------------------

trap 'error ${LINENO} ${?};' ERR

# webhook url链接
webhook_url="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?debug=1&key=${webhook_key}"

webhook_key="${1}" # 企业微信群机器人webhook的key，设置到环境变量脱敏
project_name="${2}" #工程名
branch="${3}" #分支
status="${4}" # 构建状态

# 解决容器少8小时问题（按理是容器设置好）
# date_str=$(date "+%Y-%m-%d %H:%M:%S")
# seconds=$(date -d "$date_str" +%s)                       # 得到时间戳
# seconds_new=$(expr $seconds + 28800)                     # 8小时秒数
# deploytime=$(date -d @$seconds_new "+%Y-%m-%d %H:%M:%S") # 获得正确日期格式化
deploytime=$(date "+%Y-%m-%d %H:%M:%S")
commitMessage=$(git log --oneline -n 1)
commitAuthorName=$(git --no-pager show -s --format='%an' HEAD)
commitAuthorEmail=$(git --no-pager show -s --format='%ae' HEAD)

if [ ! -n "$1" ]; then
    echo "没有传信息"
    exit 1
fi

info_content="<font color='info'>$project_name</font> 工程构建【$status】。\n  >分支：<font color='warning'>$branch</font> \n >完成时间：<font color='comment'>$deploytime</font> \n >提交者：<font color='comment'>$commitAuthorName<$commitAuthorEmail></font> \n >提交日记：<font color='comment'>$commitMessage</font> \n >Jenkins Job：[$BUILD_TAG]($BUILD_URL)"
# logStep "info_content=$info_content"
json_data="{  \"msgtype\": \"markdown\", \"markdown\": { \"content\": \"$info_content\" }}"

sendNotifications
