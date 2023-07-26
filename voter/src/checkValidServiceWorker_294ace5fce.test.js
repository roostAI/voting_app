// Test generated by RoostGPT for test zb-js-test using AI Type Open AI and AI Model gpt-4

jest.mock('node-fetch');
const fetch = require('node-fetch');
const {Response} = jest.requireActual('node-fetch');

const { checkValidServiceWorker, registerValidSW } = require('./serviceWorker');

describe('Service Worker Testing', () => {

  beforeEach(() => {
    fetch.mockClear();
  });

  test('should find valid service worker and register it', async () => {
    fetch.mockReturnValue(
      Promise.resolve(
        new Response(JSON.stringify({}), { headers: { 'content-type': 'application/javascript' } })
      )
    );

    const mockRegisterValidSW = jest.fn();
    registerValidSW = mockRegisterValidSW;

    await checkValidServiceWorker('swUrl', {});
    expect(mockRegisterValidSW).toHaveBeenCalled();
  });

  test('should not find service worker and reload the page', async () => {
    fetch.mockReturnValue(
      Promise.resolve(
        new Response(JSON.stringify({}), { status: 404 })
      )
    );

    const mockReload = jest.fn();
    global.window.location.reload = mockReload;

    await checkValidServiceWorker('swUrl', {});
    expect(mockReload).toHaveBeenCalled();
  });

  test('should handle when fetch fails', async () => {
    fetch.mockReturnValue(Promise.reject('API is down'));

    const consoleSpy = jest.spyOn(console, 'log');

    await checkValidServiceWorker('swUrl', {});
    expect(consoleSpy).toHaveBeenCalledWith('No internet connection found. App is running in offline mode.');
  });

});