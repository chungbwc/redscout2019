import processing.video.*;

import java.net.URI;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.client.utils.URIBuilder;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.util.EntityUtils;

import java.io.FileInputStream;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.awt.Rectangle;
import javax.imageio.ImageIO;

Capture cam;
PImage img;
Rectangle fRect;
HttpClient httpclient;
HttpPost request;
String gender;
int age;
boolean detect;
String emoStr;
String eye;
String lip;
PFont font;
String userDir;

private static final String subscriptionKey = 
  "your subscription key";
private static final String uriBase = 
  "https://bryanfacetest.cognitiveservices.azure.com/face/v1.0/detect";
private static final String faceAttributes =
  "age,gender,headPose,smile,facialHair,glasses,emotion,hair,makeup,occlusion,accessories,blur,exposure,noise";
private static final String [] emotions = {
  "contempt", 
  "surprise", 
  "happiness", 
  "neutral", 
  "sadness", 
  "disgust", 
  "anger", 
  "fear"
};

public void setup() {
  size(1280, 720);
  cam = new Capture(this, width, height);
  cam.start();
  img = createImage(width, height, ARGB);

  httpclient = null;
  request = null;
  gender = "";
  age = 0;
  emoStr = "";
  fRect = new Rectangle(0, 0, 0, 0);
  detect = false;
  font = loadFont("SansSerif-24.vlw");
  textFont(font, 24);

  try {
    httpclient = HttpClientBuilder.create().build();
    URIBuilder builder = new URIBuilder(uriBase);
    builder.setParameter("returnFaceId", "true");
    builder.setParameter("returnFaceLandmarks", "false");
    builder.setParameter("returnFaceAttributes", faceAttributes);
    URI uri = builder.build();
    request = new HttpPost(uri);
    request.setHeader("Content-Type", "application/octet-stream");
    request.setHeader("Ocp-Apim-Subscription-Key", subscriptionKey);
  } 
  catch (Exception e) {
    println(e.getMessage());
  }
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
    text("Gender: " + gender, 20, 30);
    text("Age: " + str(age), 20, 60);
    text("Emotion: " + emoStr, 20, 90);
    text("Eye makeup: " + eye, 20, 120);
    text("Lip makeup: " + lip, 20, 150);
    popStyle();
  }
}

public void mousePressed() {
  img.copy(cam, 0, 0, cam.width, cam.height, 0, 0, img.width, img.height);
  detectFace(img);
}

private void detectFace(PImage i) {
  detect = !detect;
  if (!detect) {
    return;
  }
  try {
    BufferedImage bim = (BufferedImage)i.getNative();
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    ImageIO.write(bim, "png", out);
    byte [] imageBytes = out.toByteArray();
    ByteArrayEntity imgEntity = new ByteArrayEntity(imageBytes, ContentType.APPLICATION_OCTET_STREAM);
    request.setEntity(imgEntity);
    HttpResponse response = httpclient.execute(request);
    HttpEntity entity = response.getEntity();
    if (entity != null) {
      String jsonString = EntityUtils.toString(entity).trim();
      JSONArray json = parseJSONArray(jsonString);
      println(json);
      showResult(json);
    }
  } 
  catch (Exception e) {
    println(e.getMessage());
  }
}

private void showResult(JSONArray j) {
  JSONObject jRes = j.getJSONObject(0);
  JSONObject faceRect = jRes.getJSONObject("faceRectangle");
  JSONObject faceAttr = jRes.getJSONObject("faceAttributes");
  JSONObject faceEmot = faceAttr.getJSONObject("emotion");

  emoStr = "";
  float max = Float.MIN_VALUE;
  for (int i=0; i<emotions.length; i++) {
    float emo = faceEmot.getFloat(emotions[i]);
    if (emo > max) {
      emoStr = emotions[i] + " " + nf(emo*100, 2, 0) + "%";
      max = emo;
    }
    //    println(emotions[i] + " " + nf(faceEmot.getFloat(emotions[i]), 2, 0));
  }

  JSONObject makeup = faceAttr.getJSONObject("makeup");
  eye = makeup.getBoolean("eyeMakeup") ? "Yes" : "No";
  lip = makeup.getBoolean("lipMakeup") ? "Yes" : "No";

  gender = faceAttr.getString("gender");
  age = faceAttr.getInt("age");

  fRect = new Rectangle(faceRect.getInt("left"), faceRect.getInt("top"), 
    faceRect.getInt("width"), faceRect.getInt("height"));
}

public void captureEvent(Capture c) {
  c.read();
}

public void keyPressed() {
  saveFrame(userDir + "Face####.png");
}
