const AWS = require("aws-sdk");
const validityOfPSUrl = 10 * 60;
const getPreSignedURL = (key, folderPath, imageExtension) =>
  new Promise(async (resolve, reject) => {
    const params = {
      Bucket: process.env.fileUploadBucket,
      Key: `${folderPath}/${key}`,
      Expires: validityOfPSUrl,
      ContentType: `image/${imageExtension}`,
    };
    try {
      const client = new AWS.S3();
      client.config.update({
        accessKeyId: "AKIAUDRE7M3EH5X6SB6F",
        secretAccessKey: "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",
        region: process.env.AWS_REGION,
        signatureVersion: "v4",
      });

      const signedURL = await new Promise((resolve, reject) => {
        client.getSignedUrl("putObject", params, (err, data) => {
          if (err) {
            reject(err);
          } else {
            resolve(data);
          }
        });
      });
      resolve(signedURL);
    } catch (error) {
      console.log("get ps error", error);
      reject(error);
    }
  });
const destroy = async (req, res) => {
  // destroy
  const client = new AWS.S3();
  client.config.update({
    accessKeyId: "AKIAWAA2QLUBZTTFKRSW", // Generated on step 1
    secretAccessKey: "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", // Generated on step 1
    region: "us-east-1", // Must be the same as  bucket
    signatureVersion: "v4",
  });
  var params = {
    Bucket: "testimagesu",
    Key: req.body.key,
  };
  client.deleteObject(params, function (err, data) {
    if (data) {
      console.log("File deleted successfully");
      return res.success({ data: "Object deleted from s3." });
    } else {
      console.log("Check if you have sufficient permissions : " + err);
      return res.error({ status: 501, message: String(err) });
    }
  });
};
module.exports = {
  getPreSignedURL,
};
