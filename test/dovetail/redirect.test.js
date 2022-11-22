const url = require('url');
const querystring = require('querystring');
const fetch = require('node-fetch');
const uuid = require('uuid');

describe('dovetail - redirect', () => {
  const TEST_PATH = `${TEST_FEEDER_PODCAST}/${TEST_FEEDER_EPISODE}/test-file.mp3`;
  const TEST_URL = `${DOVETAIL_HOST}/${TEST_PATH}`;

  // unique user-agent headers
  const opts = { redirect: 'manual', headers: {} };
  beforeEach(() => {
    opts.headers['user-agent'] = `${USER_AGENT} / ${uuid.v4()}`;
  });

  const hasImpressions = r =>
    ['x-impressions', 'x-repressions', 'x-depressions'].map(k => r.headers.has(k));

  it('redirects to the cdn', async () => {
    const res = await fetch(TEST_URL, opts);

    expect(res.status).toEqual(302);
    expect(res.headers.get('cache-control')).toEqual('max-age=0, private, must-revalidate');
    expect(res.headers.get('x-program')).toEqual(TEST_FEEDER_PODCAST);
    expect(res.headers.get('x-episode')).toEqual(TEST_FEEDER_EPISODE);
    expect(res.headers.has('x-placement')).toBeTruthy();

    // our UA was unique, so there will be an impression
    expect(hasImpressions(res)).toEqual([true, false, false]);

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

  it('returns repressions for subsequent requests', async () => {
    const res1 = await fetch(TEST_URL, opts);
    const res2 = await fetch(TEST_URL, opts);
    const res3 = await fetch(TEST_URL, opts);

    expect(res1.status).toEqual(302);
    expect(res2.status).toEqual(302);
    expect(res3.status).toEqual(302);

    // only the first response has x-impressions
    expect(hasImpressions(res1)).toEqual([true, false, false]);
    expect(hasImpressions(res2)).toEqual([false, true, false]);
    expect(hasImpressions(res3)).toEqual([false, true, false]);

    // urls should all match _except_ for the expiration epoch
    const loc1 = res1.headers.get('location').replace(/exp=[0-9]+/, '');
    const loc2 = res2.headers.get('location').replace(/exp=[0-9]+/, '');
    const loc3 = res3.headers.get('location').replace(/exp=[0-9]+/, '');
    expect(loc1).toEqual(loc2);
    expect(loc1).toEqual(loc3);
  });

  it('returns depressions for noImp requests', async () => {
    const res = await fetch(`${TEST_URL}?noImp`, opts);

    expect(res.status).toEqual(302);
    expect(hasImpressions(res)).toEqual([false, false, true]);
  });
});
