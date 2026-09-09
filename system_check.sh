#!/usr/bin/env bash
# System & Hardening Check Script

echo "=== SYSTEM INFORMATION ==="
echo "User: $(whoami)"
echo "Hostname: $(hostname)"
echo "Working Directory: $(pwd)"
echo "Kernel: $(uname -a)"
echo "Uptime: $(uptime)"
echo ""

echo "=== HARDENING & PERMISSIONS CHECK ==="
touch test.txt
chmod 600 test.txt
ls -l test.txt
echo ""

echo "=== PROCESS CHECK ==="
ps aux | head -n 5