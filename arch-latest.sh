#!/bin/bash

echo "dowload latest release of archlinux from gitlab.archlinux.org"

most_recent=$(curl -Ls 'https://gitlab.archlinux.org/archlinux/arch-boxes/-/jobs/artifacts/master/browse/output?job=build:secure' |
	grep cloudimg | grep -vi sha256 | grep -vi sig | sed "s/.* href=\"\(.*\)\".*/\1/" | tail -1 | sed "s|artifacts/file|artifacts/raw|")
curl -LO "https://gitlab.archlinux.org$most_recent"{,.SHA256}
