<<<<<<< HEAD
/**
 * @fileoverview This module provides API routes for managing deployment of instances,
 * including listing available instances with basic authentication and deploying new instances.
 * It handles interactions with a custom database and communicates with node services
 * for instance creation and deployment.
 */

=======
>>>>>>> b731dc3 (Initial commit)
const express = require('express');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
const { db } = require('../handlers/db.js'); // Import the custom database handler
const basicAuth = require('express-basic-auth');
<<<<<<< HEAD
const config = require('../config.json')

const router = express.Router();

/**
 * GET /instances/list
 * Provides a list of all instances available in the database. Access to this route is restricted
 * with basic authentication, requiring a username and password. The authentication challenge and
 * realm can be configured within the route setup.
 *
 * @returns {Response} Sends a JSON response containing an array of instances.
 */
router.get('/instances/list', basicAuth({
  users: { 'Skyport': config.key },
  challenge: true, // we'll disable this in prod
=======

const router = express.Router();

// Custom basic auth configuration for /instances/list
router.get('/instances/list', basicAuth({
  users: { 'Skyport': 'skyport_1' }, // Replace with your actual admin credentials
  challenge: true, // Optional, this will cause browsers to show a login dialog
  realm: 'Imb4T3st4pp' // Optional, can set a realm identifier
>>>>>>> b731dc3 (Initial commit)
}), async (req, res) => {
  let instances = await db.get('instances');
  res.json(instances);
});

<<<<<<< HEAD
/**
 * GET /images/list
 * Provides a list of all images available in the database.
 *
 * @returns {Response} Sends a JSON response containing an array of images.
 */
router.get('/images/list', basicAuth({
  users: { 'Skyport': config.key },
  challenge: true, // we'll disable this in prod
}), async (req, res) => {
  let images = await db.get('images');
  res.json(images);
});

/**
 * GET /instances/deploy
 * Handles the deployment of a new instance based on the parameters provided via query strings.
 * It validates the required parameters, interacts with a node specific API to create the instance,
 * and updates the database with the new instance data. Error handling is included for validation
 * and remote request failures.
 *
 * @param {string} image - The Docker image name to deploy.
 * @param {string} [cmd] - Optional command to run in the container, passed as comma-separated values.
 * @param {string} [env] - Optional environment variables for the container, passed as comma-separated values.
 * @param {number} [memory] - Optional memory allocation for the container, specified in MB.
 * @param {number} [cpu] - Optional CPU share for the container.
 * @param {string} [ports] - Optional port mappings for the container, passed as comma-separated values in 'container:host' format.
 * @param {string} nodeId - Identifier for the node on which the instance will be deployed.
 * @param {string} name - Name of the instance.
 * @param {string} user - User identifier who is deploying the instance.
 * @returns {Response} Sends a 201 status with instance deployment details if successful, or an error status if deployment fails.
 */

router.get('/instances/deploy', async (req, res) => {
  const {
    image,
=======
router.get('/instances/deploy', async (req, res) => {
  const {
    image,
    cmd,
    env,
>>>>>>> b731dc3 (Initial commit)
    memory,
    cpu,
    ports,
    nodeId,
    name,
    user
  } = req.query;

<<<<<<< HEAD
  if (!image || !memory || !cpu || !ports || !nodeId || !name || !user) return res.send('Missing parameters')

  const NodeId = nodeId;
  const Name = name;
=======
  if (!image) {
    return res.status(400).json({ error: 'Image parameter is required' });
  }

  const NodeId = nodeId;
  const Name = name;
  const Cmd = cmd ? cmd.split(',') : undefined;
  const Env = env ? env.split(',') : undefined;
>>>>>>> b731dc3 (Initial commit)
  const Memory = memory ? parseInt(memory) * 1024 * 1024 : undefined;
  const Cpu = cpu ? parseInt(cpu) : undefined;
  const ExposedPorts = {};
  const PortBindings = {};

  let Node = await db.get(NodeId + '_node');
<<<<<<< HEAD
  if (!Node) return res.send('Invalid node');
=======
  if (!Node) return res.send('invalid node');
>>>>>>> b731dc3 (Initial commit)

  const NodeRemote = Node.address;
  const NodePort = Node.port;

  if (ports) {
    ports.split(',').forEach(portMapping => {
      const [containerPort, hostPort] = portMapping.split(':');
      const key = `${containerPort}/tcp`;
      ExposedPorts[key] = {};
      PortBindings[key] = [{ HostPort: hostPort }];
    });
  }

  const RequestData = {
    method: 'post',
    url: 'http://' + NodeRemote + ':' + NodePort + '/instances/create',
    auth: {
      username: 'Skyport',
      password: Node.apiKey
    },
    headers: { 
      'Content-Type': 'application/json'
    },
    data: {
      Name,
      Image: image,
<<<<<<< HEAD
=======
      Cmd,
      Env,
>>>>>>> b731dc3 (Initial commit)
      Memory,
      Cpu,
      ExposedPorts,
      PortBindings
    }
  };

  try {
    const response = await axios(RequestData);

    // Attempt to get the user's current server list
    const userId = user;
    const userServers = await db.get(`${userId}_instances`) || [];
    const globalServers = await db.get('instances') || [];

    // Append the new server ID to the user's server list
    userServers.push({
      Name: name,
      Node,
      ContainerId: response.data.containerId,
      VolumeId: response.data.volumeId,
      Memory,
      Cpu,
<<<<<<< HEAD
=======
      Cmd,
      Env,
>>>>>>> b731dc3 (Initial commit)
      ExposedPorts,
      PortBindings
    });

    globalServers.push({
      Name: name,
      Node,
      ContainerId: response.data.containerId,
      VolumeId: response.data.volumeId,
      Memory,
      Cpu,
<<<<<<< HEAD
=======
      Cmd,
      Env,
>>>>>>> b731dc3 (Initial commit)
      ExposedPorts,
      PortBindings
  });

    // Save the updated list back to the database
    await db.set(`${userId}_instances`, userServers);
    await db.set(`instances`, globalServers);

<<<<<<< HEAD
    // somewhatNotGlobalServerYetSlightlyGlobalIsThisGlobalOrNot this was called
    await db.set(`${response.data.containerId}_instance`, {
      Name: name,
      Node,
      ContainerId: response.data.containerId,
      VolumeId: response.data.volumeId,
      Memory,
      Cpu,
      ExposedPorts,
      PortBindings
    });

=======
>>>>>>> b731dc3 (Initial commit)
    res.status(201).json({
      Message: 'Container created successfully and added to user\'s servers',
      ContainerId: response.data.containerId,
      VolumeId: response.data.volumeId
    });
  } catch (error) {
    console.log(error)
    res.status(500).json({
<<<<<<< HEAD
      error: 'Failed to create container',
=======
      error: 'Failed to register container',
>>>>>>> b731dc3 (Initial commit)
      details: error ? error.data : 'No additional error info'
    });
  }
});

<<<<<<< HEAD
module.exports = router;
=======
module.exports = router;
>>>>>>> b731dc3 (Initial commit)
