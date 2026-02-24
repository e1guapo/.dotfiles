# Make sure to add the following to the ssh config for machines with adb
# servers we want to interact with.
#     LocalForward 5038 localhost:5037 - obe

# Default: adb talks to remote adb servers via SSH
#adb() {
#    command adb "$@"
#}

# Explicitly use local adb server (default 5037)
adb_local() {
    ADB_SERVER_SOCKET=tcp:127.0.0.1:5038 command adb "$@"
}
