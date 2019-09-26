public class FacePhoto {
  private String fName;
  private PImage img;
  private boolean loaded;

  public FacePhoto(String f) {
    fName = f;
    img = null;
    loaded = false;
  }

  public void loadFile() {
    img = loadImage("photos/" + fName + ".png");
    if (img.width > 0) 
      loaded = true;
  }

  public boolean isLoaded() {
    return loaded;
  }

  public PImage getImage() {
    return img;
  }

  public void release() {
    img = null;
    loaded = false;
  }

  public String getName() {
    return fName;
  }
}
