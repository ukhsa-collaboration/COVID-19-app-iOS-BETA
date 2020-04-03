const express = require('express');
const fetch = require('node-fetch');

const app = express();
const port = 8000;
const upstreamServer = process.env['UPSTREAM_SONAR_URL'];
const upstreamHost = new URL(upstreamServer).host;

if (!upstreamServer) {
	console.log('Environment variable UPSTREAM_SONAR_URL must be set');
	process.exit(1);
}

app.use(express.json());

app.post('/api/devices/registrations', async (req, res) => {
	console.log('Immediately responding OK to /api/devices/registrations. Delaying the request to upstream by 15 seconds.');
	console.log('Put the iOS app into the background now.');

	res.send('{}');

	await delay(15);

	const url = upstreamServer + '/api/devices/registrations';
	console.log('Forwarding to', url);

	const upstreamResponse = await fetch(url, {
		method: 'POST',
		body: JSON.stringify(req.body),
		headers: {...req.headers, host: upstreamHost},
	});
	const responseBody = await upstreamResponse.text();

	if (!upstreamResponse.ok) {
		console.error('Upstream failed with status', upstreamResponse.status);
		console.error('Upstream response body', responseBody);
		res.status(upstreamResponse.status).send();
		return;
	}

	console.log('Upstream succeeded with body', responseBody);
});

app.post('/api/devices', forwardWithDelay(45));
app.listen(port, () => console.log(`Listening on port ${port}`));


function forwardWithDelay(delaySecs) {
	return async (req, res) => {
		const url = upstreamServer + req.path;
		console.log('Will forward to', url, 'after', delaySecs, 'seconds');
		await delay(delaySecs);

		console.log('Forwarding to', url);
		const upstreamResponse = await fetch(url, {
			method: 'POST',
			body: JSON.stringify(req.body),
			headers: {...req.headers, host: upstreamHost},
		});
	
		const responseBody = await upstreamResponse.text();
	
		if (!upstreamResponse.ok) {
			console.error('Upstream failed with status', upstreamResponse.status);
			console.error('Upstream response body', responseBody);
			res.status(upstreamResponse.status).send();
			return;
		}
	
		console.log('Upstream succeeded with body', responseBody);
		res.send(responseBody);
	};
}

function delay(secs) {
	return new Promise(resolve => setTimeout(resolve, secs * 1000));
}
