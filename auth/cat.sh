# SPDX-License-Identifier: GPL-3.0-or-later
#
#	mutt-auth cat <uid>
#
# Print token to stdout, refresh it if it's expired. Token is read from
# $HOME/.mutt/<uid>.token.
#

uid=$1
token=$uid.token

[ -n "$uid" ] || die 'missing uid'
[ -s $token ] || die "no token found at '$token'"

gpg -dqr $uid $token >.$token-$$

expire=$(grep "^expire$TAB" .$token-$$ | cut -f2)
expire=$(( expire - 60 ))
now=$(awk 'BEGIN { print systime() }')

if [ $now -gt $expire ]; then
	$entry refresh $uid
	$entry cat $uid
	exit
fi

grep "^access$TAB" .$token-$$ | cut -f2
