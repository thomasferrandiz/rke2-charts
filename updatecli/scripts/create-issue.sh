#!/usr/bin/env bash

TARGET_REPOSITORY="rancher/rke2"
BODY="Url of the failed run: ${UPDATECLI_GITHUB_WORKFLOW_URL}"

create-issue() {
    title=$1

    #check if issue already exists
    issues=$(gh issue list -R ${TARGET_REPOSITORY} \
                --search "is:open ${title}" \
                --app rke2-issues-updatecli --json number --jq ".[].number" | wc -l)

    if [[ $issues = 0 ]]; then
        echo "Creating issue for: $title"
        gh issue create -R ${TARGET_REPOSITORY} \
            --title "${title}" \
            --body "${BODY}"
    else
        echo "Issue already exists for: ${title}"
    fi
}

export -f create-issue
