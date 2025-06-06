<<<<<<< HEAD
/**
 * @fileoverview This module dynamically sets up express routes for different pages based on
 * configuration read from a JSON file. It utilizes middleware for authentication checks and
 * accesses a database to fetch user-specific or global information to render pages.
 */

=======
>>>>>>> b731dc3 (Initial commit)
const express = require('express');
const fs = require('fs').promises;
const router = express.Router();

const { isAuthenticated } = require('../handlers/auth.js');
const { db } = require('../handlers/db.js');

<<<<<<< HEAD
/**
 * Dynamically reads the page configurations from a JSON file and sets up express routes accordingly.
 * Each page configuration can specify if authentication is required. Authenticated routes fetch
 * user-specific instance data from the database, while non-authenticated routes fetch general data.
 * Routes render pages with the specified templates and data.
 *
 * @async
 * @function setupRoutes
 * @returns {Promise<void>} Executes the asynchronous setup of routes, does not return a value but logs errors.
 */

=======
// Asynchronously read the JSON file and setup routes
>>>>>>> b731dc3 (Initial commit)
async function setupRoutes() {
    try {
        const data = await fs.readFile('pages.json', 'utf8'); 
        const pages = JSON.parse(data);

        pages.forEach(async page => {
            if (page.requiresAuth) {
                router.get(page.path, isAuthenticated, async (req, res) => {
                    const instances = await db.get(req.user.userId + '_instances') || [];
<<<<<<< HEAD
                    res.render(page.template, { req, user: req.user, instances, name: await db.get('name') || 'Skyport' });
                });
            } else {
                router.get(page.path, async (req, res) => {
                    res.render(page.template, { req, name: await db.get('name') || 'Skyport' });
=======
                    res.render(page.template, { user: req.user, instances, name: await db.get('name') || 'Skyport' });
                });
            } else {
                router.get(page.path, async (req, res) => {
                    res.render(page.template, { name: await db.get('name') || 'Skyport' });
>>>>>>> b731dc3 (Initial commit)
                });
            }
        });
    } catch (error) {
        console.error('Error setting up routes:', error);
    }
}

<<<<<<< HEAD
/**
 * GET /
 * Redirects the user to the instances overview page. This route serves as a default route that
 * directs users to a more specific page, handling the initial access or any unspecified routes.
 *
 * @returns {Response} Redirects to the '/instances' page.
 */

=======
>>>>>>> b731dc3 (Initial commit)
router.get('/', async (req, res) => {
    res.redirect('../instances')
});

// Setup routes
setupRoutes();

module.exports = router;
