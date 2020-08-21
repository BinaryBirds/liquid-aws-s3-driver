test: env
	swift test --enable-test-discovery --parallel

env:
	echo 'REGION="us-west-1"' > .env.testing
	echo 'BUCKET="vaportestbucket"' >> .env.testing
