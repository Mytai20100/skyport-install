const axios = require('axios');
const { db } = require('../handlers/db');
const CatLoggr = require('cat-loggr');
const log = new CatLoggr();
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function seed() {
  try {
    // First check if there are any images already in the database
    const existingImages = await db.get('images');
    if (existingImages && existingImages.length > 0) {
      rl.question('\'images\' is already set in the database. Do you want to continue seeding? (y/n) ', async (answer) => {
        if (answer.toLowerCase() !== 'y') {
          log.info('seeding aborted by the user.');
          rl.close();
          process.exit(0);
        } else {
          await performSeeding();
          rl.close();
        }
      });
    } else {
      await performSeeding();
      rl.close();
    }
  } catch (error) {
    log.error(`failed during seeding process: ${error}`);
    rl.close();
  }
}

async function performSeeding() {
  try {
    const imagesIndexResponse = await axios.get('https://raw.githubusercontent.com/Mytai20100/images/image.json');
    const imageUrls = imagesIndexResponse.data;
    let imageDataArray = [];

    for (let url of imageUrls) {
      log.init('fetching image data...');
      try {
        const imageDataResponse = await axios.get(url);
        log.init('seeding: ' + imageDataResponse.data.Name);
        imageDataArray.push(imageDataResponse.data);
      } catch (error) {
        log.error(`failed to fetch image data from ${url}: ${error}`);
      }
    }

    if (imageDataArray.length > 0) {
      await db.set('images', imageDataArray);
      log.info('seeding complete!');
    } else {
      log.info('no new images to seed.');
    }
  } catch (error) {
    log.error(`failed to fetch image URLs or store image data: ${error}`);
  }
}

seed();

process.on('exit', (code) => {
  log.info(`exiting...`);
});

process.on('unhandledRejection', (reason, promise) => {
  log.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});
