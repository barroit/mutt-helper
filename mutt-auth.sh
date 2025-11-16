#!/usr/local/bin/shimp
# SPDX-License-Identifier: GPL-3.0-or-later

set -e

. $(which-lib39)

command=$1
prefix=$(which-absdir $0)/auth
script=$prefix/$command.sh

[ -n "$command" ] || die 'missing command'
[ -f $script ] || die "unknown command '$command'"

trap 'rm -f .*-$$' EXIT

cd $HOME/.mutt

shift
. $script
