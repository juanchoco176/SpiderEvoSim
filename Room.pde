class Room {
    float[][] walls;
    float[] wallLengths;
    float[] zs;
    float totalWallLength;
    ArrayList<Window> windows = new ArrayList<>();

    public Room(float[][] _walls, float[] _zs) {
        walls = _walls;
        zs = _zs;
        totalWallLength = 0;
        wallLengths = new float[walls.length];
        calculateWallLengthsAndWindows();
    }

    private void calculateWallLengthsAndWindows() {
        for (int i = 0; i < walls.length; i++) {
            int j = (i + 1) % walls.length;
            wallLengths[i] = dist(walls[i][0], walls[i][1], walls[j][0], walls[j][1]);
            totalWallLength += wallLengths[i];
            addWindowsForWall(i);
        }
    }

    private void addWindowsForWall(int i) {
        int toAdd = (int) min(1.0, (wallLengths[i] / WINDOW_W));
        for (int k = 0; k < toAdd; k++) {
            float[] coor = {
                totalWallLength + random(WINDOW_W / 2, wallLengths[i] - WINDOW_W / 2),
                random(WINDOW_H, 500 - WINDOW_H)
            };
            windows.add(new Window(coor));
        }
    }

    float getMaxDim(int d) {
        return d == 0 ? totalWallLength : (d == 1 ? zs[1] - zs[0] : 0);
    }

    float getTotalWall(int wallN) {
        float cum = 0;
        for (int w = 0; w < wallN; w++) {
            cum += wallLengths[w];
        }
        return cum;
    }

    float[] getWhatWallOn(float coorW) {
        int cum = 0;
        for (int w = 0; w < walls.length; w++) {
            if (coorW >= cum && coorW < cum + wallLengths[w]) {
                return new float[]{w, (coorW - cum) / wallLengths[w]};
            }
            cum += wallLengths[w];
        }
        return new float[]{walls.length - 1, 1};
    }

    float[] wallCoorToRealCoor(float[] coor) {
        float[] result = new float[4];
        result[2] = coor[1];

        float[] wallInfo = getWhatWallOn(coor[0]);
        int w1 = (int) wallInfo[0];
        int w2 = (w1 + 1) % walls.length;
        float prog = wallInfo[1];

        result[0] = lerp(walls[w1][0], walls[w2][0], prog);
        result[1] = lerp(walls[w1][1], walls[w2][1], prog);
        result[3] = atan2(walls[w2][1] - walls[w1][1], walls[w2][0] - walls[w1][0]);
        return result;
    }

    float[] swatterHelper(float[] coor, float R) {
        float[] coorW1 = getWhatWallOn(coor[0] - R);
        float[] coorW2 = getWhatWallOn(coor[0] + R);
        int wallN1 = (int) coorW1[0];
        int wallN2 = (int) coorW2[0];

        float[] result = new float[wallN2 - wallN1 + 2];
        result[0] = coor[0] - R;
        result[result.length - 1] = coor[0] + R;
        for (int i = 1; i < result.length - 1; i++) {
            result[i] = getTotalWall(wallN1 + i);
        }
        return result;
    }

    void drawWalls() {
        g.noStroke();
        float[] mins = {Float.MAX_VALUE, Float.MAX_VALUE};
        float[] maxes = {Float.MIN_VALUE, Float.MIN_VALUE};

        for (int i = 0; i < walls.length; i++) {
            for (int d = 0; d < 2; d++) {
                mins[d] = min(mins[d], walls[i][d]);
                maxes[d] = max(maxes[d], walls[i][d]);
            }
            drawWall(i);
        }

        drawFloor(mins, maxes);
        drawGraphKiosk();
    }

    private void drawWall(int i) {
        int j = (i + 1) % walls.length;
        g.fill(WALL_COLOR);
        g.beginShape();
        g.vertex(walls[i][0], walls[i][1], zs[0]);
        g.vertex(walls[j][0], walls[j][1], zs[0]);
        g.vertex(walls[j][0], walls[j][1], zs[1]);
        g.vertex(walls[i][0], walls[i][1], zs[1]);
        g.endShape(CLOSE);
    }

    private void drawFloor(float[] mins, float[] maxes) {
        float margin = 20;
        g.fill(FLOOR_COLOR);
        g.beginShape();
        g.vertex(mins[0] - margin, mins[1] - margin, -EPS);
        g.vertex(maxes[0] + margin, mins[1] - margin, -EPS);
        g.vertex(maxes[0] + margin, maxes[1] + margin, -EPS);
        g.vertex(mins[0] - margin, maxes[1] + margin, -EPS);
        g.endShape(CLOSE);
    }

    void drawGraphKiosk() {
        float graphR = 160;
        for (int d = 0; d < 6; d++) {
            float gx = 400;
            float rot = 2 + d;
            if (d >= 1) {
                gx += graphR;
                rot--;
            }
            if (d >= 4) {
                gx -= graphR;
                rot--;
            }
            drawGraph(d, gx, rot, graphR);
        }
    }

    void drawGraph(int d, float gx, float rot, float graphR) {
        g.pushMatrix();
        g.translate(gx, 400, 0);
        g.rotateZ(rot * PI / 2);
        g.rotateX(-PI / 2);
        g.translate(0, 0, graphR / 2);
        g.fill(120, 80, 40);
        g.rect(-graphR / 2, -graphR, graphR, graphR);
        g.translate(0, 0, EPS);
        g.image(statImages[(d + 4) % 6], -graphR * 0.47, -graphR * 0.97, graphR * 0.94, graphR * 0.94 * 0.75);
        g.popMatrix();
    }
}
