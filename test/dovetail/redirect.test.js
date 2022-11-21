const url = require('url');
const querystring = require('querystring');
const fetch = require('node-fetch');
const uuid = require('uuid');

describe('dovetail - redirect', () => {
  const TEST_PATH = `${TEST_FEEDER_PODCAST}/${TEST_FEEDER_EPISODE}/test-file.mp3`;
  const TEST_URL = `${DOVETAIL_HOST}/${TEST_PATH}`;

  const headers = suffix => {
    const agent = suffix ? `${USER_AGENT} / ${suffix}` : USER_AGENT;
    return { 'user-agent': agent };
  };

  it('redirects to the cdn', async () => {
    const res = await fetch(TEST_URL, { redirect: 'manual', headers: headers(uuid.v4()) });

    expect(res.status).toEqual(302);

    expect(res.headers.get('cache-control')).toEqual('max-age=0, private, must-revalidate');
    expect(res.headers.get('x-program')).toEqual(TEST_FEEDER_PODCAST);
    expect(res.headers.get('x-episode')).toEqual(TEST_FEEDER_EPISODE);
    expect(res.headers.has('x-placement')).toBeTruthy();

    // our UA was unique, so there will be an impression
    expect(res.headers.has('x-impressions')).toBeTruthy();
    expect(res.headers.has('x-depressions')).toBeFalsy();
    expect(res.headers.has('x-repressions')).toBeFalsy();

    const loc = url.parse(res.headers.get('location'));
    const parts = loc.pathname.split('/').filter(p => p);
    const query = querystring.parse(loc.query);

    expect(loc.protocol).toMatch(/^https?:/);
    expect(loc.host).toContain('dovetail3-cdn');

    // first path segment is optionally a CDN region
    if (parts[0] !== TEST_FEEDER_PODCAST) {
      parts.shift();
    }

    // <podcast_id>/<episode_guid>/<arrangement_digest>/<filename>
    expect(parts[0]).toEqual(TEST_FEEDER_PODCAST);
    expect(parts[1]).toEqual(TEST_FEEDER_EPISODE);
    expect(parts[2]).toMatch(/^[0-9a-zA-Z_-]+$/);
    expect(parts[3]).toEqual('test-file.mp3');

    // listener episode
    expect(query.le).toMatch(/^[0-9a-zA-Z_-]+$/);
    expect(query.exp).toMatch(/^[0-9]+$/);

    // expiration epoch should be "soon-ish"
    const now = Math.round(Date.now() / 1000);
    expect(parseInt(query.exp, 10)).toBeGreaterThan(now - 60);
    expect(parseInt(query.exp, 10)).toBeLessThan(now + 60 * 60 * 25);
  });
});
