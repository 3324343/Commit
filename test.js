
const { execFileSync } = require("node:child_process");

const INTERVAL_MS = 10 * 60 * 1000; // 10 minutes
const BRANCH = null; // null = use the current branch

function git(args) {
  return execFileSync("git", args, {
    encoding: "utf8",
    stdio: ["inherit", "pipe", "inherit"],
  }).trim();
}

function autoCommit() {
  try {
    git(["rev-parse", "--is-inside-work-tree"]);

    const branch =
      BRANCH || git(["branch", "--show-current"]);

    if (!branch) {
      console.log("No branch checked out. Skipping.");
      return;
    }

    git(["add", "-A"]);

    if (!git(["status", "--porcelain"])) {
      console.log(`[${new Date().toLocaleString()}] No changes.`);
      return;
    }

    const message = `Auto commit: ${new Date().toISOString()}`;

    git(["commit", "-m", message]);
    git(["push", "-u", "origin", branch]);

    console.log("Changes committed and pushed successfully.");
  } catch (error) {
    console.error("Auto-commit failed:", error.message);
  }
}

console.log("Git auto-commit started. Interval: 10 minutes.");

autoCommit();
setInterval(autoCommit, INTERVAL_MS);

