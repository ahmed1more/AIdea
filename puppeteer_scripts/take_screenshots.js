const puppeteer = require('puppeteer');
const fs = require('fs');

(async () => {
  if (!fs.existsSync('../figures')) {
    fs.mkdirSync('../figures', { recursive: true });
  }

  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();
  await page.setViewport({ width: 393, height: 852, deviceScaleFactor: 2 });
  
  let screenshotPromise = Promise.resolve();

  page.on('console', async msg => {
    const text = msg.text();
    console.log('BROWSER: ' + text);
    if (text.startsWith('SCREENSHOT:')) {
      const filename = text.split(':')[1].trim();
      console.log('Capturing ' + filename);
      // Wait for previous screenshot if any
      await screenshotPromise;
      screenshotPromise = page.screenshot({ path: '../figures/' + filename }).then(() => console.log('Saved ' + filename));
    }
    if (text.includes('AUTOMATION COMPLETE')) {
      console.log('Done! Waiting for pending screenshots...');
      await screenshotPromise;
      await browser.close();
      process.exit(0);
    }
  });

  await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded', timeout: 60000 });
  
  setTimeout(async () => {
    console.log('Timeout reached. Exiting.');
    await browser.close();
    process.exit(1);
  }, 90000);
})();
