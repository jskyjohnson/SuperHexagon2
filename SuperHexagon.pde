
import java.util.Iterator;

//Game states
int clock;
boolean newGame;
boolean playingGame;

//Game Objects
ArrayList<Obs> objects;
PlayerObject player;
CenterObject center;

//Player stuff
boolean left;
boolean right;

void setup(){
  size(500, 500);
  newGame = true;
  playingGame = false;
  clock = 0;
}

void tick(){
  
  
   Iterator<Obs> iter = objects.iterator();
   while (iter.hasNext()){
    Obs looking = iter.next();
     if(looking.toremove){
        iter.remove();
     }
    looking.update(); 
    }
  clock++;
}

void draw(){
  background(0);
  
  if(newGame){
   newGame = false;
   playingGame = true;
   objects= new ArrayList<Obs>();
   
   center = new CenterObject();
   objects.add(center);
   player = new PlayerObject();
   objects.add(player); 
  }else if(playingGame){
   tick();
   for(Obs obj: objects){
    obj.display();
   } 
  }
  
}

void keyPressed(){
  
   if(key == 'a'){
    left = true;
   } 
   if(key == 'd'){
    right = true; 
   }
 
}
void keyReleased(){
 
  if(key == 'a'){
  left = false;
 } 
 if(key == 'd'){
  right = false; 
 } 
}



abstract class Obs{
  float x;
  float y;
  float rotation;
  boolean toremove;
  
  void update(){}
  void display(){}
  void collision(){}
}
abstract class ObsCent extends Obs{
  float rotationspeed;
  float radius;
}

class PlayerObject extends ObsCent{
  float ORBITDISTANCE = center.radius + 5;
  float ORBITACCELERATION = .01;
  PlayerObject(){
    x = 0;
    y = -ORBITDISTANCE; 
    radius = 5;
    rotation = 0;
    toremove = false;
    rotationspeed = 0.0;
  }
  void update(){

    if(left){
     rotationspeed-=ORBITACCELERATION; 
    }
    if(right){
     rotationspeed+=ORBITACCELERATION; 
    }
    if(!left&&!right || left&&right){
     rotationspeed = 0; 
    }
    
    if(Math.abs(rotationspeed)>.1){
      if(left){
       rotationspeed = 20*(-ORBITACCELERATION); 
      }else{
       rotationspeed = 20*(ORBITACCELERATION); 
      }  
    }
    rotation+=rotationspeed;
  }
  void collision(){
    
  }
  void display(){
    pushMatrix();
     translate(width/2,height/2);
     rotate(rotation);
     stroke(255);
     line(-5+ORBITDISTANCE, -4, 5+ORBITDISTANCE, 0);
     line(-5+ORBITDISTANCE, 4, 5+ORBITDISTANCE, 0);
     line(-3+ORBITDISTANCE, -3, -3+ORBITDISTANCE, 3);
     //ellipse(ORBITDISTANCE,0,radius,radius);
    popMatrix();
  }
}

class CenterObject extends ObsCent{
  
  int sides;
  Shape dishape;
  CenterObject(){ 
   sides = 6;
   x = width/2;
   y = height/2;
   radius = 20f;
  }
  void update(){
    dishape = new Shape(6, radius);
  }
  void collision(){
    
  }
  void display(){
    pushMatrix();
     translate(width/2, height/2);
     stroke(255);
     dishape.display();
    popMatrix();
  }
}
class Shape{
 int sides; 
 float radius;
 ArrayList<Vertices> verts;
 Shape(int sides, float r){
   verts = new ArrayList<Vertices>();
   radius = r;
   float intangle =(float) (2*Math.PI)/sides;
    for(int i = 0; i < sides; i++){
      this.vertex((float)(radius*Math.cos(intangle*(i))) ,(float) (radius*Math.sin(intangle*(i))));
    } 
 }
 void vertex(float a, float b){
   Vertices k = new Vertices(a, b);
   verts.add(k);
 }
 void display(){
   for(int i = 0; i < verts.size()-1; i++){
     line(verts.get(i).x, verts.get(i).y, verts.get(i+1).x, verts.get(i+1).y);
   }
   line(verts.get(verts.size()-1).x, verts.get(verts.size()-1).y, verts.get(0).x, verts.get(0).y);
   
 }
 
}
class Vertices{
  float x;
  float y;
  Vertices(float a, float b){
   x = a;
   y = b; 
  }
  String toString(){
   return x + " " + y; 
  }
}
