class Room{
  float[][] walls;
  float[] wall_lengths;
  float[] zs;
  float TOTAL_WALL_LENGTH;
  public Room(float[][] _walls, float[] _zs){
    walls = _walls;
    zs = _zs;
    TOTAL_WALL_LENGTH = 0;
    wall_lengths = new float[walls.length];
    for(int i = 0; i < walls.length; i++){
      int j = (i+1)%walls.length;
      wall_lengths[i] = dist(walls[i][0],walls[i][1],walls[j][0],walls[j][1]);
      int to_add = (int)min(1.0,(wall_lengths[i]/WINDOW_W));
      for(int k = 0; k < to_add; k++){
        float[] coor = {TOTAL_WALL_LENGTH+random(WINDOW_W/2,wall_lengths[i]-WINDOW_W/2),random(WINDOW_H,500-WINDOW_H)};
        Window newWindow = new Window(coor);
        windows.add(newWindow);
      }
      TOTAL_WALL_LENGTH += wall_lengths[i];
    }
  }
  float getMaxDim(int d){
    if(d == 0){
      return TOTAL_WALL_LENGTH;
    }else if(d == 1){
      return zs[1]-zs[0];
    }
    return 0;
  }
  float getTotalWall(int wallN){
    int cum = 0;
    for(int w = 0; w < wallN; w++){
      cum += wall_lengths[w];
    }
    return cum;
  }
  float[] getWhatWallOn(float coorW){
    int cum = 0;
    for(int w = 0; w < walls.length; w++){
      if(coorW >= cum && coorW < cum+wall_lengths[w]){
        float[] result = {w,(coorW-cum)/wall_lengths[w]};
        return result;
      }
      cum += wall_lengths[w];
    }
    float[] result = {walls.length-1,1};
    return result;
  }
  float[] wallCoor_to_realCoor(float[] coor){
    float[] result = new float[4];
    result[2] = coor[1];

    float[] w = getWhatWallOn(coor[0]);
    int w1 = (int)w[0];
    int w2 = (w1+1)%walls.length;
    float prog = w[1];
    
    result[0] = lerp(walls[w1][0],walls[w2][0],prog);
    result[1] = lerp(walls[w1][1],walls[w2][1],prog);
    result[3] = atan2(walls[w2][1]-walls[w1][1],walls[w2][0]-walls[w1][0]);
    return result;
  }
  
  float[] swatterHelper(float[] coor, float R){
    float[] coorW1 = getWhatWallOn(coor[0]-R);
    float[] coorW2 = getWhatWallOn(coor[0]+R);
    int wall_n1 = (int)coorW1[0];
    int wall_n2 = (int)coorW2[0];
    
    float[] result = new float[wall_n2-wall_n1+2];
    result[0] = coor[0]-R;
    result[result.length-1] = coor[0]+R;
    for(int i = 1; i < result.length-1; i++){
      result[i] = getTotalWall(wall_n1+i);
    }
    return result;
    
    /*if(wall_n1 == wall_n2){
      float[] result = {coor[0]-R,coor[0]+R};
      return result;
    }else{
      float[] result = {coor[0]-R,getTotalWall(wall_n2),coor[0]+R};
      return result;
    }*/
  }
  void drawWalls(){
    g.noStroke();
    float[] mins = {99999,99999};
    float[] maxes = {-99999,-99999};
    for(int i = 0; i < walls.length; i++){
      for(int d = 0; d < 2; d++){
        if(walls[i][d] < mins[d]){
          mins[d] = walls[i][d];
        }
        if(walls[i][d] > maxes[d]){
          maxes[d] = walls[i][d];
        }
      }
      float x1 = walls[i][0];
      float y1 = walls[i][1];
      float z1 = zs[0];
      int j = (i+1)%walls.length;
      float x2 = walls[j][0];
      float y2 = walls[j][1];
      float z2 = zs[1];
      
      g.fill(WALL_COLOR);
      g.beginShape();
      g.vertex(x1,y1,z1);
      g.vertex(x2,y2,z1);
      g.vertex(x2,y2,z2);
      g.vertex(x1,y1,z2);
      g.endShape(CLOSE);
    }
    float MARGIN = 20;
    g.fill(FLOOR_COLOR);
    g.beginShape();
    g.vertex(mins[0]-MARGIN,mins[1]-MARGIN,-EPS);
    g.vertex(maxes[0]+MARGIN,mins[1]-MARGIN,-EPS);
    g.vertex(maxes[0]+MARGIN,maxes[1]+MARGIN,-EPS);
    g.vertex(mins[0]-MARGIN,maxes[1]+MARGIN,-EPS);
    g.endShape(CLOSE);
    drawGraphKiosk();
  }
  void drawGraphKiosk(){
    float graph_R = 160;
    for(int d = 0; d < 6; d++){
      float gx = 400;
      float rot = 2+d;
      if(d >= 1){
        gx += graph_R;
        rot--;
      }
      if(d >= 4){
        gx -= graph_R;
        rot--;
      }
      drawGraph(d,gx,rot,graph_R);
    }
  }
  void drawGraph(int d, float gx, float rot, float graph_R){
    g.pushMatrix();
    g.translate(gx,400,0);
    g.rotateZ(rot*PI/2);
    g.rotateX(-PI/2);
    g.translate(0,0,graph_R/2);
    g.fill(120,80,40);
    g.rect(-graph_R/2,-graph_R,graph_R,graph_R);
    g.translate(0,0,EPS);
    g.image(statImages[(d+4)%6],-graph_R*0.47,-graph_R*0.97,graph_R*0.94,graph_R*0.94*0.75);
    g.popMatrix();
  }
}
