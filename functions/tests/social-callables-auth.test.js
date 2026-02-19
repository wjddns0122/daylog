const assert = require("node:assert/strict");
const testEnv = require("firebase-functions-test")();

const functions = require("../lib/index.js");

async function expectUnauthenticated(callable, data) {
  const wrapped = testEnv.wrap(callable);
  await assert.rejects(
    async () => wrapped(data),
    (error) => {
      return error && error.code === "unauthenticated";
    },
  );
}

async function main() {
  await expectUnauthenticated(functions.sendFollowRequest, {
    targetUserId: "target_01",
  });
  await expectUnauthenticated(functions.cancelFollowRequest, {
    targetUserId: "target_01",
  });
  await expectUnauthenticated(functions.acceptFollowRequest, {
    requestId: "req_01",
  });
  await expectUnauthenticated(functions.rejectFollowRequest, {
    requestId: "req_01",
  });
  await expectUnauthenticated(functions.unfollowUser, {
    targetUserId: "target_01",
  });

  testEnv.cleanup();
  console.log("social callable unauthenticated tests passed");
}

main().catch((error) => {
  testEnv.cleanup();
  console.error(error);
  process.exit(1);
});
