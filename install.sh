#!/bin/bash
set -e

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
make -C "$repo_root" install
