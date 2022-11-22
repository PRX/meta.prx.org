const fetch = require('node-fetch');

describe('dovetail - debug', () => {
  const TEST_PATH = `${TEST_FEEDER_PODCAST}/${TEST_FEEDER_EPISODE}/test-file.mp3`;
  const TEST_URL = `${DOVETAIL_HOST}/${TEST_PATH}`;

  it('returns debug json', async () => {
    const headers = {
      'user-agent': USER_AGENT,
      accept: 'application/vnd.dovetail.v3+json',
    };
    const res = await fetch(TEST_URL, { headers });
    const json = await res.json();

    expect(res.status).toEqual(200);
    expect(json.program.id.toString()).toEqual(TEST_FEEDER_PODCAST);
    expect(json.digest).toMatch(/^[0-9a-zA-Z_-]+$/);
    expect(json.redirect).toContain('dovetail3-cdn');

    // arrangement/placement
    expect(json.arrangement.length).toBeGreaterThan(1);
    expect(json.arrangement.filter(p => p.type === 'original').length).toBeGreaterThan(1);
    expect(json.arrangement.filter(p => p.type === 'sonic_id').length).toBeGreaterThan(0);
    expect(json.arrangement.filter(p => p.type === 'ad').length).toBeGreaterThan(0);
  });
});
