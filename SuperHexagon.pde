import ddf.minim.*;
import ddf.minim.analysis.*;
import javax.swing.JFileChooser;
import java.util.Iterator;

//Sound stuff
class BeatListener implements AudioListener{
  private BeatDetect beat;
  private AudioPlayer source;
   BeatListener(BeatDetect beat, AudioPlayer source){
    this.source = source;
    this.source.addListener(this);
    this.beat = beat;
   }
   void samples(float[] samps){
    beat.detect(source.mix);
   }
   void samples(float[] sampsL, float[] sampsR){
    beat.detect(source.mix);
   }
}
 
AudioPlayer song;
BeatDetect beat;
BeatListener bl;
Minim minim;
FFT fft;

//Game states
int clock;
boolean newGame;
boolean playingGame;
boolean canSpawn;
int spawnclock;
//Game Objects
ArrayList<Obs> objects;
ArrayList<Obs> toAdd;


PlayerObject player;
BackgroundObject back;
CenterObject center;
BeatBarObject beatBar;
//Player stuff
boolean left;
boolean right;
void setup(){
  size(500, 500);
  smooth();
  minim = new Minim(this);
  newGame = true;
  playingGame = false;
  clock = 0;
  spawnclock = 0;
}
void tick(){
  fft.forward(song.mix);
   Iterator<Obs> iter = objects.iterator();
   while (iter.hasNext()){
    Obs looking = iter.next();
     if(looking.toremove){
        iter.remove();
     }
    looking.update(); 
   }
   
  for(Obs ob:toAdd){
   objects.add(ob);
  }
  toAdd = new ArrayList<Obs>();
  clock++;
  spawnclock++;
}
void draw(){
  if(newGame){
//    JFileChooser chooser = new JFileChooser();
//    int returnValue = chooser.showOpenDialog(null);
//    if(returnValue == JFileChooser.APPROVE_OPTION){
//     File file = chooser.getSelectedFile();
//     song = minim.loadFile(file.getAbsolutePath(), 1024); 
//    }
   song = minim.loadFile("song.mp3", 1024);
   song.play();
   beat = new BeatDetect(song.bufferSize(), song.sampleRate());
   beat.setSensitivity(1000);
   bl = new BeatListener(beat, song);
   newGame = false;
   playingGame = true;
   fft = new FFT(song.bufferSize(), song.sampleRate());
   
   objects= new ArrayList<Obs>();
   toAdd = new ArrayList<Obs>();
   center = new CenterObject(0);
   objects.add(center);
   player = new PlayerObject(1);
   objects.add(player);
   back = new BackgroundObject(); 
   objects.add(0, back);
   beatBar = new BeatBarObject();
   objects.add(beatBar);
   spawnclock = 0;
   
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
   if(key == 'v'){
     for(int i = 0; i <center.sides; i++){
      EnemyObject k = new EnemyObject(i);
      objects.add(k);   
     }
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
void stop(){
 song.close();
 minim.stop(); 
 super.stop();
}
abstract class Obs{
  int id;
  float x;
  float y;
  float rotation;
  boolean toremove;
  
  void update(){}
  void display(){}
  void collision(){}
  void beat(){}
}
abstract class ObsCent extends Obs{
  float rotationspeed;
  float radius;
}

class BeatBarObject extends Obs{
  ArrayList<Float> values;
  ArrayList<Color> colors;
  ArrayList<Float> energy;
 
  BeatBarObject(){
    values = new ArrayList<Float>(beat.dectectSize());
    for(int i = 0; i < beat.dectectSize(); i++){
     values.add(1f); 
    }
    colors = new ArrayList<Color>(beat.dectectSize());
    for(int i = 0; i < beat.dectectSize(); i++){
     colors.add(new Color(0,0,0)); 
    }
    energy = new ArrayList<Float>();
    for(int i = 0; i < beat.dectectSize(); i++){
      energy.add(10f);
    }
   
    
  }
  void update(){
    int numberBeats =0;
    for(int i = 0; i < beat.dectectSize()-1; i++){
     int ffti = (fft.specSize()/ beat.dectectSize()) * i; 
     if(beat.isRange(i, i+1, 1)){
       
      values.set(i, fft.getBand(ffti));
      for(Obs ob: objects){
       if(ob.id == i){
        ob.beat();
       }
      }
     } 
     values.set(i, values.get(i)*.9);
      
     int red= 0;
     int green = 0;
     int blue = 0;
     double freq = (Math.log((fft.getBand(ffti))+1))/2;
    
     red   =(int) (Math.sin(freq)* 127 + 128);
     green =(int) (Math.sin(freq+(Math.PI/3)) * 127 + 128);
     blue  =(int) (Math.sin(freq+((2*Math.PI)/3)) * 127 + 128);
     colors.set(i, new Color(red, green, blue)); 
     if(!canSpawn){
      if(spawnclock > 50){
       canSpawn = true;
       spawnclock = 0;
      } 
     }
     if(fft.getBand(ffti)>energy.get(i) && canSpawn){
       ArrayList<Integer> taken = new ArrayList<Integer>();
       for(int i2 = 0; i2 < (Math.random()*center.sides-1);i2++){
         int newInt =(int) (Math.random()*center.sides);
         boolean already = false;
         for(int checker = 0; checker < taken.size(); checker++){
          if(newInt == taken.get(checker)){
           already =true; 
          }
         }
         if(!already){
         taken.add(newInt);  
         } 
        }
       System.out.println(taken);
       for(int lo = 0; lo < taken.size(); lo++){
         toAdd.add( new EnemyObject((int)(taken.get(lo))));
       }
       canSpawn = false;   
      } 
     energy.set(i,energy.get(i)+.7*fft.getBand(ffti));
    }
    for(int i = 0; i < energy.size(); i++){
     energy.set(i, energy.get(i)*.9);
    }
    
    
  }
  void display(){
    pushMatrix();
    
    for(int i = 0; i <beat.dectectSize(); i++){
    int ffti = (fft.specSize()/ beat.dectectSize()) * i;
    stroke(0,0);
    fill(colors.get(i).red,colors.get(i).green ,colors.get(i).blue);
      rect(width/(values.size()-1) * i, height, width/(values.size()-1), -5*values.get(i));
    }
    popMatrix();
  }
  void beat(){
    
  }
}

class EnemyObject extends ObsCent{
 int idtrack;
 float beatCo;
 float incomingspeed;
 float SIZE;
 float radius2;
 EnemyObject(int id2){
  id = id2;
  idtrack = id2;
  x = 0;
  y = 0;
  radius = width;
  radius2 = width+15;
  incomingspeed = 2;
 } 
 void update(){
   radius -= incomingspeed;
   radius2 = radius+15;
   if(Math.abs(radius) < 1){
     toremove = true;
   }
   beatCo*=.9;
   
 }
 void display(){
   pushMatrix();
   stroke(255);
   translate(width/2, height/2);
   
   //rotate((float)((Math.PI*2)/center.sides)*idtrack);
   float xa = (float) (radius*Math.cos(((Math.PI*2)/center.sides)*(idtrack))) ;
   float ya = (float) (radius*Math.sin(((Math.PI*2)/center.sides)*(idtrack)));
   float xb = (float) (radius*Math.cos(((Math.PI*2)/center.sides)*(idtrack+1)));
   float yb = (float) (radius*Math.sin(((Math.PI*2)/center.sides)*(idtrack+1)));
   float xc = (float) (radius2*Math.cos(((Math.PI*2)/center.sides)*(idtrack)));
   float yc = (float) (radius2*Math.sin(((Math.PI*2)/center.sides)*(idtrack)));
   float xd = (float) (radius2*Math.cos(((Math.PI*2)/center.sides)*(idtrack+1))) ;
   float yd = (float) (radius2*Math.sin(((Math.PI*2)/center.sides)*(idtrack+1)));
   float x1 = (float) ((radius + ((radius2-radius)/2))*Math.cos(((Math.PI*2)/center.sides)*idtrack));
   float x2 = (float) ((radius + ((radius2-radius)/2))*Math.cos(((Math.PI*2)/center.sides)*(idtrack+1)));
   float x3 = (float)(x1+x2)/2;
   float y1 = (float) ((radius + ((radius2-radius)/2))*Math.sin(((Math.PI*2)/center.sides)*idtrack));
   float y2 = (float) ((radius + ((radius2-radius)/2))*Math.sin(((Math.PI*2)/center.sides)*(idtrack+1)));
   float y3 = (float)(y1+y2)/2;
   line(xa,ya,xb,yb);
   line(xc,yc,xd,yd);
   line(xa,ya,xc,yc);
   line(xb,yb,xd,yd); 
   float ka = distance(x3, y3, xa, ya);
   float nxa = unit(ka, x3, xa) * ka;
   float nya = unit(ka, y3, ya) * ka;
   float kb = distance(x3, y3, xb, yb);
   float nxb = unit(kb, x3, xb) * kb;
   float nyb = unit(kb, y3, yb) * kb;
   float kc = distance(x3, y3, xc, yc);
   float nxc = unit(kc, x3, xc) * kc;
   float nyc = unit(kc, y3, yc) * kc;
   float kd = distance(x3, y3, xd, yd);
   float nxd = unit(kd, x3, xd) * kd;
   float nyd = unit(kd, y3, yd) * kd;
   stroke(0,0);
   fill(beatBar.colors.get(id).red,beatBar.colors.get(id).green,beatBar.colors.get(id).blue);
   triangle(x3, y3,nxa*beatCo+x3,nya*beatCo+y3,nxb*beatCo+x3,nyb*beatCo+y3);
   triangle(x3, y3,nxa*beatCo+x3,nya*beatCo+y3,nxc*beatCo+x3,nyc*beatCo+y3);
   triangle(x3, y3,nxd*beatCo+x3,nyd*beatCo+y3,nxc*beatCo+x3,nyc*beatCo+y3);
   triangle(x3, y3,nxb*beatCo+x3,nyb*beatCo+y3,nxd*beatCo+x3,nyd*beatCo+y3);
   popMatrix();
 }
 void beat(){
   beatCo = 1;
 }
 void collision(){
   
 }
 float unit(float k, float a, float b){
   return (a-b)/k;
 }
 float distance(float a, float b, float c, float d){
   float k = (float)Math.sqrt(Math.pow(a-c,2) +Math.pow(b-d,2) );
   return k; 
 }
}

class BackgroundObject extends ObsCent{
 int numberSides;
 BackgroundObject(){
  x = 0;
  y = 0;
  rotation = 0;
  toremove = false; 
 }
 void update(){
   numberSides = center.sides;
 }
 void display(){
   pushMatrix();
   translate(width/2, height/2);
   for(int i = 0; i < numberSides; i++){
     if(i%2 == 1){
      fill(50);
     }else{
      fill(130); 
     }
    stroke(0,0);
    triangle((float)0,(float) 0,(float) (width*Math.cos(((Math.PI*2)/numberSides)*i)),(float) (height*Math.sin(((Math.PI*2)/numberSides)*i)),(float) (width*Math.cos(((Math.PI*2)/numberSides)*(i+1))),(float) (height*Math.sin(((Math.PI*2)/numberSides)*(i+1))));
   }
   popMatrix();
 }
 void beat(){
   
 }
}

class PlayerObject extends ObsCent{
  float ORBITDISTANCE = center.radius + 10;
  float ORBITACCELERATION = .01;
  float beatCo;
  PlayerObject(int idd){
    id = idd;
    x = 0;
    beatCo = 1;
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
    beatCo*= .9;
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
     triangle(-3*beatCo+ORBITDISTANCE, (-3*beatCo), (-3)*beatCo+ORBITDISTANCE, 3*beatCo, 5*beatCo+ORBITDISTANCE, 0);
     //ellipse(ORBITDISTANCE,0,radius,radius);
    popMatrix();
  }
  void beat(){
   beatCo = 1;
  }
}

class CenterObject extends ObsCent{
  float beatCo;
  int sides;
  Shape dishape;
  CenterObject(int idd){
   id = idd; 
   sides = 6;
   x = width/2;
   beatCo = 1;
   y = height/2;
   radius = 20f;
  }
  void update(){
    dishape = new Shape(6, radius);
    beatCo *= .9;
  }
  void collision(){
    
  }
  void display(){
    pushMatrix();
     translate(width/2, height/2);
     stroke(255);
     dishape.display();
     dishape.beat(beatCo);
    popMatrix();
  }
  void beat(){
    beatCo = 1;
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
 void beat(float beatCo){
   fill(255);
    for(int i = 0; i < verts.size()-1; i++){
     triangle(0,0,verts.get(i).x * beatCo, verts.get(i).y * beatCo, verts.get(i+1).x * beatCo,  verts.get(i+1).y * beatCo);
   }
   triangle(0,0,verts.get(verts.size()-1).x* beatCo, verts.get(verts.size()-1).y* beatCo, verts.get(0).x* beatCo, verts.get(0).y* beatCo);
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
class Color{
 int red;
 int green;
 int blue;
 Color(int a, int b, int c){
  red = constrain(a, 0, 255);
  green = constrain(b, 0, 255);
  blue = constrain(c, 0, 255);
 } 
}
