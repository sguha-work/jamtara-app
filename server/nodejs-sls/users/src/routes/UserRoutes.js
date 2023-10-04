var express = require("express");
var router = express.Router();

const userController = require("../controllers/UserController");
// const CognitoExpress = require("cognito-express");
// //Initializing CognitoExpress constructor
// const cognitoExpress = new CognitoExpress({
//   region: process.env.AWS_REGION, //process.env.AWS_REGION,
//   cognitoUserPoolId: process.env.COGNITO_USER_POOL_ID,
//   tokenUse: "access", //Possible Values: access | id
//   tokenExpiration: 3600 //Up to default expiration of 1 hour (3600000 ms)
// });
// const jwtVerifier = (req, res, next) => {
//   //I'm passing in the access token in header under key accessToken
//   const accessTokenFromClient = (req.headers.authorization) ? req.headers.authorization.replace("Bearer ", "") : '';
//   // //Fail if token not present in header.
//   res.setHeader('Access-Control-Allow-Origin', '*');
//   res.setHeader('Access-Control-Allow-Credentials', 'true');
//   if (!accessTokenFromClient) return res.status(401).json({ message: "Access Token missing from header", status: 401 });
//   cognitoExpress.validate(accessTokenFromClient, function (err, response) {

//     //If API is not authenticated, Return 401 with error message. 
//     if (err) return res.status(401).json({ message: err, status: 401 });
//     //Else API has been authenticated. Proceed.
//     req.identity = response;
//     req.identity.authorization = req.headers.authorization;
//     next();
//   });
// };

router.get("/list/:type/:parentId", async (req, res) => {
  await userController.fetchUsers(req, res);
});

router.get("/list-all-by-division", async (req, res) => {
  await userController.fetchAllUsersDivisionWise(req, res);
});
router.get("/notifications/:target_user/:target_user_id", async (req, res) => {
  await userController.fetchNotifications(req, res);
});
router.get("/:user_id", async (req, res) => {
  await userController.fetchUserDetails(req, res);
});

router.post("/", async (req, res) => {
  await userController.createUser(req, res);
});

router.patch("/:user_id", async (req, res) => {
  await userController.updateUser(req, res);
});

router.patch("/notification/:id", async (req, res) => {
  await userController.updateNotification(req, res);
});

router.delete("/:user_id", async (req, res) => {
  await userController.deleteUser(req, res);
});

router.patch("/update-password/:user_id", async ()=>{
  await userController.updateUserPassword();
});

module.exports = router;
