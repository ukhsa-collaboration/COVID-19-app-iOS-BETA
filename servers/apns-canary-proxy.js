const express = require('express');
const { exec } = require('child_process');

const app = express();
const port = 8001;


app.use(express.json());

app.post('/ping/:token', async (req, res) => {
	const token = req.params.token;
	console.log('Got request to ping device', token);
	res.send('');

	exec('./send-to-apns ' + token, (error, stdout, stderr) => {
		console.log('pu.sh stdout:\n', stdout);
		console.log('pu.sh stderr:\n', stderr);

		if (error) {
			console.error('pu.sh failed');
			console.error(error);
		}
	});
});

app.listen(port, () => console.log(`Listening on port ${port}`));
