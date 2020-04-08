const express = require('express');

const app = express();
const port = 8000;
const upstreamServer = process.env['UPSTREAM_SONAR_URL'];
const upstreamHost = new URL(upstreamServer).host;

if (!upstreamServer) {
	console.log('Environment variable UPSTREAM_SONAR_URL must be set');
	process.exit(1);
}

app.use(express.json());

app.post('/api/devices/registrations', (req, res) => res.send('ok'));
app.listen(port, () => console.log(`Listening on port ${port}`));
