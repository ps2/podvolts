
void setup() {
  // initialize serial communications at 14400 bps:
  Serial.begin(14400);
}

int a0,a1;

void loop() {
  a0 = analogRead(0);
  Serial.print(a0);
  Serial.print(",");
  a1 = analogRead(1);
  Serial.print(a1);
  Serial.println("");
  delay(3);
}

