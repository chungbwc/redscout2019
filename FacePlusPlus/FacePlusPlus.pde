import processing.video.*;
import http.requests.*;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import java.io.File;
import java.io.ByteArrayOutputStream;
import java.io.FileOutputStream;
import java.awt.Rectangle;

final static String API_KEY = "your api key";
final static String API_SECRET = "your api secret code";
final static String API_URL = "https://api-us.faceplusplus.com/facepp/v3/detect";

PostRequest post;
PFont font;
String person;
PImage img;
Capture cam;
boolean detect;
Rectangle fRect;
int age;
String gender;
String emoStr;
String ethnicity;
String skin;
float beauty;
String userDir;

private static final String [] emotions = {
  "surprise", 
  "happiness", 
  "neutral", 
  "sadness", 
  "disgust", 
  "anger", 
  "fear"
};

private static final String [] skins = {
  "dark_circle", 
  "acne", 
  "health", 
  "stain"
};

public void setup() {
  size(1280, 720);
  cam = new Capture(this, width, height);
  cam.start();
  img = createImage(width, height, ARGB);
  //  person = dataPath("MePhoto001.jpg");
  post = new PostRequest(API_URL);
  //  post.addFile("image_file", person);
  detect = false;
  fRect = new Rectangle(0, 0, 0, 0); 
  age = 0;
  gender = "";
  ethnicity = "";
  beauty = 0.0;
  emoStr = "";
  skin = "";
  font = loadFont("SansSerif-24.vlw");
  textFont(font, 24);
  userDir = System.getProperty("user.home") + "/Desktop/";
}

public void draw() {
  background(0);
  if (!detect) {
    image(cam, 0, 0, width, height);
  } else {
    image(img, 0, 0, width, height);
    pushStyle();
    noFill();
    stroke(255, 200, 0);
    rect(fRect.x, fRect.y, fRect.width, fRect.height);
    noStroke();
    fill(0);
    text("Gender: " + gender, 20, 40);
    text("Age: " + str(age), 20, 70);
    text("Ethnicity: " + ethnicity, 20, 100);
    text("Emotion: " + emoStr, 20, 130);
    text("Beauty: " + beauty, 20, 160);
    text(skin, 20, 190);
    popStyle();
  }
}

public void mousePressed() {
  img.copy(cam, 0, 0, cam.width, cam.height, 
    0, 0, img.width, img.height);
  detectFace(img);
}

private void detectFace(PImage i) {
  detect = !detect;
  if (!detect) {
    return;
  }
  try {
    BufferedImage bim = (BufferedImage) i.getNative();
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    ImageIO.write(bim, "png", out);
    byte [] imageBytes = out.toByteArray();
    File temp = File.createTempFile("out", ".tmp");
    OutputStream os = new FileOutputStream(temp);
    os.write(imageBytes);
    os.close();
    post.addData("api_key", API_KEY);
    post.addData("api_secret", API_SECRET);
    post.addData("return_attributes", "gender,age,emotion,ethnicity,beauty,skinstatus");
    post.addFile("image_file", temp);
    post.send();
    temp.delete();
  } 
  catch (Exception e) {
    println(e.getMessage());
  }
  showResult();
}

private void showResult() {
  String res = post.getContent();
  JSONObject json = parseJSONObject(res);
  JSONArray faces = json.getJSONArray("faces");
  JSONObject face = faces.getJSONObject(0);
  JSONObject attr = face.getJSONObject("attributes");
  println(face);
  age = attr.getJSONObject("age").getInt("value");
  gender = attr.getJSONObject("gender").getString("value");
  JSONObject rect = face.getJSONObject("face_rectangle");
  fRect = new Rectangle(rect.getInt("left"), rect.getInt("top"), 
    rect.getInt("width"), rect.getInt("height"));
  ethnicity = attr.getJSONObject("ethnicity").getString("value");
  if (gender.equals("Male")) {
    beauty = attr.getJSONObject("beauty").getFloat("male_score");
  } else if (gender.equals("Female")) {
    beauty = attr.getJSONObject("beauty").getFloat("female_score");
  } else {
    beauty = 0.0;
  }
  JSONObject emotion = attr.getJSONObject("emotion");
  float max = Float.MIN_VALUE;
  for (int i=0; i<emotions.length; i++) {
    float emo = emotion.getFloat(emotions[i]);
    if (emo > max) {
      emoStr = emotions[i] + " " + nf(emo, 2, 0);
      max = emo;
    }
  }
  JSONObject skinStatus = attr.getJSONObject("skinstatus");
  skin = "";
  for (int i=0; i<skins.length; i++) {
    float val = skinStatus.getFloat(skins[i]);
    skin += skins[i] + " " + nf(val, 2, 0) + "\n";
  }
}

public void captureEvent(Capture c) {
  c.read();
}

public void keyPressed() {
  saveFrame(userDir + "Face####.png");
}
