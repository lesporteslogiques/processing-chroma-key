//
//  Exemple de chroma key (technique du "blue screen")
//
//  Click gauche pour selectionner une couleur clé
//  Click droit pour changer l'image de fond
//  Touche 'm' pour afficher le masque de transparence
//

import processing.video.*;

String[] backgrounds = {"meteo.jpg", "breizh.png", "space.jpg"};
int bg_index = 0;

PImage fons;
Capture video;

color key_color;
float max_dist = sqrt(3 * sq(256));
float max_dist_sq = 3 * sq(256);
float key_dist = 50;
//float key_dist_sq;
float key_dist_norm = key_dist / max_dist;
//float key_dist_norm_sq = sq(key_dist_norm);
float linear_smooth = 0.03;

boolean show_mask = false;
float blend;


void setup() {
  size(640, 480);
  fons = loadImage(backgrounds[bg_index]);
  key_color = 0xff00;
  video = new Capture(this, 640, 480);
  video.start();
}

void draw() {
  //loadPixels();
  if (show_mask) {
    background(0);
    if (video.available()) {
      video.read();
      video.loadPixels();
    }
    loadPixels();
    for (int i=0; i<pixels.length; i++) {
      float dist = colorDist(video.pixels[i], key_color);
      float threshold = max_dist * key_dist_norm;
      if (abs(threshold - dist) < linear_smooth * max_dist) {
        // border case
        blend = 0.5 - (threshold - dist) / (2*linear_smooth*max_dist);
        pixels[i] = color(256*blend);
        //pixels[i] = color(127);
      } else if (dist < threshold) {
        pixels[i] = color(0);
      } else {
        pixels[i] = color(255);
      }
    }
    updatePixels();
  } else {
    // Draw background
    image(fons, 0, 0, width, height);
    if (video.available()) {
      video.read();
      video.loadPixels();
    }
    loadPixels();
    for (int i=0; i<pixels.length; i++) {
      float dist = colorDist(video.pixels[i], key_color);
      float threshold = max_dist * key_dist_norm;
      color c1, c2;
      float r, v, b;
      if (abs(threshold - dist) < linear_smooth * max_dist) {
        // border case
        blend = 0.5 - (threshold - dist) / (2*linear_smooth*max_dist);
        blend = constrain(blend, 0.0, 1.0);
        c1 = pixels[i];
        c2 = video.pixels[i];
        r = (1.0-blend) * (c1 >> 16 & 0xFF) + blend * (c2 >> 16 & 0xFF);
        v = (1.0-blend) * (c1 >> 8 & 0xFF) + blend * (c2 >> 8 & 0xFF);
        b = (1.0-blend) * (c1 & 0xFF) + blend * (c2 & 0xFF);
        pixels[i] = color(r, v, b);
      } else if (dist > threshold) {
        pixels[i] = video.pixels[i];
      }
    }
    updatePixels();
  }
}

float colorDist(color c1, color c2) {
  float d = 0;
  d += sq(red(c1) - red(c2));
  d += sq(green(c1) - green(c2));
  d += sq(blue(c1) - blue(c2));
  
  return sqrt(d);
}


void mouseClicked() {
  if (mouseButton == LEFT) {
    key_color = video.pixels[mouseX + width*mouseY];
  } else if (mouseButton == RIGHT) {
    bg_index = (bg_index+1) % backgrounds.length;
    fons = loadImage(backgrounds[bg_index]);
  }
}

void mouseDragged() {
  key_color = video.pixels[mouseX + width*mouseY];
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  key_dist += 8*e;
  key_dist = constrain(key_dist, -max_dist*linear_smooth, max_dist*(1+linear_smooth));
  key_dist_norm = key_dist / max_dist;
  //println(key_dist, key_dist_norm);
}

void keyPressed() {
  if (key == 'm') {
    show_mask = !show_mask;
  }
}
