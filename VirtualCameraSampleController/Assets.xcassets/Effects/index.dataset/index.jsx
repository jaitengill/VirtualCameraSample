/* eslint-disable */
import blackAndWhite from './b&w.png';
import blueLaser from './blue_laser.png';
import caustics from './caustics.png';
import chromatic from './chromatic_aberration.png';
import clubPartyLights from './club_party_lights.png';
import confetti from './confetti.png';
import displacedGlow from './displaced_glow.png';
import dreamyBloom from './dreamy_bloom.png';
import fireflies from './fireflies.png';
import glitch from './glitch.png';
import glitchV2 from './glitch_v2.png';
import glitter from './glitter.png';
import glowyGoo from './glowy_goo.png';
import greenLaser from './green_laser.png';
import lensFlare from './lens_flare.png';
import matrix from './matrix.png';
import nightVision from './night_vision.png';
import oldFilm from './old_film.png';
import oldFilmDust from './old_film_dust.png';
import onlyRed from './only_reds.png';
import overlayFire from './overlay_fire.png';
import paper from './paper.png';
import smoke from './smoke.png';
import stars from './stars.png';
import staticEffect from './static.png';
import staticStrong from './static_strong.png';
import technical from './technical.png';
import thermalVision from './thermal_vision.png';
import trippy from './trippy.png';
import velvet from './velvet.png';
import vhs from './vhs.png';

import none from './none.jpeg';

export function getFilterPreview(filterName) {
  switch (filterName) {
  case "b&w":
    return blackAndWhite;
  case "blue_laser":
    return blueLaser;
  case "caustics":
    return caustics;
  case "chromatic_aberration":
    return chromatic;
  case "club_party_lights":
    return clubPartyLights;
  case "confetti":
    return confetti;
  case "displaced_glow":
    return displacedGlow;
  case "dreamy_bloom":
    return dreamyBloom;
  case "fireflies":
    return fireflies;
  case "glitch":
    return glitch;
  case "glitch_v2":
    return glitchV2;
  case "glitter":
    return glitter;
  case "glowygoo":
    return glowyGoo;
  case "green_laser":
    return greenLaser;
  case "lens_flare":
    return lensFlare;
  case "matrix":
    return matrix;
  case "night_vision":
    return nightVision;
  case "old_film":
    return oldFilm;
  case "old_film_dust":
    return oldFilmDust;
  case "only_reds":
    return onlyRed;
  case "overlay_fire":
    return overlayFire;
  case "paper":
    return paper;
  case "smoke":
    return smoke;
  case "stars":
    return stars;
  case "static":
    return staticEffect;
  case "static_strong":
    return staticStrong;
  case "technical":
    return technical;
  case "thermal_vision":
    return thermalVision;
  case "trippy":
    return trippy;
  case "velvet":
    return velvet;
  case "vhs":
    return vhs;
  case 'none':
    return none;
  default: throw new Error(`Bad Filter Name: ${filterName}`);
  }
}
