class TestMain {
  static function main() {
    var r = new haxe.unit.TestRunner();
    r.add(new SignatureVersion4Test());
    r.run();
  }
}