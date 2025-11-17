# SPDX-License-Identifier: GPL-3.0-or-later
#
#	mutt-auth dump <uid>
#
# Read json object from stdin and merge it into $HOME/.mutt/token.<uid>. Update
# the following fields in token file:
#
#	access_token
#	expires_in
#
# If other fields in token file also defined in stdin, overwrite them. Otherwise
# leave them untouched.
#

cat >.token-$$

uid=$1
token=token.$uid

[ -n "$uid" ] || die 'missing uid'

token_error=$(jq -r '.error // ""' <.token-$$)
token_error_mesg=$(jq -r '.error_description // ""' <.token-$$)

[ -n "$token_error" ] && [ -z "$token_error_mesg" ] && die "$token_error"
[ -n "$token_error" ] && die "$token_error, $token_error_mesg"

token_access=$(jq -r .access_token <.token-$$)
token_refresh=$(jq -r '.refresh_token // ""' <.token-$$)
token_expire=$(jq -r .expires_in <.token-$$)
token_server=$(jq -r '.server // ""' <.token-$$)

if [ -z "$token_refresh" ] || [ -z "$token_server" ]; then
	[ ! -s $token ] && die "required token file at '$token' is missing"
	gpg -dqr $uid $token >.token-old-$$
fi

token_refresh=${token_refresh:-$(grep "^refresh$TAB" .token-old-$$ | cut -f2)}
token_server=${token_server:-$(grep "^server$TAB" .token-old-$$ | cut -f2)}
token_expire=$(( $(awk 'BEGIN { print systime() }') + token_expire ))

cat <<EOF | gpg -er $uid >$token
access	$token_access
refresh	$token_refresh
expire	$token_expire
server	$token_server
EOF
