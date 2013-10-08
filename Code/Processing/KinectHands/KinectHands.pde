import SimpleOpenNI.*;
//import oscP5.*;
//import netP5.*;
import hypermedia.net.*;
import ddf.minim.*;
import java.util.*;
import TUIO.*;


SimpleOpenNI context;
Minim minim;
AudioInput input;
//OscP5 oscP5;
AudioPlayer player;
UDP udp;


int NUM_SECTIONS = 2;
Section[] sections = new Section[NUM_SECTIONS];
Section funSection = new Section();
int s = 0;
int q = 0;

boolean fun = false;
boolean  autoCalib = true;
PVector handL = new PVector();
PVector handR = new PVector();
float  confidence;
PGraphics selBuf;
int nextID = 1;
int[] userMap;
ArrayList<Integer> userIds = new ArrayList<Integer>();
int hoverSection = 0;
int lastSection = -1;

void setup()
{
  size(640, 480, OPENGL);
  smooth();
  noLoop();

  selBuf = createGraphics(640, 480, OPENGL);

  //  oscP5 = new OscP5(this,12000);
  TuioProcessing tuioClient = new TuioProcessing(this);


   context = new SimpleOpenNI(this);
   
   context.setMirror(true);
   context.enableDepth();
   context.enableScene();
   
   
   // enable skeleton generation for all joints
   //  context.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
   //context.enableUser(SimpleOpenNI.SKEL_PROFILE_UPPER);
   context.enableUser(SimpleOpenNI. SKEL_PROFILE_HEAD_HANDS);
   
   context.enableGesture();
   context.enableHands();
   
   context.setSmoothingHands(.5);
   
   //  context.addGesture("RaiseHand");
   context.addGesture("Wave");
   //  context.addGesture("Push");  
   //  context.addGesture("Swipe");
   //  context.addGesture("Steady");
   //  context.addGesture("Circle");


  udp = new UDP( this, 6001);
  udp.log( true );

  minim = new Minim(this);
  //  minim.debugOn();
  input = minim.getLineIn();

  for (int i=0; i<NUM_SECTIONS;i++)
    sections[i] = new Section();

  // enable depthMap generation 
  if (context !=null && context.enableDepth() == false)
  {
    println("Can't open the depthMap, maybe the camera is not connected!"); 
    exit();
    return;
  }

  if (false)
    if (context != null && context.enableRGB() == false)
    {
      println("Can't open the rgbMap, maybe the camera is not connected or there is no rgbSensor!"); 
      exit();
      return;
    }

  loop();
}

void draw()
{
  // update the cam
  if (context != null)
    context.update();

  background(0);

  //translate(0, 0, -1000);

  //image(context.rgbImage(), 0, 0);
  //  image(context.depthImage(), 0, 0);
  if (context != null) 
    image(context.sceneImage(), 0, 0);


  //  // if we have detected any users
  //  if (context.getNumberOfUsers() > 0) { 
  //
  //    // find out which pixels have users in them
  //    userMap = context.getUsersPixels(SimpleOpenNI.USERS_ALL); 
  //
  //    loadPixels(); 
  //
  //    for (int i = 0; i < userMap.length; i++) { 
  //      // if the current pixel is on a user
  //      if (userMap[i] != 0) {
  //        // make it green
  //        color c = pixels[i];
  //        pixels[i] = color(red(c)/2, (int)green(c) | 0xff, blue(c) / 2);
  //      }
  //    }
  //    // display the changed pixel array
  //    updatePixels();
  //  }

  if (context !=null) {
    int[] userList = context.getUsers(); 
    if (userList.length > 0) { 
      int userId = userList[0];    
      if ( context.isTrackingSkeleton(userId)) {

        noStroke();
        fill(255, 0, 0);
        PVector v = new PVector();

        confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HAND, handL);
        context.convertRealWorldToProjective(handL, v);
        ellipse(v.x, v.y, 10, 10); 

        //println(jointPos_Proj.x + ", " + jointPos_Proj.y  + ", " + jointPos_Proj.z);

        confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HAND, handR);
        context.convertRealWorldToProjective(handR, v);
        ellipse(v.x, v.y, 10, 10);
      }
    }

    for (int i=0; i<sections.length; i++) {
      sections[i].draw(this.g, false);
      PVector[] quad = sections[i].quad;

      stroke(255, 0, 255);
      PVector u = PVector.sub(quad[1], quad[0]);
      PVector v = PVector.sub(quad[2], quad[0]);
      PVector n = u.cross(v);

      PVector center = new PVector();
      for (int k=0; k<4; k++) 
        center = PVector.add(center, quad[k]);
      center = PVector.mult(center, 0.25);

      PVector p = new PVector();
      PVector t = new PVector();    
      context.convertRealWorldToProjective(center, p);
      context.convertRealWorldToProjective(PVector.add(center, PVector.mult(n, 1)), t);
      line(p.x, p.y, t.x, t.y);
    }
  }

  funSection.draw(this.g, false);

  if (context != null)
    hoverSection = getHoveredSection(sections) + 1;

  //  OscMessage oscMsg = new OscMessage("/handR");
  //  oscMsg.add(handR.x);
  //  oscMsg.add(handR.y);
  //  oscMsg.add(handR.z);
  //  oscP5.send(oscMsg, new NetAddress("127.0.0.1",32000));

  boolean h = PVector.dist(handR, funSection.center()) < 330;
  if (h && funSection.hovered != h) {
    //    player = minim.loadFile("../KinectTUIO/data/wwf.mp3");
    //    player.play();
  }
  funSection.hovered = h;

  if (hoverSection != lastSection) {
    println("Section changed: " + hoverSection);

    //    udp.send(""+hoverSection, "192.168.2.107", 6000);
    udp.send(""+hoverSection, "172.20.10.2", 6000);

    //    oscMsg = new OscMessage("/section");
    //    oscMsg.add(hoverSection);
    //    oscP5.send(oscMsg, new NetAddress("127.0.0.1",32000));

    lastSection = hoverSection;
  }

  if (fun) {
    fill(255, 0, 255, 64);
    rect(0, 0, width, height);
  }

  noStroke();
  float level = input.mix.level();
  level = (float)(20*Math.log10(level)) + 60;
  if (level > 40) {
    //    getPoints();
    fill(255, 0, 0);
  }
  else
    fill(0, 255, 0);
  rect(0, 0, 10, (int)(height * level / 60.0));
  fill(0);
  text((int)level + "dB", 10, 40);
  text("FPS: " + frameRate, 10, 20);


  text("Section: " + s, 10, 60);
  //  context.drawCamFrustum();
}

// -----------------------------------------------------------------
// SimpleOpenNI user events

void onNewUser(int userId)
{
  println("onNewUser - userId: " + userId);
  println("  start pose detection");

  userIds.add(userId);

  if (autoCalib)
    context.requestCalibrationSkeleton(userId, true);
  else    
    context.startPoseDetection("Psi", userId);
}

void onLostUser(int userId)
{
  println("onLostUser - userId: " + userId);
}

void onExitUser(int userId)
{
  println("onExitUser - userId: " + userId);
}

void onReEnterUser(int userId)
{
  println("onReEnterUser - userId: " + userId);
}


void onStartCalibration(int userId)
{
  println("onStartCalibration - userId: " + userId);
}

void onEndCalibration(int userId, boolean successfull)
{
  println("onEndCalibration - userId: " + userId + ", successfull: " + successfull);

  if (successfull) 
  { 
    println("  User calibrated !!!");
    context.startTrackingSkeleton(userId);
  } 
  else 
  { 
    println("  Failed to calibrate user !!!");
    println("  Start pose detection");
    context.startPoseDetection("Psi", userId);
  }
}

void onStartPose(String pose, int userId)
{
  println("onStartdPose - userId: " + userId + ", pose: " + pose);
  println(" stop pose detection");

  context.stopPoseDetection(userId); 
  context.requestCalibrationSkeleton(userId, true);
}

void onEndPose(String pose, int userId)
{
  println("onEndPose - userId: " + userId + ", pose: " + pose);
}

// -----------------------------------------------------------------
// Keyboard events


int getHoveredSection(Section[] sections) {
  double md = Double.POSITIVE_INFINITY; 
  int idx = -1;
  for (int i=0; i<sections.length; i++) {
    double d = PVector.dist(handR, sections[i].center());
    if (d < md) { 
      md = d;
      for (int j=0; j<sections.length; j++)
        sections[j].hovered = false;
      if (d < 330) {
        sections[i].hovered = true;
        idx = i;
      }
    }
  }
  return idx;
}


void getPoints() {
  PVector[] quad = sections[s].quad;
  if (fun)
    quad = funSection.quad;
  PVector p = new PVector();

  quad[q] = handL.get();
  q = (q + 1) % 4;

  quad[q] = handR.get();      
  s = q == 3 ? s + 1 : s;
  s = s % NUM_SECTIONS;     
  q = (q + 1) % 4;

  println(s);
  println(quad);
}

void keyPressed()
{
  switch(key)
  {
  case 'f':
    fun = !fun;
    break;

  case ' ':
    //    context.setMirror(!context.mirror());
    getPoints();
    break;
  }

  //  int i = 0;
  switch(keyCode)
  {

  case DELETE:
    int i = 0;
    for (; i<sections.length-1; i++)
      if (sections[i].selected) break;
    for (int j=0; j<4; j++)
      sections[i].quad[j] = new PVector();  
    break;

  case ENTER:
    getPoints();
    break;
  }
}

void mousePressed() {  
  if (mouseButton == RIGHT) {
    getPoints();
    return;
  }

  selBuf.beginDraw();
  selBuf.background(0, 0, 0);

  for (int i=0; i<sections.length; i++)
    sections[i].draw(selBuf, true);

  selBuf.endDraw();

  int p = selBuf.get(mouseX, mouseY);

  for (int i=0; i<sections.length; i++) {
    sections[i].selected = color(sections[i].id) == p;
    if (color(sections[i].id) == p)
      println(i);
  }
}

void mouseReleased() {
  if (mouseButton == RIGHT) {
    getPoints();
    return;
  }
}

void stop() {
  input.close();
  minim.stop();
  super.stop();
}

//void oscEvent(OscMessage msg) {
//  msg.print();
//
//  if (msg.checkTypetag("siiffffffff")) {
//    if (msg.get(3).floatValue() < 0.25) {
//      player = minim.loadFile("../sounds/chaser.wav");
//      player.play();
//    }
//  }
//}

void addTuioObject(TuioObject tobj) {
  //  player = minim.loadFile("../sounds/chaser.wav");
  //  player.play();
  println(tobj);
}

void removeTuioObject(TuioObject tobj) {
  boolean r = false;
  if (sections.length > 2)
    for (int i=0; i<3; i++) {    
      r = r || sections[i].hovered;
    }
  if (r) {
    //    player = minim.loadFile("../sounds/check.wav");
    //    player.play();
  }
}

void onRecognizeGesture(String strGesture, PVector idPosition, PVector endPosition)
{
  println("onRecognizeGesture - strGesture: " + strGesture + ", idPosition: " + idPosition + ", endPosition:" + endPosition);

  if (strGesture.equals("Wave")) 
  {
    udp.send("Wave", "172.20.10.2", 6000);
    //    udp.send("Wave", "192.168.2.107", 6000);
    //    player = minim.loadFile("../sounds/check.wav");
    //    player.play();

    //    OscMessage oscMsg = new OscMessage("/Wave");
    //    oscP5.send(oscMsg, new NetAddress("127.0.0.1",32000));
  }
}

