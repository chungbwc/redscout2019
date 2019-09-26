// Face swap example from OpenCV
import cvimage.*;
import processing.video.*;
import org.opencv.core.*;
import org.opencv.core.Core;
import org.opencv.photo.Photo;
import org.opencv.imgproc.*;
import org.opencv.imgproc.Imgproc;
import org.opencv.face.Face;
import org.opencv.face.Facemark;
import java.util.ArrayList;
import java.util.Arrays;
import java.io.File;
import java.io.FilenameFilter;

final int W = 480, H = 480;
final int CAPW = 640, CAPH = 480;
final float DIST = 1.0;
PImage img1, img2;
String faceFile, modelFile;
Facemark fm;
PVector offset1, offset2, origin;
Point [] points1;
Mat im1s;
Capture cap;
FacePhoto [] allFaces;
int faceIdx;
String fName;

public void settings() {
  size(W+CAPW, H);
}

public void setup() {
  System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
  println(Core.VERSION);
  background(0);
  storeAllFaces();

  faceFile = "haarcascade_frontalface_default.xml";
  modelFile = "face_landmark_model.dat";
  fm = Face.createFacemarkKazemi();
  fm.loadModel(dataPath(modelFile));
  faceIdx = 0;
  fName = "";
  storeFace();
  origin = new PVector(0, 0);
  offset1 = new PVector(img1.width, 0);
  printArray(Capture.list());
  cap = new Capture(this, CAPW, CAPH);
  //cap = new Capture(this, CAPW, CAPH, "HD USB Camera");
  //cap = new Capture(this, CAPW, CAPH, "Integrated Webcam");
  //cap = new Capture(this, CAPW, CAPH, "FaceTime HD Camera");
  //cap = new Capture(this, CAPW, CAPH, "USB2.0 VGA UVC WebCam");
  cap.start();
}

private void storeAllFaces() {
  // Store all official faces in array.
  File dir = new File(dataPath("photos"));
  File [] files = dir.listFiles(new FilenameFilter() {
    @Override
      public boolean accept(File f, String n) {
      return n.endsWith(".png");
    }
  }
  );
  allFaces = new FacePhoto[files.length];
  for (int i=0; i<files.length; i++) {
    String s = files[i].getName();
    s = s.substring(0, s.length()-4);
    allFaces[i] = new FacePhoto(s);
  }
}

private void storeFace() {
  //  int idx = floor(random(allFaces.length));
  int idx = faceIdx;
  allFaces[idx].loadFile();
  img1 = allFaces[idx].getImage();
  fName = allFaces[idx].getName();
  println(fName);
  CVImage cv1 = new CVImage(img1.width, img1.height);
  cv1.copyTo(img1);
  Mat im1 = cv1.getBGR();
  im1s = new Mat(im1.rows(), im1.cols(), CvType.CV_32F);
  im1.convertTo(im1s, CvType.CV_32F);
  ArrayList<MatOfPoint2f> shape1 = detectFacemarks(im1);
  println(shape1.size());
  //  if (shape1.size() != 1) 
  if (shape1.size() <= 0)
    return;

  float maxWidth = Float.MIN_VALUE;
  idx = -1;
  for (int i=0; i<shape1.size(); i++) {
    Point [] pts = shape1.get(i).toArray();
    float w = abs((float)(pts[0].x - pts[16].x));
    if (w > maxWidth) {
      maxWidth = w;
      idx = i;
    }
  }
  if (idx < 0) 
    return;
  points1 = shape1.get(idx).toArray();
}

public void draw() {
  image(img1, origin.x, origin.y);
  matchFace();
  pushStyle();
  noStroke();
  fill(0);
  text(fName, 20, 20);
  popStyle();
}

private void matchFace() {
  if (!cap.available()) 
    return;
  cap.read();
  CVImage cv = new CVImage(cap.width, cap.height);
  cv.copyTo(cap);
  // image(cap, offset1.x, offset1.y);
  Mat im = cv.getBGR();
  ArrayList<MatOfPoint2f> shapes = detectFacemarks(im);
  float maxWidth = Float.MIN_VALUE;
  int idx = -1;
  for (int i=0; i<shapes.size(); i++) {
    Point [] pts = shapes.get(i).toArray();
    float w = abs((float)(pts[0].x - pts[16].x));
    if (w > maxWidth) {
      maxWidth = w;
      idx = i;
    }
  }
  if (idx < 0) 
    return;

  Point [] points2 = shapes.get(idx).toArray();
  Rect rect = new Rect(0, 0, cap.width, cap.height);
  ArrayList<int []> triangles = getTriangles(rect, points2);
  Mat warp = im.clone();
  warp.convertTo(warp, CvType.CV_32F);

  for (int i=0; i<triangles.size(); i++) {
    ArrayList<Point> triangle1 = new ArrayList<Point>();
    ArrayList<Point> triangle2 = new ArrayList<Point>();
    int [] triangle = triangles.get(i);
    for (int j=0; j<3; j++) {
      triangle1.add(points1[triangle[j]]);
      triangle2.add(points2[triangle[j]]);
    }
    // Draw the triangle for the 1st image.
    drawTriangles(triangle1, origin);
    // drawTriangles(triangle2, offset1);
    // Warp each triangle from source image to target image.
    warp = warpTriangle(im1s, warp, triangle1, triangle2);
  }
  MatOfInt index1 = new MatOfInt();
  Imgproc.convexHull(new MatOfPoint(points2), index1, false);
  int [] index2 = index1.toArray();
  ArrayList<Point> hull = new ArrayList<Point>();
  for (int i=0; i<index2.length; i++) {
    Point pt = new Point((int)points2[index2[i]].x, 
      (int)points2[index2[i]].y);
    if (rect.contains(pt)) 
      hull.add(pt);
  }

  Mat mask = Mat.zeros(im.size(), im.depth());
  MatOfPoint mp = new MatOfPoint();
  mp.fromList(hull);
  Imgproc.fillConvexPoly(mask, mp, Scalar.all(255));

  // mp.fromList(Arrays.asList(points2));
  Rect r = Imgproc.boundingRect(mp);

  Point centre = new Point((int)((r.tl().x + r.br().x)/2.0), 
    (int)((r.tl().y + r.br().y)/2.0));

  warp.convertTo(warp, CvType.CV_8UC3);
  CVImage last = new CVImage(warp.cols(), warp.rows());
  Mat output = new Mat(im.size(), im.type());

  Photo.seamlessClone(warp, im, mask, centre, output, Photo.NORMAL_CLONE);
  last.copyTo(output);
  //last.copyTo(warp);
  image(last, offset1.x, offset1.y);

  mp.release();
  mask.release();
  im.release();
  warp.release();
}

private Mat warpTriangle(Mat i, Mat o, ArrayList<Point> t1, ArrayList<Point> t2) {
  MatOfPoint m1 = new MatOfPoint();
  MatOfPoint m2 = new MatOfPoint();
  m1.fromList(t1);
  m2.fromList(t2);
  Rect rect1 = Imgproc.boundingRect(m1);
  Rect rect2 = Imgproc.boundingRect(m2);
  ArrayList<Point> triangle1Rect = new ArrayList<Point>();
  ArrayList<Point> triangle2Rect = new ArrayList<Point>();
  ArrayList<Point> triangle2RectInt = new ArrayList<Point>();
  for (int j=0; j<3; j++) {
    triangle1Rect.add(new Point(t1.get(j).x - rect1.x, 
      t1.get(j).y - rect1.y));
    triangle2Rect.add(new Point(t2.get(j).x - rect2.x, 
      t2.get(j).y - rect2.y));
    triangle2RectInt.add(new Point((int)(t2.get(j).x - rect2.x), 
      (int)(t2.get(j).y - rect2.y)));
  }
  Mat mask = Mat.zeros(rect2.height, rect2.width, CvType.CV_32FC3);
  MatOfPoint tmp = new MatOfPoint();
  tmp.fromList(triangle2RectInt);
  Imgproc.fillConvexPoly(mask, tmp, new Scalar(1.0, 1.0, 1.0), 16, 0);
  Mat img1Rect = i.submat(rect1);
  Mat img2Rect = Mat.zeros(rect2.height, rect2.width, img1Rect.type());
  MatOfPoint mm1 = new MatOfPoint();
  MatOfPoint mm2 = new MatOfPoint();
  mm1.fromList(triangle1Rect);
  mm2.fromList(triangle2Rect);
  Mat warp_mat = Imgproc.getAffineTransform(new MatOfPoint2f(mm1.toArray()), 
    new MatOfPoint2f(mm2.toArray()));
  Imgproc.warpAffine(img1Rect, img2Rect, warp_mat, img2Rect.size(), 
    Imgproc.INTER_LINEAR, Core.BORDER_REFLECT_101, Scalar.all(0));
  Core.multiply(img2Rect, mask, img2Rect);
  Mat tmp1 = new Mat(mask.size(), mask.type(), Scalar.all(1.0));
  Core.subtract(tmp1, mask, tmp1);
  Mat tOut = o.clone();
  Mat tmp2 = tOut.submat(rect2);
  Core.multiply(tmp2, tmp1, tmp2);
  Core.add(tmp2, img2Rect, tmp2);
  m1.release();
  m2.release();
  mm1.release();
  mm2.release();
  warp_mat.release();
  tmp.release();
  tmp1.release();
  tmp2.release();
  img1Rect.release();
  img2Rect.release();
  return tOut;
}

private void drawTriangles(ArrayList<Point> p, PVector o) {
  pushStyle();
  noFill();
  stroke(255, 0, 0, 160);
  beginShape();
  for (Point pt : p) {
    vertex((float)pt.x+o.x, (float)pt.y+o.y);
  }
  endShape();
}

private ArrayList<int []> getTriangles(Rect r, Point [] pts) {
  // Construct the Delaunay triangles from the list of Point in pts.
  // Result is in the list of 3 indices of the vertex.
  ArrayList<int []> tri = new ArrayList<int []>();
  Subdiv2D subdiv = new Subdiv2D(r);
  for (Point p : pts) {
    if (r.contains(p)) 
      subdiv.insert(p);
  }
  MatOfFloat6 triangleList = new MatOfFloat6();
  subdiv.getTriangleList(triangleList);
  float [] triangleArray = triangleList.toArray();
  for (int i=0; i<triangleArray.length; i+=6) {
    Point [] pt = new Point[3];
    int [] ind = new int[3];
    pt[0] = new Point(triangleArray[i], triangleArray[i+1]);
    pt[1] = new Point(triangleArray[i+2], triangleArray[i+3]);
    pt[2] = new Point(triangleArray[i+4], triangleArray[i+5]);
    if (r.contains(pt[0]) &&
      r.contains(pt[1]) &&
      r.contains(pt[2])) {
      for (int j=0; j<3; j++) 
        for (int k=0; k<pts.length; k++) 
          if (abs((float)(pt[j].x - pts[k].x)) < DIST &&
            abs((float)(pt[j].y - pts[k].y)) < DIST)
            ind[j] = (int) k;
      tri.add(ind);
    }
  }
  return tri;
}

private ArrayList<MatOfPoint2f> detectFacemarks(Mat i) {
  // Detect face landmark from an Mat image.
  ArrayList<MatOfPoint2f> shapes = new ArrayList<MatOfPoint2f>();
  MatOfRect faces = new MatOfRect();
  Face.getFacesHAAR(i, faces, dataPath(faceFile)); 
  if (!faces.empty()) {
    fm.fit(i, faces, shapes);
  }
  faces.release();
  return shapes;
}

public void keyPressed() {
  if (keyCode == 32) {
    faceIdx++;
    faceIdx %= allFaces.length;
  }
  storeFace();
}

public void mousePressed() {
  saveFrame("output/face####.png");
}
