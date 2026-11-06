#!/usr/bin/env node
/**
 * Cursor updater for airi
 *
 * Uses Cursor's internal API (same as omarcresp/cursor-flake) to fetch the latest
 * version + download URL, computes the hash, and updates sources.json.
 *
 * Run with: nix run .#update-cursor
 */

import { execFileSync } from "child_process";
import { readFileSync, writeFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));

const DOWNLOAD_API = "https://api2.cursor.sh/updates/api/download/stable";
const SOURCES_FILE = join(__dirname, "sources.json");

const TARGETS = {
  "x86_64-linux": "linux-x64",
  // "aarch64-darwin": "darwin-arm64", // uncomment if you want macOS support later
};

async function getLatestRelease() {
  const releases = await Promise.all(
    Object.entries(TARGETS).map(async ([system, apiTarget]) => {
      const response = await fetch(`${DOWNLOAD_API}/${apiTarget}/cursor`, {
        headers: {
          "User-Agent": "Cursor-Version-Checker",
          "Cache-Control": "no-cache",
        },
      });

      if (!response.ok) {
        throw new Error(`Cursor API returned ${response.status} for ${system}`);
      }

      const release = await response.json();
      if (!release.version || !release.downloadUrl) {
        throw new Error(`Cursor API returned invalid metadata for ${system}`);
      }

      return [system, release];
    })
  );

  const versions = new Set(releases.map(([, r]) => r.version));
  if (versions.size !== 1) {
    throw new Error(`Cursor platforms are on different versions: ${[...versions].join(", ")}`);
  }

  return {
    version: releases[0][1].version,
    sources: Object.fromEntries(
      releases.map(([system, release]) => [
        system,
        { url: release.downloadUrl },
      ])
    ),
  };
}

function getCurrentRelease() {
  return JSON.parse(readFileSync(SOURCES_FILE, "utf-8"));
}

function getHashForUrl(url) {
  const base32 = execFileSync("nix-prefetch-url", ["--type", "sha256", url], {
    encoding: "utf-8",
  }).trim();

  const sri = execFileSync(
    "nix",
    ["hash", "convert", "--to", "sri", "--hash-algo", "sha256", base32],
    { encoding: "utf-8" }
  ).trim();

  return sri;
}

function releaseIsCurrent(current, latest) {
  return (
    current.version === latest.version &&
    Object.entries(latest.sources).every(
      ([system, source]) => current.sources?.[system]?.url === source.url
    )
  );
}

async function main() {
  console.log("Fetching latest Cursor release from official API...");
  const latest = await getLatestRelease();
  console.log("Latest version:", latest.version);

  const current = getCurrentRelease();
  console.log("Current version in sources.json:", current.version);

  if (releaseIsCurrent(current, latest)) {
    console.log("Already up to date!");
    return;
  }

  console.log(`New release available: ${latest.version}`);

  for (const [system, source] of Object.entries(latest.sources)) {
    console.log(`Fetching hash for ${system}...`);
    source.hash = getHashForUrl(source.url);
  }

  console.log("Writing updated sources.json...");
  writeFileSync(SOURCES_FILE, JSON.stringify(latest, null, 2) + "\n");

  console.log(`Done! Updated Cursor to version ${latest.version}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
