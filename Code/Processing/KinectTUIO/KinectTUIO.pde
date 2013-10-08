import ddf.minim.*;
import TUIO.*;
import hypermedia.net.*;

Section sections[] = new Section[2];
Ameoba ameobas[] = new Ameoba[20];

Minim minim;
AudioInput input;
AudioPlayer player;

UDP udp;


int barmanSection = 0;

void setup() {
  size(1024, 768, P3D);
  PFont font = createFont("impact.ttf", 32);
  textFont(font, 32);

  sections[0] = new Section();
  sections[1] = new Section();

  for (int i=0; i<ameobas.length; i++)
    ameobas[i] = new Ameoba();

  minim = new Minim(this);
  TuioProcessing tuioClient = new TuioProcessing(this, 3333);
  TuioProcessing tuioClient2 = new TuioProcessing(this, 3332);

  udp = new UDP( this, 6000 );
  udp.log( true );
  udp.listen( true );
}

void stop() {
  input.close();
  minim.stop();
  super.stop();
}


void draw()
{
  background(235, 255, 64);

  int gap  = 100;

  noStroke();
  if (barmanSection != 0) {
    fill(255, 0, 255);
    rect(barmanSection == 1 ? 0 : width / 2 + gap, 0, width / 2 - gap, height);
  }

  for (Ameoba a: ameobas) {
    a.update();
    a.draw();
  }

  fill(0);
  text("Section1: " + sections[0].drinks.size(), 20, 40);
  text("Section2: " + sections[1].drinks.size(), 20 + width / 2 + gap, 40);

  for (int j=0; j<2; j++)
    for (int i=0; i<sections[j].drinks.size(); i++) 
    {
      Drink d = sections[j].drinks.get(i);
      if (j==barmanSection)
        fill(255, 0, 255);
      else
        fill(235, 255, 64);

      int x = (j == 0 ? 0 : width / 2 + gap);
      int y = 80 + 40 * i;
      text(d.name(), 20 + x, y);
      text("10NIS", width / 2 - gap + x, y);
    }
}

// called when an object is added to the scene
void addTuioObject(TuioObject tobj) {
  //  println("add object "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle());

  if (barmanSection != 0) 
  {  
    player = minim.loadFile("data/cork.wav");
    player.play();

    Drink d = new Drink();
    d.id = tobj.getSymbolID();
    sections[barmanSection - 1].drinks.add(d);
  }
}


// called when an object is removed from the scene
void removeTuioObject(TuioObject tobj) {
  //  println("remove object "+tobj.getSymbolID()+" ("+tobj.getSessionID()+")");

  if (barmanSection != 0) {  
    player = minim.loadFile("data/beep.wav");
    player.play();
  }
}

// called when an object is moved
void updateTuioObject (TuioObject tobj) {
  //  println("update object "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle()
  //    +" "+tobj.getMotionSpeed()+" "+tobj.getRotationSpeed()+" "+tobj.getMotionAccel()+" "+tobj.getRotationAccel());
}

// called when a cursor is added to the scene
void addTuioCursor(TuioCursor tcur) {
  //  println("add cursor "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY());
}

// called when a cursor is moved
void updateTuioCursor (TuioCursor tcur) {
  //  println("update cursor "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY()
  //    +" "+tcur.getMotionSpeed()+" "+tcur.getMotionAccel());
}

// called when a cursor is removed from the scene
void removeTuioCursor(TuioCursor tcur) {
  //  println("remove cursor "+tcur.getCursorID()+" ("+tcur.getSessionID()+")");
}

// called after each message bundle
// representing the end of an image frame
void refresh(TuioTime bundleTime) {
}

void receive( byte[] data ) {
  String message = new String(data);
  message = trim(message);

  if (message.length() > 1 && message.equals("Wave"))
  {
    if (barmanSection==0) {
      player = minim.loadFile("data/oom.mp3");
      player.play();
    }
    else {
      sections[barmanSection - 1].drinks.clear();
      player = minim.loadFile("data/check.wav");
      player.play();
    }
  }
  else {
    int i = parseInt(message);

    if ( barmanSection != i) {
      if (i==0) {
        //      player = minim.loadFile("data/sfx_punch.wav");
        //      player.play();
      }
      else {
        player = minim.loadFile("data/sfx2.wav");
        player.play(10);
      }
    }
    barmanSection = i;
  }
  println(message);
}

