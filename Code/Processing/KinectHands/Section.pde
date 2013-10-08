
class Section {
  PVector[] quad = new PVector[4];
  int id;
  boolean active;
  boolean selected;
  boolean hovered; 

  Section() {
    id = nextID++;
    selected = false;
    hovered = false;
    active = true;
    for (int i=0; i<4; i++)
      quad[i] = new PVector();
  }


  void draw(PGraphics canvas, boolean sel) {
    PVector p = new PVector();
    PVector v = new PVector();

    canvas.stroke(255, 0, 0);
    canvas.fill(255, 0, 0, 64);

    PVector center = new PVector();
    for (int k=0; k<4; k++) 
      center = PVector.add(center, quad[k]);
    center = PVector.mult(center, 0.25);

    if (context!=null) {
      canvas.strokeWeight(1);
      canvas.stroke(255, 255, 0);
      context.convertRealWorldToProjective(center, p);
      context.convertRealWorldToProjective(handR, v);
      canvas.line(p.x, p.y, v.x, v.y);
    }

    canvas.strokeWeight(6);

    if (!active) {
      canvas.fill(255, 0, 0, 64);
      canvas.stroke(255, 0, 0);
    }

    if (hovered) {
      canvas.fill(255, 255, 255, 64);
      canvas.stroke(255, 255, 255);
    }

    if (selected) {
      canvas.fill(0, 255, 255, 64);
      canvas.stroke(0, 255, 255);
    }

    if (sel) {
      canvas.noStroke();
      canvas.fill(id);
    }
    if (context!=null) {
      canvas.beginShape(QUADS);
      context.convertRealWorldToProjective(quad[0], p);    
      canvas.vertex(p.x, p.y, 0);
      context.convertRealWorldToProjective(quad[1], p);    
      canvas.vertex(p.x, p.y, 0);
      context.convertRealWorldToProjective(quad[3], p);    
      canvas.vertex(p.x, p.y, 0);
      context.convertRealWorldToProjective(quad[2], p);    
      canvas.vertex(p.x, p.y, 0);
      canvas.endShape();
    }
  }

  PVector center() {
    PVector center = new PVector();
    for (int k=0; k<4; k++) 
      center = PVector.add(center, quad[k]);
    return PVector.mult(center, 0.25);
  }
}

