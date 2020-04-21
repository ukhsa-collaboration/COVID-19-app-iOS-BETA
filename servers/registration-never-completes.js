const express = require('express');

const app = express();
const port = 8000;
const upstreamServer = process.env['UPSTREAM_SONAR_URL'];
const upstreamHost = hostFrom(upstreamServer);

app.use(express.json());

app.post('/api/devices/registrations', (req, res) => res.send('ok'));
app.listen(port, () => console.log(`Listening on port ${port}`));

function hostFrom(upstreamServer) {
  if (!upstreamServer) {
	  console.log('Environment variable UPSTREAM_SONAR_URL must be set');
	  process.exit(1);
  }

	return new URL(upstreamServer).host;
}
