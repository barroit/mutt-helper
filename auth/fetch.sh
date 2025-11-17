# SPDX-License-Identifier: GPL-3.0-or-later
#
#	mutt-auth fetch <server> <uid>
#
# Fetch token from <server>'s oauth 2 endpoint and store it in token/<uid> under
# $HOME/.mutt. GnuPG is used to encrypt this token file. You must have a uid
# matches <uid> in gpg keys, as this script uses that to identify which key to
# use for encryption.
#
# This script requires $HOME/.mutt/client/<uid>. This file must be encrypted by
# GnuPG, and your <uid> key has correct [E] subkey to decrypt it. Fill it with
# id, optional sec if your server requires one, and separate columns with tab:
#
#	id	wvX6wO17Ow71-AwphnnPn6LZg377ALhwJn....apps.googleusercontent.com
#	sec	9S4aV6-x-O6A1nvQKov0nSa7h9pn0P96aZK
#
# id
#	ID of OAuth 2.0 client.
# sec
#	Secret of OAuth 2.0 client. Public clients don't need this, but google
#	requires it regardless of client type.
#
# It also requires param.<server>, this file stores endpoint parameters of
# server. Example for Google server:
#
#	https://github.com/barroit/etc/blob/master/mutt/param.google
#
# Client creation guide:
#
#	https://github.com/muttmua/mutt/
#	blob/master/contrib/mutt_oauth2.py.README
#

server=$1
uid=$2

[ -n "$server" ] || die 'missing server'
[ -n "$uid" ] || die 'missing uid'

param=param.$server
client=client/$uid

[ -s $param ] || die "missing '$param'"
[ -s $client ] || die "missing '$client'"

! blk39_has code $param && die "missing code in '$param'"
! blk39_has token $param && die "missing token in '$param'"
! blk39_has scope $param && die "missing scope in '$param'"

gpg -dqr $uid $client >.client-$$

id=$(grep "^id$TAB" .client-$$ | cut -f2)
sec=$(grep "^sec$TAB" .client-$$ | cut -f2)

[ -n "$id" ] || die "missing 'id' in $client"

port=$($prefix/pickport.py)
redirect=http://localhost:$port
state=$(openssl rand -hex 16)

verifier=$(openssl rand -base64 96 | tr +/ -_ | tr -d '\n')
challenge=$(printf '%s' $verifier | openssl dgst -sha256 -binary | \
	    openssl base64 | tr +/ -_ | tr -d '=')

cat <<EOF >.code-url-$$
$(blk39_find code $param)?
client_id=$id&
redirect_uri=$(urlsafe $redirect)&
response_type=code&
scope=$(blk39_find scope $param | oneline | urlsafe)&
state=$state&
login_hint=$(urlsafe $uid)&
code_challenge=$challenge&
code_challenge_method=S256&
EOF

blk39_keys $param | grep ^code_ | sed 's/^code_//' | while read key; do
	printf '%s=%s&\n' $key $(blk39_find code_$key $param) >>.code-url-$$
done

open $(tr -d '\n' <.code-url-$$ | sed 's/&$/\n/') >/dev/null
info 'auth url opened in browser, waiting for user consent...'

cat <<'EOF' | $prefix/catport.js $port 'text/html; charset=utf-8' >.code-$$
<html>
  <head>
    <title>^o^</title>
  </head>
  <body>
    <h1>Authorization request completed</h1>
    <h2>No need to keep this tab open anymore</h2>
  </body>
</html>
EOF

code_state=$(grep "^state$TAB" .code-$$ | cut -f2)
code=$(grep "^code$TAB" .code-$$ | cut -f2)
code_error=$(grep "^error$TAB" .code-$$ | cut -f2)
code_error_mesg=$(grep "^error_description$TAB" .code-$$ | cut -f2 | tr + ' ')

[ "$code_state" = $state ] || die 'forgery occurred, try this again'
[ -n "$code_error" ] && [ -z "$code_error_mesg" ] && die "$code_error"
[ -n "$code_error" ] && die "$code_error, $code_error_mesg"

cat <<EOF >.token-data-in-$$
client_id=$id&
code=$code&
grant_type=authorization_code&
redirect_uri=$redirect&
code_verifier=$verifier&
EOF

[ -n "$sec" ] && printf 'client_secret=%s&\n' $sec >>.token-data-in-$$

blk39_keys $param | grep ^token_ | sed 's/^token_//' | while read key; do
	printf '%s=%s&\n' $key \
			  $(blk39_find token_$key $param) >>.token-data-in-$$
done

tr -d '\n' <.token-data-in-$$ | sed 's/&$//' >.token-data-$$

curl -s -X POST -H 'Content-Type: application/x-www-form-urlencoded' \
     --data-binary @.token-data-$$ $(blk39_find token $param) >.token-in-$$

jq ". + { \"server\": \"$server\" }" .token-in-$$ >.token-$$

$entry dump $uid <.token-$$
