const fetch = require('node-fetch');

describe('dovetail - basic', () => {
  it('has a root doc', async () => {
    const res = await fetch(DOVETAIL_HOST);
    const text = await res.text();

    expect(res.status).toEqual(200);
    expect(res.headers.get('content-type')).toMatch(/text\/plain/);
    expect(text).toContain('You know, for podcasts');
  });
});
