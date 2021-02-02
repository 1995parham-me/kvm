#!/bin/bash
# In The Name of God
# ========================================
# [] File Name : arch-latest.sh
#
# [] Creation Date : 02-02-2021
#
# [] Created By : Parham Alvani <parham.alvani@gmail.com>
# =======================================

most_recent=$(curl -Ls 'https://gitlab.archlinux.org/archlinux/arch-boxes/-/jobs/artifacts/master/browse/output?job=build:secure' | grep cloudimg | grep -vi sha256 | sed "s/.* href=\"\(.*\)\".*/\1/" | tail -1 | sed "s|artifacts/file|artifacts/raw|")
curl -LO  "https://gitlab.archlinux.org$most_recent"{,.SHA256}
