# Backend Helper Scripts

This directory contains utility scripts for testing and developing the backend service.

## Files

- **`test_ws.ps1`**: PowerShell script to test the WebSocket connection (`/ws`) by sending a JSON payload and receiving the broadcasted response.
- **`test_ws.sh`**: Bash wrapper script to run `test_ws.ps1` directly from Git Bash or POSIX terminals.

## Usage

### Testing WebSocket Endpoint

Prerequisites: Ensure the backend server is running on `localhost:8080`.

**From PowerShell:**

```powershell
.\scripts\test_ws.ps1
```

**From Git Bash / WSL:**

```bash
powershell -ExecutionPolicy Bypass -File ./scripts/test_ws.ps1
# or
./scripts/test_ws.sh

```
