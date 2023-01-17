test: env
	swift test --parallel

env:
	echo 'REGION="us-west-1"' > .env.testing
	echo 'BUCKET="vaportestbucket"' >> .env.testing
