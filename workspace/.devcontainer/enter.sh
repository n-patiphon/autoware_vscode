#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(basename "$(dirname "$SCRIPT_DIR")")"
docker exec -it "$PARENT_DIR" bash
