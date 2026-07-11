#!/bin/bash
set -euo pipefail

EVENT="${1:-goal}"

case "$EVENT" in
    goal)        NOTIF="goal" ;;
    kickoff)     NOTIF="kickoff" ;;
    halftime|ht) NOTIF="halftime" ;;
    2ndhalf|sh)  NOTIF="secondHalf" ;;
    fulltime|ft) NOTIF="fulltime" ;;
    *)
        echo "Usage: $0 {goal|kickoff|halftime|2ndhalf|fulltime}"
        exit 1
        ;;
esac

# Ship a tiny ad hoc binary that posts a distributed notification
DIR=$(mktemp -d)
cat > "$DIR/main.swift" <<SWIFT
import Foundation
let event = CommandLine.arguments[1]
DistributedNotificationCenter.default().post(
    name: Notification.Name("com.premierleaguebar.testEvent"),
    object: event
)
CFRunLoopRunInMode(.defaultMode, 0.5, false)
SWIFT

cd "$DIR"
swiftc -o trigger main.swift 2>/dev/null
"$DIR/trigger" "$NOTIF" 2>/dev/null
rm -rf "$DIR"
echo "Triggered: $NOTIF"
