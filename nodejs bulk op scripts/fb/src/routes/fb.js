var express = require('express');
var router = express.Router();
const fbController = require('../controllers/FbController');

router.get('/get-data', async function (req, res, next) {
  await fbController.getData(req, res);
});

module.exports = router;
