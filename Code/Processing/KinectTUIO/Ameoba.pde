class Ameoba
{
  PVector pos;
  PVector vel;
  float rot;
  float phase = random(0, 180);
  
  Ameoba() {
    pos = new PVector(random(0, width), random(0, height), 0);
    vel = new PVector(random(-1, 1), random(-1, 1), 0);
    rot = random(-180, 180);  
}

  void update() {
    rot = (rot +1.0/360) % 360;
    if (pos.x > width || pos.x < 0)
      vel.x = -vel.x;

    if (pos.y > height || pos.y < 0)
      vel.y = -vel.y;

    pos = PVector.add(pos, vel);
  }

  void draw() {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    float s = cos(frameCount * 0.01 + phase) / 2;
    scale(1 + s,  1 + s, 1);
    rotate(rot);
    fill(0);
    ellipse(0, 0, 30, 30);
    ellipse(10, 15, 30, 30);
    ellipse(-10, 15, 30, 30);

    fill(230);
    ellipse(0, 0, 15, 15);
    ellipse(10, 15, 15, 15);
    ellipse(-10, 15, 15, 15);

    popMatrix();
  }
}

