#!/usr/bin/env python3
import os
import sys
import pty
import signal

# Path to the log file
LOG_FILE = "/tmp/clicom_monitor.log"

def main():
    # Use the current user shell or default to bash
    shell = os.environ.get('SHELL', '/bin/bash')
    
    print(f"\033[92m[Clicom] Session recording started.\033[0m")
    print(f"\033[90mOutput is being saved to {LOG_FILE}\033[0m")
    print(f"\033[90mType 'exit' or Ctrl+D to stop recording.\033[0m")

    # Open log file for binary writing
    with open(LOG_FILE, 'wb') as f:
        def read_master(fd):
            # Read output from terminal
            data = os.read(fd, 1024)
            # Write to log file
            f.write(data)
            f.flush()
            # Return data to be displayed in user's terminal
            return data

        # Spawn the shell inside a pseudo-terminal
        pty.spawn([shell], read_master)

    print(f"\n\033[92m[Clicom] Recording stopped.\033[0m")

if __name__ == "__main__":
    # Handle terminal resize signals
    def resize_handler(signum, frame):
        pass 
    signal.signal(signal.SIGWINCH, resize_handler)
    
    main()
