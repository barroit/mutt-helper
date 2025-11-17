#!/usr/bin/env node
/* SPDX-License-Identifier: GPL-3.0-or-later */

import { readFileSync } from 'node:fs'
import { createServer } from 'node:http'
import { argv, exit } from 'node:process'
import { text } from 'node:stream/consumers'

if (argv.length < 3) {
	console.fatal('usage: catport <port> [bodytype]')
	exit(1)
}

const port = argv[2]
let type
let hint

if (argv.length == 4) {
	type = argv[3]
	hint = readFileSync(0)
}

let raise
let req
let res

const server = createServer((req_in, res_in) =>
{
	req = req_in
	res = res_in
	raise()
})

await new Promise(cb =>
{
	raise = cb
	server.listen(port, '127.0.0.1')
})

res.statusCode = 200
res.setHeader('Connection', 'close')

if (argv.length == 4) {
	res.setHeader('Content-Type', type)
	res.setHeader('Content-Length', hint.length)
}

res.end(hint)

switch (req.method) {
case 'GET':
	const url = new URL(req.url, `http://${ req.headers.host }`)
	const params = url.searchParams
	const iter = params.entries()

	for (const [ key, val ] of iter)
		console.log(`${ key }\t${ val }`)
}

exit()
