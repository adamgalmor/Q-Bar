class Drink
{
  int id;

  String name() {
    String name = "";
    switch(id) {
    case 0:
    case 1:
    case 2:
      name = "Beer";
      break;

    case 3:
    case 4:
      name = "Fine Ale";
      break;

    case 5:
      name = "DeerKiller";
      break;

    default:
      name = "Unknown";
      break;
    }
    return name;
  }
}

