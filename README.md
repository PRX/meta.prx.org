# META.prx.org

[![Build Status](https://snap-ci.com/PRX/meta.prx.org/branch/master/build_image)](https://snap-ci.com/PRX/meta.prx.org/branch/master)

### Acceptance Tests

This repo houses the acceptance tests for all PRX services.  The tests will confirm that everything in the staging environment is playing together nicely, and then assemble a complete list of staging-service-versions to deploy to production, via SnapCI.

To run the tests locally:

```
cp env-example .env
vi .env # and enter your staging hosts
bundle exec rake test

# or run a single subset of tests
bundle exec rake test:dovetail
bundle exec rake test:publish
bundle exec rake test:upload
```

### Load Tests

Non-CI load testing is also housed in this repo.  To test dovetail, just run `bundle exec rake load:dovetail`.  You can also specify the total-stitch-requests to make, and the concurrency of downloads: `bundle exec rake load:dovetail[200,10]`.

### Metadata for PRX Services

The meta wiki and issue tracker are used to cover cross-service project management and documentation.
