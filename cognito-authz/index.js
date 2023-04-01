const { CognitoJwtVerifier } = require("aws-jwt-verify");
const express = require("express");
const app = express()
const port = 8123

// Create the verifier outside your route handlers,
// so the cache is persisted and can be shared amongst them.
const jwtVerifier = CognitoJwtVerifier.create({
  userPoolId: process.env.AWS_COGNITO_USER_POOL_ID,
  clientId: process.env.AWS_COGNITO_USER_POOL_CLIENT_ID,
  tokenUse: "access",
});

app.get('/health-check', (req, res) => {
  res.status(200).send({ "status": "ok" });
});

app.get("/api/*", async (req, res, next) => {
  try {
    const authHeader = req.header("authorization")
    console.log(`[GET] Handling authz for ${req.originalUrl} with authorization header ${authHeader}`)
    let payload

    if (authHeader && authHeader.split(' ')[0] === 'Bearer') {
      payload = await jwtVerifier.verify(authHeader.split(' ')[1]);
    } else {
      payload = await jwtVerifier.verify(authHeader);
    }

    console.log("Token is valid. Payload: ", payload)
    res.append('x-cognito-username', payload.username).json({Status: "Ok"});
  } catch (err) {
    console.error(err);
    return res.status(200).end()
  }
});

app.post("/api/*", async (req, res, next) => {
  try {
    const authHeader = req.header("authorization")
    console.log(`[POST] Handling authz for ${req.originalUrl} with authorization header ${authHeader}`)
    let payload

    if (authHeader && authHeader.split(' ')[0] === 'Bearer') {
      payload = await jwtVerifier.verify(authHeader.split(' ')[1]);
    } else {
      payload = await jwtVerifier.verify(authHeader);
    }

    console.log("Token is valid. Payload: ", payload)
    res.append('x-cognito-username', payload.username).json({Status: "Ok"});
  } catch (err) {
    console.error(err);
    return res.status(403).json({ statusCode: 403, message: "Forbidden" });
  }
});

// Hydrate the JWT verifier, then start express.
// Hydrating the verifier makes sure the JWKS is loaded into the JWT verifier,
// so it can verify JWTs immediately without any latency.
// (Alternatively, just start express, the JWKS will be downloaded when the first JWT is being verified then)
jwtVerifier
  .hydrate()
  .catch((err) => {
    console.error(`Failed to hydrate JWT verifier: ${err}`);
    process.exit(1);
  })
  .then(() =>
    app.listen(port, () => {
      console.log(`Authz app listening at http://localhost:${port}`);
    })
  );