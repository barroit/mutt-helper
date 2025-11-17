# SPDX-License-Identifier: GPL-3.0-or-later
#
#	mutt-auth refresh <uid>
#
# Fetch new token from server. Server is read from $HOME/.mutt/token.<uid>
#

uid=$1
token=token.$uid

[ -n "$uid" ] || die 'missing uid'
[ -s $token ] || die "no token found at '$token'"

gpg -dqr $uid $token >.token-old-$$

server=$(grep "^server$TAB" .token-old-$$ | cut -f2)
refresh=$(grep "^refresh$TAB" .token-old-$$ | cut -f2)

[ -z "$server" ] || [ -z "$refresh" ] && die "broken token file '$token'"

param=param.$server
client=client.$server

[ -s $param ] || die "missing '$param'"
[ -s $client ] || die "missing '$client'"

! blk39_has token $param && die "missing token in '$param'"

gpg -dqr $uid $client >.$client-$$

id=$(grep "^id$TAB" .$client-$$ | cut -f2)
sec=$(grep "^sec$TAB" .$client-$$ | cut -f2)

[ -n "$id" ] || die "missing 'id' in $client"

cat <<EOF >.token-data-in-$$
client_id=$id&
grant_type=refresh_token&
refresh_token=$refresh&
EOF

[ -n "$sec" ] && printf 'client_secret=%s&\n' $sec >>.token-data-in-$$

tr -d '\n' <.token-data-in-$$ | sed 's/&$//' >.token-data-$$

curl -s -X POST -H 'Content-Type: application/x-www-form-urlencoded' \
     --data-binary @.token-data-$$ $(blk39_find token $param) >.token-$$

$entry dump $uid <.token-$$
