import processing.video.*;
import java.io.File;
import java.io.FilenameFilter;

final int DISPLAYS = 2;
final int MOV_WIDTH = 640;

Movie [] mov;
int [] display;
PVector [] offset;
int idx;
PFont font;

public void settings() {
  size(1280, 720);
}

public void setup() {
  background(0);
  File dir = new File(dataPath(""));
  File [] files = dir.listFiles(new FilenameFilter() {
    @Override
      public boolean accept(File d, String n) {
      return n.endsWith(".mp4");
    }
  }
  );
  println("Number of movies " + files.length);
  mov = new Movie[files.length];
  for (int i=0; i<mov.length; i++) {
    mov[i] = new Movie(this, files[i].getName());
  }
  noCursor();
  display = new int[DISPLAYS];
  offset = new PVector[DISPLAYS];
  display[0] = playMovie();
  int t = playMovie();
  if (t == display[0]) {
    t++;
    t %= mov.length;
  }
  display[1] = t;
  mov[display[0]].play();
  mov[display[1]].play();
  offset[0] = new PVector(0, 120);
  offset[1] = new PVector(MOV_WIDTH, 120);
  font = loadFont("LucidaSans-48.vlw");
  textFont(font, 48);
}

public void draw() {
  background(0);
  image(mov[display[0]], offset[0].x, offset[0].y);
  image(mov[display[1]], offset[1].x, offset[1].y);

  float perc = mov[display[0]].time()/mov[display[0]].duration();
  if (perc > 0.97) {
    mov[display[0]].stop();
    int t = playMovie();
    if (t == display[1]) {
      t++;
      t %= mov.length;
    }
    display[0] = t;
    mov[display[0]].play();
  }
  perc = mov[display[1]].time()/mov[display[1]].duration();
  if (perc > 0.97) {
    mov[display[1]].stop();
    int t = playMovie();
    if (t == display[0]) {
      t++;
      t %= mov.length;
    }
    display[1] = t;
    mov[display[1]].play();
  }
  pushStyle();
  noStroke();
  fill(255, 0, 0);
  text("Be a Hong Kong Patriot, Part 3", 10, 90);
  text("The Red Scout", 10, 670);
  popStyle();
}

private int playMovie() {
  int i = floor(random(mov.length));
  return i;
}

public void movieEvent(Movie m) {
  m.read();
}
