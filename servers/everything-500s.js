const express = require('express');

const app = express();
const port = 8000;

app.post('/api/devices/registrations', fail);
app.post('/api/devices', fail);
app.listen(port, () => console.log(`Listening on port ${port}`));

function fail() {
	throw new Error('nope');
}
