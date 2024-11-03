class Spider {
    static final float BODY_SPAN = 4;
    static final float MAX_LEG_SPAN = 37;
    static final float Ldist = MAX_LEG_SPAN * 0.25f;
    static final int MAX_SENSITIVITY_GENES = 6;
    static final int GENOME_LENGTH = LEG_COUNT * 13;
    static final float MAX_DIST_MOUSE = 100;

    float[] genome;
    float[] coor;
    float[][] leg_coor;
    int index, visIndex, generation, birth_tick;
    Spider parent;
    ArrayList<Integer> swattersSeen = new ArrayList<>();
    
    public Spider(int i, Room room) {
        this.index = i;
        this.generation = 0;
        this.parent = null;
        this.genome = new float[GENOME_LENGTH];
        this.coor = new float[2];
        this.leg_coor = new float[LEG_COUNT][2];
        
        // Initialize genome and coordinates
        initializeGenome();
        initializeCoordinates(room);
        placeLegs();
        increment();
    }

    private void initializeGenome() {
        for (int g = 0; g < GENOME_LENGTH; g++) {
            genome[g] = random(0.2f, 0.4f);
        }
    }

    private void initializeCoordinates(Room room) {
        for (int d = 0; d < 2; d++) {
            coor[d] = random(0, room.getMaxDim(d));
        }
        float ang = random(0, 1);
        for (int L = 0; L < LEG_COUNT; L++) {
            float angL = (L + ang) * PI / 2;
            float distance = genome[L * GENES_PER_LEG + 1];
            leg_coor[L][0] = coor[0] + cos(angL) * distance;
            leg_coor[L][1] = coor[1] + sin(angL) * distance;
        }
    }

    float clip(float val, Room room, int dim) {
        return constrain(val, 0, room.getMaxDim(dim));
    }

    float cursorOnSpider() {
        float[] realCoor = room.wallCoor_to_realCoor(coor);
        g.pushMatrix();
        aTranslate(realCoor);
        
        float x1 = g.screenX(0, 0, 0);
        float y1 = g.screenY(0, 0, 0);
        float x2 = g.screenX(0, MAX_LEG_SPAN, 0);
        float y2 = g.screenY(0, MAX_LEG_SPAN, 0);
        
        float distFromCenter = dist(x1, y1, width / 2, height / 2);
        float value = (distFromCenter < dist(x1, y1, x2, y2) && distFromCenter < MAX_DIST_MOUSE)
                ? g.screenZ(0, 0, 0) : -99999;

        g.popMatrix();
        return value;
    }

    color getColor() {
        int c = swattersSeen.size();
        if (c == 0) return color(0, 0, 0, 255);
        
        float fac = constrain((c - 1) / 5.0f, 0, 1);
        return (c < 6) 
            ? color(0, fac * 140, 255 - fac * 255, 255)
            : color(255 * fac, 140 - fac * 140, 0, 255);
    }

    color transitionColor(color a, color b, float prog) {
        return color(lerp(red(a), red(b), prog), lerp(green(a), green(b), prog), lerp(blue(a), blue(b), prog));
    }

    void drawSpider(Room room) {
        color c = (this == highlight_spider) ? color(0, 255, 0) : getColor();
        float[] realCoor = room.wallCoor_to_realCoor(coor);
        
        g.pushMatrix();
        aTranslate(realCoor);
        g.fill(c);
        drawBody(realCoor);
        drawLegs(room, c);
        drawParentIndicator(room, realCoor);
        g.popMatrix();
    }

    private void drawBody(float[] realCoor) {
        g.pushMatrix();
        g.rotateZ(realCoor[3]);
        g.beginShape();
        for (int i = 0; i < 12; i++) {
            float angle = i * TWO_PI / 12;
            g.vertex(cos(angle) * BODY_SPAN, 2, sin(angle) * BODY_SPAN);
        }
        g.endShape(CLOSE);
        g.popMatrix();
    }

    private void drawLegs(Room room, color c) {
        g.stroke(c);
        g.strokeWeight(3);
        for (int L = 0; L < LEG_COUNT; L++) {
            float[] legRealCoor = room.wallCoor_to_realCoor(leg_coor[L]);
            float[] Lcoor = aSubstract(legRealCoor, realCoor);
            float[] Mcoor = multi(Lcoor, 0.5f);
            Mcoor[0] -= sin(realCoor[3]) * Ldist;
            Mcoor[1] += cos(realCoor[3]) * Ldist;
            g.line(0, 0, 0, Mcoor[0], Mcoor[1], Mcoor[2]);
            g.line(Mcoor[0], Mcoor[1], Mcoor[2], Lcoor[0], Lcoor[1], Lcoor[2]);
        }
    }

    private void drawParentIndicator(Room room, float[] realCoor) {
        if (getAge() < 200 && parent != null && parent.getAge() >= getAge()) {
            float[] parentCoor = room.wallCoor_to_realCoor(parent.coor);
            if (realCoor[0] != parentCoor[0] || realCoor[1] != parentCoor[1]) {
                g.pushMatrix();
                aTranslate(realCoor);
                g.rotateZ(realCoor[3]);
                g.fill(255);
                drawParentBody();
                g.popMatrix();
                drawParentConnection(realCoor, parentCoor);
            }
        }
    }

    private void drawParentBody() {
        float WHITE_SPAN = BODY_SPAN * 4;
        g.beginShape();
        for (int i = 0; i < 12; i++) {
            float angle = i * TWO_PI / 12;
            g.vertex(cos(angle) * WHITE_SPAN, EPS * 2, sin(angle) * WHITE_SPAN);
        }
        g.endShape(CLOSE);
    }

    private void drawParentConnection(float[] realCoor, float[] parentCoor) {
        if (dist(realCoor[0], realCoor[1], realCoor[2], parentCoor[0], parentCoor[1], parentCoor[2]) < BODY_SPAN * 40) {
            g.stroke(255);
            g.strokeWeight(20);
            g.line(realCoor[0], realCoor[1], realCoor[2], parentCoor[0], parentCoor[1], parentCoor[2]);
        }
    }

    float[] multi(float[] a, float m) {
        float[] result = new float[a.length];
        for (int i = 0; i < a.length; i++) {
            result[i] = a[i] * m;
        }
        return result;
    }

    float[] aSubstract(float[] a, float[] b) {
        float[] result = new float[a.length];
        for (int i = 0; i < a.length; i++) {
            result[i] = a[i] - b[i];
        }
        return result;
    }

    float[] getWeightedCenter(int step, Room room, float darkest_sensed_shadow) {
        float[] sum_coor = {0, 0};
        float sum_weight = 0;
        
        for (int L = 0; L < LEG_COUNT; L++) {
            int genome_index = L * GENES_PER_LEG + 2 * step;
            if (darkest_sensed_shadow < genome[L * GENES_PER_LEG + 12]) {
                genome_index += 6;
            }
            float weight = genome[genome_index];
            sum_weight += weight;
            sum_coor[0] += leg_coor[L][0] * weight;
            sum_coor[1] += leg_coor[L][1] * weight;
        }

        return new float[]{sum_coor[0] / sum_weight, sum_coor[1] / sum_weight};
