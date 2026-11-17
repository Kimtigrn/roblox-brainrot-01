// Brainrot Base Battles: a 3D Roblox brainrot game for make.fun's
// roblox-brainrot-01 bounty. The game is this directory's Rojo project, built
// into game.rbxl with `rojo build default.project.json --output game.rbxl`,
// and this program hands it in: it copies game.rbxl, src/, screenshots/ and
// PLAY.json from beside this file to /output and writes /output/dossier.json,
// the summary the judge reads, with the vendored make.fun library.
//
// The game itself: a central conveyor belt walks absurd meme-born brainrots
// past four player bases. Buy one off the belt, place it on your base, and it
// earns money every second at its own rate; climb the rarity ladder, mutate,
// upgrade and rebirth, and lock your base before someone steals your best one.
//
// Every name under /output starts with a letter, a digit or _ and holds only
// letters, digits, . _ and -: the grader fails an entry whose output holds any
// other, so a file such as .gitkeep or .DS_Store copied in fails it. So src/
// and screenshots/ are copied without any name that starts with a dot, at any
// depth. The preflight below fails fast with a plain message when a piece of
// the entry is missing or over its cap, instead of a cryptic copy error.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

// Preflight: the entry is refused without its place, its link file, or 3-4
// screenshots inside the gate's 256 KiB cap, so say so plainly before copying.
if (!existsSync(join(here, 'game.rbxl'))) {
	throw new Error('game.rbxl is missing: build it first with `rojo build default.project.json --output game.rbxl`.');
}
if (!existsSync(join(here, 'PLAY.json'))) {
	throw new Error('PLAY.json is missing: it names the published place (fill it in once the experience is Public).');
}
const screenshotDir = join(here, 'screenshots');
const screenshots = existsSync(screenshotDir) ? readdirSync(screenshotDir).filter((name) => !name.startsWith('.')) : [];
if (screenshots.length < 3 || screenshots.length > 4) {
	throw new Error(`screenshots/ must hold 3 or 4 images, found ${screenshots.length}.`);
}
for (const name of screenshots) {
	const lower = name.toLowerCase();
	if (!lower.endsWith('.png') && !lower.endsWith('.jpg') && !lower.endsWith('.jpeg')) {
		throw new Error(`screenshots/${name} is not a PNG or JPEG, and the gate refuses any other format.`);
	}
	const size = statSync(join(screenshotDir, name)).size;
	if (size > 262144) {
		throw new Error(`screenshots/${name} is ${size} bytes, over the 256 KiB cap: re-encode it smaller.`);
	}
}

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);
