// import libraries
import processing.serial.*;

// Serial port to connect to
String serialPortName = "/dev/cu.usbmodem143240";
int baud = 14400;

int graphWidth = 900;

// A reading of 993 = 4.788 volts
float voltageScale = 993 / 4.788;

/* SETTINGS END */

import java.util.NoSuchElementException;

public class CircularBuffer {
  private final Object lock = new Object();
  
  private final double[] elements;
  private int start = -1;
  private int end = -1;
  private final int capacity;

  void add(double num) {
    synchronized (lock) {
      end = (end + 1) % capacity;
      elements[end] = num;
      if (start == end || start == -1) {
        start = (start + 1) % capacity;
      }
    }
  }

  double get(int index) {
    double rval;
    synchronized (lock) {
      if (index >= capacity) {
        println("index >= capacity");
        throw new IndexOutOfBoundsException();
      }
      if (index >= count()) {
        print(index);
        print(" >= ");
        println(count());
        println("index >= count()");
        throw new IndexOutOfBoundsException();
      }
      rval =  elements[(start + index) % capacity];
    }

    return rval;
  }

  boolean isEmpty() {
    return start == -1 && end == -1;
  }

  CircularBuffer(int capacity) {
    this.capacity = capacity;
    elements = new double[capacity];
  }

  double min() {
    if (count() == 0) {
      throw new NoSuchElementException();
    }

    double out = get(0);
    for (int i = 1; i < count(); ++i) {
      out = Math.min(out, get(i));
    }

    return out;
  }

  double max() {
    if (count() == 0) {
      throw new NoSuchElementException();
    }

    double out = get(0);
    for (int i = 1; i < count(); ++i) {
      out = Math.max(out, get(i));
    }

    return out;
  }

  int count() {
    if (end == -1) {
      return 0;
    }

    return (end - start + capacity) % capacity + 1;
  }

  int capacity() {
    return capacity;
  }

}

Serial serialPort; // Serial port object
String displayString;
PFont myFont;     // The display font
CircularBuffer buffers[];
float yScale = 0.6;
boolean refresh = false;
PrintWriter output;
String outputFileName;


// helper for saving the executing path
String topSketchPath = "";

void setup() {
  surface.setTitle("Realtime plotter");
  //printArray(PFont.list());
  
  myFont = createFont("LucidaSans", 16);
  textFont(myFont, 16);
  
  size(900, 800);
  
  //printArray(Serial.list());  
  new Serial(this, serialPortName, baud).bufferUntil(10);
}

void drawBuffer(CircularBuffer buffer, double offset, double scale) {
  int count = buffer.count();
  int i;
  for (i=0; i<count; i++) {
    double yRaw = buffer.get(i);
    double yPos = (yRaw - offset) * scale;
    point((float)i, 800-(float)yPos);
  }
}


void draw() {

  double chartRange, chartScale, chartOffset;
  float minY = 0, maxY = 0;
  
  if (buffers == null || buffers.length == 0) {
    return;
  }

  if (!refresh) {
    return;
  }
  background(0);
  
  int colors[] = new int[]{#CCFF00, #00FFAA, #CC00AA};
  
  if (colors.length < buffers.length) {
    print("Not enough colors!");
    return;
  }
  
  // Figure y scale of graph
  for (int i=0;i < buffers.length; i++) {
     if (i==0) {
       minY = (float)buffers[i].min();
       maxY = (float)buffers[i].max();
     } else {
       minY = min(minY, (float)buffers[i].min());
       maxY = max(maxY, (float)buffers[i].max());
     }
  }
  
  chartRange = (maxY - minY) * 2;
  chartScale = 800 / chartRange;
  chartOffset = minY - ((chartRange/2) - ((maxY - minY) / 2.0));
  
  for (int i=0;i < buffers.length; i++) {
    stroke(colors[i]);
    drawBuffer(buffers[i], chartOffset, chartScale);
  }
    
  text(displayString, 10,50);
  refresh = false;
} 

void serialEvent(Serial p) { 
  String inString = p.readString();
  String[] values = split(inString, ',');
  int i;
  
  if (buffers == null || values.length != buffers.length) {
    buffers = new CircularBuffer[values.length];
    for (i=0; i<values.length; i++) {
      buffers[i] = new CircularBuffer(graphWidth);
    }
  }
  
  displayString = "Values: ";
  
  for (i=0; i<values.length; i++) {
    float val = float(values[i]) / voltageScale;
    buffers[i].add(val);
    displayString += nf(val,0,2);
    if (i<values.length-1) {
      displayString += ",";
    }
    refresh = true;
  }

  String newFile = nf(year(),4) + nf(month(),2) + nf(day(),2) + nf(hour(),2) + ".csv";
  if (outputFileName == null || !newFile.equals(outputFileName)) {
    outputFileName = newFile;
    if (output != null) {
      output.flush();
      output.close();
    }
    output = createWriter(outputFileName);
  }
    
  long timestamp = System.currentTimeMillis() % (1000 * 60 * 60);
  String timeStr = nf(timestamp / (1000*60)) + ":" + nf((timestamp % (1000 * 60)) / 1000.0); 
  output.print(timeStr+",");
  output.print(inString);
} 
