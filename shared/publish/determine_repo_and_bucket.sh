if $ENTERPRISE; then
	if $TESTING; then
		export REPOSITORY_NAME=enterprise-testing
		export S3_BUCKET_NAME=enterprise-testing-NQLVwRlu10n13
	else
		export REPOSITORY_NAME=enterprise
		export S3_BUCKET_NAME=enterprise-NQLVwRlu10n13
	fi
else
	if $TESTING; then
		export REPOSITORY_NAME=oss-testing
		export S3_BUCKET_NAME=passenger-testing
	else
		export REPOSITORY_NAME=oss
		export S3_BUCKET_NAME=passenger
	fi
fi
