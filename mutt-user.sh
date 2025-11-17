#!/usr/local/bin/shimp
# SPDX-License-Identifier: GPL-3.0-or-later

trap 'rm -f .*-$$' EXIT

set -e

. $(which-lib39)

cd $HOME/.mutt

addr=$1

[ -n "$addr" ] || die 'missing addr'

find -H addr -mindepth 1 -name "$addr*" ! -name '*.patch' >.find-$$

if [ ! -s .find-$$ ]; then
	die "no matching config found for '$addr'"

elif [ $(cat .find-$$ | wc -l) -gt 1 ]; then
	ambig=$(xargs -I{} sh -c 'printf "\n  %s" $(basename {})' <.find-$$)

	die "ambiguous address '$addr', can be:$ambig"
fi

profile=$(cat .find-$$)
patch=$profile.patch

rm -f user*

ln -s $profile user
ln -s /dev/null user-$(basename $profile)
[ -f $patch ] && ln -s $patch user-patch || ln -s /dev/null user-patch
