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

Use the `PROFILE_TIME` environment variable to trigger profiling information as the tests run:
```
PROFILE_TIME=1 bundle exec rake test:metrics
```

### Load Tests

Non-CI load testing is also housed in this repo.  To test dovetail, just run `bundle exec rake load:dovetail`.  You can also specify the total-stitch-requests to make, and the concurrency of downloads: `bundle exec rake load:dovetail[200,10]`.

### Metadata for PRX Services

The meta issue tracker is used to cover cross-service project management.

### Software Health

<table>
<thead>
<tr>
<td></td>
<td>Dependencies</td>
<td>Coverage</td>
<td>Build</td>
<td>Climate</td>
</tr>    
</thead>
<tbody>
<tr>
<td><a href="https://github.com/PRX/cms.prx.org">cms.prx.org</a></td>
<td><a href='https://gemnasium.com/PRX/cms.prx.org'><img src="https://gemnasium.com/PRX/cms.prx.org.svg" alt="Dependency Status" /></a>
</td>
<td><a href='https://coveralls.io/r/PRX/cms.prx.org?branch=master'><img src='https://coveralls.io/repos/PRX/cms.prx.org/badge.svg?branch=master' alt='Coverage Status' /></a></td>
<td><a href="https://travis-ci.org/PRX/cms.prx.org"><img src="https://travis-ci.org/PRX/cms.prx.org.svg?branch=master" /></a></td>
<td><a href="https://codeclimate.com/github/PRX/cms.prx.org"><img src="https://codeclimate.com/github/PRX/cms.prx.org/badges/gpa.svg" /></a></td>
</tr>

<tr>
<td><a href="https://github.com/PRX/upload.prx.org">upload.prx.org</a></td>
<td><a href='https://gemnasium.com/PRX/upload.prx.org'><img src="https://gemnasium.com/PRX/upload.prx.org.svg" alt="Dependency Status" /></a>
</td>
<td><a href='https://coveralls.io/r/PRX/upload.prx.org?branch=master'><img src='https://coveralls.io/repos/PRX/upload.prx.org/badge.svg?branch=master' alt='Coverage Status' /></a></td>
<td><a href="https://travis-ci.org/PRX/upload.prx.org"><img src="https://travis-ci.org/PRX/upload.prx.org.svg?branch=master" /></a></td>
<td><a href="https://codeclimate.com/github/PRX/upload.prx.org"><img src="https://codeclimate.com/github/PRX/upload.prx.org/badges/gpa.svg" /></a></td>
</tr>

<tr>
<td><a href="https://github.com/PRX/tower.radiotopia.fm">tower.radiotopia.fm</a></td>
<td><a href='https://gemnasium.com/PRX/tower.radiotopia.fm'><img src="https://gemnasium.com/PRX/tower.radiotopia.fm.svg" alt="Dependency Status" /></a></a>
</td>
<td><a href='https://coveralls.io/r/PRX/tower.radiotopia.fm?branch=master'><img src='https://coveralls.io/repos/PRX/tower.radiotopia.fm/badge.svg?branch=master' alt='Coverage Status' /></a></td>
<td> n/a <a href="https://travis-ci.org/PRX/tower.radiotopia.fm"><!--<img src="https://travis-ci.org/PRX/tower.radiotopia.fm.svg?branch=master" />--></a></td>
<td><a href="https://codeclimate.com/github/PRX/tower.radiotopia.fm"><img src="https://codeclimate.com/github/PRX/tower.radiotopia.fm/badges/gpa.svg" /></a></td>
</tr>

<tr>
<td><a href="https://github.com/PRX/rack-prx_auth">rack-prx_auth</a></td>
<td><a href='https://gemnasium.com/PRX/rack-prx_auth'><img src="https://gemnasium.com/PRX/rack-prx_auth.svg" alt="Dependency Status" /></a></a>
</td>
<td><a href='https://coveralls.io/r/PRX/rack-prx_auth?branch=master'><img src='https://coveralls.io/repos/PRX/rack-prx_auth/badge.svg?branch=master' alt='Coverage Status' /></a></td>
<td><a href="https://travis-ci.org/PRX/rack-prx_auth"><img src="https://travis-ci.org/PRX/rack-prx_auth.svg?branch=master" /></a></td>
<td><a href="https://codeclimate.com/github/PRX/rack-prx_auth"><img src="https://codeclimate.com/github/PRX/rack-prx_auth/badges/gpa.svg" /></a></td>
</tr>
</tbody>
</table>

