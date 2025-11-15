#!/usr/local/bin/shimp
# SPDX-License-Identifier: GPL-3.0-or-later

set -e

. $(which-lib39)

command=$1
prefix=$(which-absdir $0)/auth
script=$prefix/$command.sh

test -n "$command" || die 'missing command'
test -x $script || die "unknown command '$command'"

shift
. $script
